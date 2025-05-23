#!/usr/bin/env bats

setup() {
  TMPDIR=$(mktemp -d)
  touch "$TMPDIR/keep-2025-01-01_1200.sql.gz"
  touch "$TMPDIR/delete-2020-01-01_1200.sql.gz"
}

teardown() {
  rm -rf "$TMPDIR"
}

@test "dry-run does not delete files" {
  run ./bin/cleanup-by-date "$TMPDIR" '' 1d --dry-run
  [ "$status" -eq 0 ]
  [[ -f "$TMPDIR/delete-2020-01-01_1200.sql.gz" ]]
}

@test "deletes old file by name-date" {
  run ./bin/cleanup-by-date "$TMPDIR" '' 1d
  [ "$status" -eq 0 ]
  [[ ! -f "$TMPDIR/delete-2020-01-01_1200.sql.gz" ]]
  [[ -f "$TMPDIR/keep-2025-01-01_1200.sql.gz" ]]
}
