import http from 'k6/http';
import exec from 'k6/execution';
import { SharedArray } from 'k6/data';
import { check } from 'k6';
import { Rate, Trend } from 'k6/metrics';

const baseUrl = __ENV.BASE_URL || 'https://fakestoreapi.com';
const latencyLimitMs = Number(__ENV.LATENCY_LIMIT_MS || 1500);
const testType = __ENV.TEST_TYPE || 'load';
const tps = Number(__ENV.TPS || 21);
const duration = __ENV.DURATION || '1m';
const preAllocatedVUs = Number(__ENV.PRE_ALLOCATED_VUS || 40);
const maxVUs = Number(__ENV.MAX_VUS || 120);
const smokeIterations = Number(__ENV.ITERATIONS || 5);
const failedTransactions = new Rate('failed_transactions');
const slowTransactions = new Rate('slow_transactions');
const successfulLogins = new Rate('successful_logins');
const loginDuration = new Trend('login_duration', true);
const credentials = new SharedArray('credentials', () => {
  const rows = open('../data/credentials.csv').trim().split(/\r?\n/);
  const [header, ...lines] = rows;
  const [firstColumn, secondColumn] = header.split(',').map((value) => value.trim());
  if (firstColumn !== 'user' || secondColumn !== 'passwd') {
    throw new Error('El archivo CSV debe tener los encabezados user,passwd');
  }
  return lines.filter(Boolean).map((line) => {
    const [user, passwd] = line.split(',');
    return {
      user: user.trim(),
      passwd: passwd.trim(),
    };
  });
});

export const options = testType === 'smoke'
  ? {
      scenarios: {
        smoke_login: {
          executor: 'shared-iterations',
          vus: 1,
          iterations: smokeIterations,
          maxDuration: '30s',
        },
      },
      thresholds: {
        failed_transactions: ['rate<0.03'],
        slow_transactions: ['rate==0'],
        successful_logins: ['rate>0.97'],
      },
    }
  : {
      scenarios: {
        login_load: {
          executor: 'constant-arrival-rate',
          rate: tps,
          timeUnit: '1s',
          duration,
          preAllocatedVUs,
          maxVUs,
        },
      },
      thresholds: {
        failed_transactions: ['rate<0.03'],
        slow_transactions: ['rate==0'],
        successful_logins: ['rate>0.97'],
        http_req_duration: [`p(95)<${latencyLimitMs}`],
      },
    };

function pickCredential() {
  return credentials[exec.scenario.iterationInTest % credentials.length];
}

function parseBody(response) {
  try {
    return response.json();
  } catch (error) {
    return null;
  }
}

export default function () {
  const credential = pickCredential();
  const response = http.post(
    `${baseUrl}/auth/login`,
    JSON.stringify({
      username: credential.user,
      password: credential.passwd,
    }),
    {
      headers: {
        'Content-Type': 'application/json',
        Accept: 'application/json',
      },
      timeout: '60s',
    },
  );
  const body = parseBody(response);
  const hasToken = Boolean(body && typeof body.token === 'string' && body.token.length > 0);
  const statusSucceeded = response.status === 200 || response.status === 201;
  const loginSucceeded = statusSucceeded && hasToken;
  const durationSucceeded = response.timings.duration <= latencyLimitMs;

  loginDuration.add(response.timings.duration);
  successfulLogins.add(loginSucceeded);
  failedTransactions.add(!loginSucceeded);
  slowTransactions.add(!durationSucceeded);

  check(response, {
    'status exitoso': () => statusSucceeded,
    'token presente': () => hasToken,
    'latencia dentro del umbral': () => durationSucceeded,
  });
}
