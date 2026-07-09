# ==============================================================================
# Host-side unit tests (Unity framework) for the pure firmware logic.
#
#   make        -> build and run the tests
#   make clean  -> remove artefacts
#
# Author: Urvish Kosta
# License: MIT (see LICENSE at repository root)
# ==============================================================================
CC     := gcc
CFLAGS := -Wall -Wextra -Werror -I../include -Iunity

.PHONY: all clean

all: test_demo_tasks
	./test_demo_tasks

test_demo_tasks: test_demo_tasks.c ../src/demo_tasks.c unity/unity.c
	$(CC) $(CFLAGS) $^ -o $@

clean:
	rm -f test_demo_tasks
