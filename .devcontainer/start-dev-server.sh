#!/usr/bin/env sh

set -eu

cd /workspaces/datawires

until pg_isready -h "${DATABASE_HOST:-db}" -U "${DATABASE_USERNAME:-datawires}" >/dev/null 2>&1; do
  sleep 1
done

mkdir -p log tmp/pids
rm -f tmp/pids/server.pid tmp/pids/server.foreman.development.pid

bundle check || bundle install
bundle exec bin/rails db:prepare

exec bundle exec bin/rails server -u puma -p 3000 -b 0.0.0.0
