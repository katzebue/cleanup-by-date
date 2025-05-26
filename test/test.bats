setup() {
  load 'test_helper/common-setup'
  _common_setup

  touch -d "2020-01-01 12:00:00" "$BATS_TEST_TMPDIR/delete-old-2020-01-01_1200.sql.gz"
  touch -d "2025-01-01 12:00:00" "$BATS_TEST_TMPDIR/keep-new-2025-01-01_1200.sql.gz"
  touch -d "2023-01-01 12:00:00" "$BATS_TEST_TMPDIR/dump-test-2023-01-01_1200.sql.gz"
  touch "$BATS_TEST_TMPDIR/ignore-this-file.txt"
}

@test "extreme period values are parsed correctly" {
  local -a periods=(
    "0y:2024-01-01 00:00:00"
    "0m:2024-01-01 00:00:00"
    "0w:2024-01-01 00:00:00"
    "0d:2024-01-01 00:00:00"
    "0h:2024-01-01 00:00:00"

    "1y:2023-01-01 00:00:00"
    "1m:2023-12-01 00:00:00"
    "1w:2023-12-25 00:00:00"
    "1d:2023-12-31 00:00:00"
    "24h:2023-12-31 00:00:00"
    "1h:2023-12-31 23:00:00"

    "168h:2023-12-25 00:00:00"
    "45d:2023-11-17 00:00:00"
    "27w:2023-06-26 00:00:00"
  )

  for item in "${periods[@]}"; do
    IFS=":" read -r period expected <<<"$item"

    tmpdir=$(mktemp -d)
    touch "$tmpdir/fake-2024-01-01"

    run cleanup-by-date "$tmpdir" "$period" \
      --now "2024-01-01 00:00:00" \
      --dry-run

    assert_success
    assert_output --partial "CUTOFF=$expected"

    rm -rf "$tmpdir"
  done
}

@test "shows help and exits 0 with missing arguments" {
  run cleanup-by-date
  assert_success
  assert_output --partial "Usage:"
}

@test "fails with invalid directory" {
  run cleanup-by-date /invalid/path 1d
  assert_failure 2
  assert_output --partial "does not exist"
}

@test "empty directory fails if no files match regex" {
  mkdir -p "$BATS_TEST_TMPDIR/empty-dir"
  run cleanup-by-date "$BATS_TEST_TMPDIR/empty-dir" 1d
  assert_failure 4
  assert_output --partial "Regex does not match any filenames"
}

@test "fails with invalid regex" {
  run cleanup-by-date "$BATS_TEST_TMPDIR" 1d --regex "([0-9]{4"
  assert_failure 4
  assert_output --partial "Regex does not match any filenames"
}

@test "fails with invalid period format" {
  run cleanup-by-date "$BATS_TEST_TMPDIR" 1x --regex ".*"
  assert_failure 3
  assert_output --partial "Invalid period format"
}

@test "dry-run shows files but doesn't delete (with --now)" {
  run cleanup-by-date "$BATS_TEST_TMPDIR" 5y --dry-run --now "2025-01-01 12:00:01"
  assert_success
  assert_output --partial "Would delete:"
  assert_output --partial "delete-old-2020-01-01_1200.sql.gz"
  assert_file_exist "$BATS_TEST_TMPDIR/delete-old-2020-01-01_1200.sql.gz"
}

@test "deletes old files correctly (with --now)" {
  run cleanup-by-date "$BATS_TEST_TMPDIR" 365d --now "2025-01-01 00:00:00"
  assert_success
  assert_file_not_exist "$BATS_TEST_TMPDIR/delete-old-2020-01-01_1200.sql.gz"
  assert_file_exist "$BATS_TEST_TMPDIR/keep-new-2025-01-01_1200.sql.gz"
}

@test "handles custom regex patterns (with --now)" {
  run cleanup-by-date "$BATS_TEST_TMPDIR" 365d --regex 'dump-.*([0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{4})\.sql\.gz' --now "2025-01-01 00:00:00"
  assert_success
  assert_file_not_exist "$BATS_TEST_TMPDIR/dump-test-2023-01-01_1200.sql.gz"
  assert_file_exist "$BATS_TEST_TMPDIR/delete-old-2020-01-01_1200.sql.gz"
}

@test "does not touch non-matching files (with --now)" {
  run cleanup-by-date "$BATS_TEST_TMPDIR" 5y --now "2025-01-01 00:00:00"
  assert_success
  assert_file_exist "$BATS_TEST_TMPDIR/ignore-this-file.txt"
}

@test "fails with invalid --now format" {
  run cleanup-by-date "$BATS_TEST_TMPDIR" 1d --now "not-a-date"
  assert_failure 3
  assert_output --partial "Invalid date for --now"
}

@test "dry-run with custom regex does not delete" {
  run cleanup-by-date "$BATS_TEST_TMPDIR" 1y --dry-run --regex 'dump-.*([0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{4})\.sql\.gz' --now "2025-01-01 00:00:00"
  assert_success
  assert_output --partial "Would delete:"
  assert_output --partial "dump-test-2023-01-01_1200.sql.gz"
  assert_file_exist "$BATS_TEST_TMPDIR/dump-test-2023-01-01_1200.sql.gz"
}

@test "default regex matches and deletes old files" {
  run cleanup-by-date "$BATS_TEST_TMPDIR" 5y --now "2025-01-01 00:00:00"
  assert_success
  assert_file_not_exist "$BATS_TEST_TMPDIR/delete-old-2020-01-01_1000.sql.gz"
}

@test "writes to log file" {
  logfile="$BATS_TEST_TMPDIR/output.log"
  run cleanup-by-date "$BATS_TEST_TMPDIR" 1y --log "$logfile" --now "2025-01-01 00:00:00"
  assert_success
  assert_file_exist "$logfile"
  run grep "Deleted:" "$logfile"
  assert_success
}

@test "ignores files without matching date even if regex is correct" {
  touch "$BATS_TEST_TMPDIR/no-date-file.sql.gz"
  run cleanup-by-date "$BATS_TEST_TMPDIR" 5y --now "2025-01-01 00:00:00"
  assert_success
  assert_file_exist "$BATS_TEST_TMPDIR/no-date-file.sql.gz"
}

@test "skips files with unparsable date" {
  touch "$BATS_TEST_TMPDIR/badfile-9999-99-99.sql.gz"
  run cleanup-by-date "$BATS_TEST_TMPDIR" 1d --now "2025-01-01 00:00:00"
  assert_success
}
