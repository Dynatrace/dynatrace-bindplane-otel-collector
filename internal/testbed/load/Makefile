.PHONY: run-tests
run-tests:
	./runtests.sh

# Lists the load tests without running them.
.PHONY: list-tests
list-tests:
	cd tests && RUN_TESTBED=1 go test -v . --test.list '.*' | grep '^Test'
