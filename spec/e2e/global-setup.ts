import { execFileSync, spawn } from 'node:child_process';
import http from 'node:http';

const serverUrl = 'http://127.0.0.1:31337/up';

function canConnect(url: string) {
  return new Promise<boolean>((resolve) => {
    const request = http.get(url, (response) => {
      response.resume();
      resolve(response.statusCode !== undefined && response.statusCode >= 200 && response.statusCode < 500);
    });

    request.on('error', () => resolve(false));
    request.setTimeout(1_000, () => {
      request.destroy();
      resolve(false);
    });
  });
}

async function waitForServer(timeoutMs: number, hasExited: () => boolean) {
  const startedAt = Date.now();

  while (Date.now() - startedAt < timeoutMs) {
    if (await canConnect(serverUrl)) return;
    if (hasExited()) throw new Error('Playwright Rails server exited before it became ready');
    await new Promise((resolve) => setTimeout(resolve, 1_000));
  }

  throw new Error(`Timed out waiting for ${serverUrl}`);
}

function stopProcessTree(pid: number) {
  if (process.platform === 'win32') {
    execFileSync('taskkill', ['/pid', String(pid), '/t', '/f'], { stdio: 'ignore' });
    return;
  }

  process.kill(pid, 'SIGTERM');
}

export default async function globalSetup() {
  let exited = false;
  const server = spawn('ruby', ['script/playwright_server.rb'], {
    cwd: process.cwd(),
    env: { ...process.env, RAILS_ENV: 'test' },
    stdio: 'inherit',
    windowsHide: true
  });

  server.once('exit', () => {
    exited = true;
  });

  await waitForServer(240_000, () => exited);

  return async () => {
    if (!server.pid || exited) return;

    try {
      stopProcessTree(server.pid);
    } catch {
      // The server may already have exited between the check and the kill.
    }
  };
}
