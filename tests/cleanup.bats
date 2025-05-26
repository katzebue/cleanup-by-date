#!/usr/bin/env bats

setup() {
  export TMP_DIR
  TMP_DIR=$(mktemp -d)
  export SCRIPT
  SCRIPT="$(pwd)/../bin/cleanup-by-date"

  # Mock date command to control timestamps for testing
  export PATH_BACKUP=$PATH
  export FAKE_BIN="$TMP_DIR/fake-bin"
  mkdir -p "$FAKE_BIN"
  cat >"$FAKE_BIN/date" <<EOF
#!/usr/bin/env bash
if [[ "\$1" == "+%s" ]]; then
  echo "1735689600"  # 2025-01-01 00:00:00 UTC
elif [[ "\$*" == "-d "* ]]; then
  shift
  echo "2023-01-01 12:00:00"
else
  command /bin/date "\$@"
fi
EOF
  chmod +x "$FAKE_BIN/date"
  export PATH="$FAKE_BIN:$PATH"

  # Create test files with specific modified timestamps using proper date format
  touch -d "2020-01-01 12:00:00" "$TMP_DIR/delete-old-2020-01-01_1200.sql.gz"
  touch -d "2025-01-01 12:00:00" "$TMP_DIR/keep-new-2025-01-01_1200.sql.gz"
  touch -d "2023-01-01 12:00:00" "$TMP_DIR/dump-test-2023-01-01_1200.sql.gz"
  touch "$TMP_DIR/ignore-this-file.txt"
}

teardown() {
  rm -rf "$TMP_DIR"
  export PATH=$PATH_BACKUP
}

@test "shows help and exits 0 with missing arguments" {
  run "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage:"* ]]
}

@test "fails with invalid directory" {
  run "$SCRIPT" /invalid/path 1d
  [ "$status" -eq 2 ]
  [[ "$output" == *"does not exist"* ]]
}

@test "handles empty directory without error" {
  mkdir -p "$TMP_DIR/empty-dir"
  run "$SCRIPT" "$TMP_DIR/empty-dir" 1d
  [ "$status" -eq 0 ]
  [[ "$output" == *"Files deleted: 0"* ]]
}

@test "fails with invalid regex" {
  run "$SCRIPT" "$TMP_DIR" 1d --regex "([0-9]{4"
  [ "$status" -eq 4 ]
  [[ "$output" == *"Regex does not match expected filename format"* ]]
}

@test "fails with invalid period format" {
  run "$SCRIPT" "$TMP_DIR" 1x --regex ".*"
  [ "$status" -eq 3 ]
  [[ "$output" == *"Invalid period format"* ]]
}

@test "dry-run shows files but doesn't delete" {
  run "$SCRIPT" "$TMP_DIR" 5y --dry-run
  echo $status
  echo "$output"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Would delete:"* ]]
  [ -f "$TMP_DIR/delete-old-2020-01-01_1200.sql.gz" ]
}

@test "deletes old files correctly" {
  run "$SCRIPT" "$TMP_DIR" 365d
  echo status: $status
  echo output: $output
  [ "$status" -eq 0 ]
  [ ! -f "$TMP_DIR/delete-old-2020-01-01_1200.sql.gz" ]
  [ -f "$TMP_DIR/keep-new-2025-01-01_1200.sql.gz" ]
}

@test "handles custom regex patterns" {
  run "$SCRIPT" "$TMP_DIR" 365d --regex 'dump-.*[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{4}\.sql\.gz'
  echo status: $status
  echo output: $output
  [ "$status" -eq 0 ]
  [ ! -f "$TMP_DIR/dump-test-2023-01-01_1200.sql.gz" ]
  [ -f "$TMP_DIR/delete-old-2020-01-01_1200.sql.gz" ]
}

@test "does not touch non-matching files" {
  run "$SCRIPT" "$TMP_DIR" 5y
  [ "$status" -eq 0 ]
  [ -f "$TMP_DIR/ignore-this-file.txt" ]
}
