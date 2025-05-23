#!/bin/bash
set -e
./bin/cleanup-by-date testdata '' 7d --dry-run --log test.log
