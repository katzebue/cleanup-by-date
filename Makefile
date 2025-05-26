SRC=src/cleanup-by-date
BIN_NAME=cleanup-by-date
LOG=test.log
TEST_DIR=test
TEST_FILE=$(TEST_DIR)/test.bats

.PHONY: install lint dryrun test

install:
	install -m 755 $(SRC) /usr/local/bin/$(BIN_NAME)

lint:
	shellcheck $(SRC)

test:
	./$(TEST_DIR)/bats/bin/bats $(TEST_FILE)
