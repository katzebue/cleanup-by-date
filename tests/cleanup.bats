#!/usr/bin/env bats

setup() {
  TMP_DIR=$(mktemp -d)
  export TMP_DIR
  SCRIPT="$(pwd)/../bin/cleanup-by-date"
  export SCRIPT

  # Create test files with specific modified timestamps using proper date format
  touch -d "2020-01-01 12:00:00" "$TMP_DIR/delete-old-2020-01-01_1200.sql.gz"
  touch -d "2025-01-01 12:00:00" "$TMP_DIR/keep-new-2025-01-01_1200.sql.gz"
  touch -d "2023-01-01 12:00:00" "$TMP_DIR/dump-test-2023-01-01_1200.sql.gz"
  touch "$TMP_DIR/ignore-this-file.txt"
}

teardown() {
  rm -rf "$TMP_DIR"
}

@test "shows help and exits 0 with missing arguments" {
  run "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage:"* ]]
}

@test "fails with invalid directory" {
  run "$SCRIPT" /invalid/path 1d
  echo status: $status
  echo output: $output
  [ "$status" -eq 2 ]
  [[ "$output" == *"does not exist"* ]]
}

@test "empty directory fails if no files match regex" {
  local dir="$TMP_DIR/empty-dir"
  mkdir -p "$dir"

  run "$SCRIPT" "$dir" 1d

  [ "$status" -eq 4 ]
  [[ "$output" == *"Regex does not match any filenames in $dir"* ]]
}

@test "fails with invalid regex" {
  run "$SCRIPT" "$TMP_DIR" 1d --regex "([0-9]{4"
  [ "$status" -eq 4 ]
  [[ "$output" == *"Regex does not match any filenames in $TMP_DIR"* ]]
}

@test "fails with invalid period format" {
  run "$SCRIPT" "$TMP_DIR" 1x --regex ".*"
  [ "$status" -eq 3 ]
  [[ "$output" == *"Invalid period format"* ]]
}

@test "dry-run shows files but doesn't delete (with --now)" {
  run "$SCRIPT" "$TMP_DIR" 5y --dry-run --now "2025-01-01 00:00:00"
  echo $status
  echo "$output"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Would delete:"* ]]
  [ -f "$TMP_DIR/delete-old-2020-01-01_1200.sql.gz" ]
}

@test "deletes old files correctly (with --now)" {
  run "$SCRIPT" "$TMP_DIR" 365d --now "2025-01-01 00:00:00"
  echo $status
  echo "$output"
  [ "$status" -eq 0 ]
  [ ! -f "$TMP_DIR/delete-old-2020-01-01_1200.sql.gz" ]
  [ -f "$TMP_DIR/keep-new-2025-01-01_1200.sql.gz" ]
}

@test "handles custom regex patterns (with --now)" {
  run "$SCRIPT" "$TMP_DIR" 365d --regex 'dump-.*([0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{4})\.sql\.gz' --now "2025-01-01 00:00:00"
  echo $status
  echo "$output"
  [ "$status" -eq 0 ]
  [ ! -f "$TMP_DIR/dump-test-2023-01-01_1200.sql.gz" ]
  [ -f "$TMP_DIR/delete-old-2020-01-01_1200.sql.gz" ]
}

@test "does not touch non-matching files (with --now)" {
  run "$SCRIPT" "$TMP_DIR" 5y --now "2025-01-01 00:00:00"
  echo $status
  echo "$output"
  [ "$status" -eq 0 ]
  [ -f "$TMP_DIR/ignore-this-file.txt" ]
}

@test "fails with invalid --now format" {
  run "$SCRIPT" "$TMP_DIR" 1d --now "not-a-date"
  echo $status
  echo "$output"
  [ "$status" -eq 3 ]
  [[ "$output" == *"Invalid date for --now"* ]]
}

@test "dry-run with custom regex does not delete" {
  run "$SCRIPT" "$TMP_DIR" 10y --dry-run --regex 'dump-.*([0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{4})\.sql\.gz' --now "2025-01-01 00:00:00"
  echo $status
  echo "$output"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Would delete:"* ]]
  [ -f "$TMP_DIR/dump-test-2023-01-01_1200.sql.gz" ]
}

@test "default regex matches and deletes old files" {
  run "$SCRIPT" "$TMP_DIR" 5y --now "2025-01-01 00:00:00"
  echo $status
  echo "$output"
  [ "$status" -eq 0 ]
  [ ! -f "$TMP_DIR/delete-old-2020-01-01_1200.sql.gz" ]
}

@test "writes to log file" {
  logfile="$TMP_DIR/output.log"
  run "$SCRIPT" "$TMP_DIR" 5y --log "$logfile" --now "2025-01-01 00:00:00"
  [ "$status" -eq 0 ]
  grep -q "Deleted:" "$logfile"
}

@test "ignores files without matching date even if regex is correct" {
  touch "$TMP_DIR/no-date-file.sql.gz"
  run "$SCRIPT" "$TMP_DIR" 5y --now "2025-01-01 00:00:00"
  [ "$status" -eq 0 ]
  [ -f "$TMP_DIR/no-date-file.sql.gz" ]
}

@test "skips files with unparsable date" {
  touch "$TMP_DIR/badfile-9999-99-99.sql.gz"
  run "$SCRIPT" "$TMP_DIR" 1d --now "2025-01-01 00:00:00"
  echo $status
  echo "$output"
  [ "$status" -eq 0 ]
}
