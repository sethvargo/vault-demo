#!/usr/bin/env bash
set -e

docker run -d -p 5432:5432 -e POSTGRES_DB=myapp postgres
echo "==> Done!"
