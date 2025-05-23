BIN=bin/cleanup-by-date
LOG=test.log
TEST_DIR=tests

install:
	sudo install -m 755 $(BIN) /usr/local/bin/cleanup-by-date

lint:
	shellcheck $(BIN)

dryrun:
	$(BIN) testdata '' 7d --dry-run --log $(LOG)

test:
	bats $(TEST_DIR)
