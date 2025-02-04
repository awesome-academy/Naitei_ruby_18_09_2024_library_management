#!/bin/sh

set -e
rm -f tmp/pids/server.pid

if [ "$1" = "sidekiq" ]; then
  exec bundle exec sidekiq
else
  exec bundle exec rails s -b 0.0.0.0
fi
