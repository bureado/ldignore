# Makefile for ldignore - LD_PRELOAD library for enforcing ignore files

CC = gcc
CFLAGS = -Wall -Wextra -O2 -fPIC -D_GNU_SOURCE
LDFLAGS = -shared -ldl -lpthread

# Library name
LIB = ldignore.so

# Source files
SRCS = ldignore.c ignore_parser.c
OBJS = $(SRCS:.c=.o)
HEADERS = ignore_parser.h

# Test programs
TEST_PROGS = test_ldignore

.PHONY: all clean test install

all: $(LIB)

# Build the shared library
$(LIB): $(OBJS)
	$(CC) $(LDFLAGS) -o $@ $^

# Compile object files
%.o: %.c $(HEADERS)
	$(CC) $(CFLAGS) -c $< -o $@

# Build test program
test_ldignore: test_ldignore.c
	$(CC) -Wall -Wextra -O2 -o $@ $^

# Run tests
test: $(LIB) test_ldignore
	@echo "=== Running ldignore tests ==="
	@./run_tests.sh

# Install the library
install: $(LIB)
	install -D -m 0755 $(LIB) /usr/local/lib/$(LIB)
	ldconfig

# Clean build artifacts
clean:
	rm -f $(OBJS) $(LIB) $(TEST_PROGS)
	rm -f test_output.txt

# Help target
help:
	@echo "Available targets:"
	@echo "  all       - Build the ldignore.so library (default)"
	@echo "  test      - Build and run tests"
	@echo "  install   - Install library to /usr/local/lib"
	@echo "  clean     - Remove build artifacts"
	@echo "  help      - Show this help message"
