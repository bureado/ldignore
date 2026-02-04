#!/bin/bash

# Create a test directory and files
TEST_DIR=$(mktemp -d)
cd "$TEST_DIR"

# Create a .claudeignore file
echo "secret.txt" > .claudeignore
echo "*.log" >> .claudeignore
echo "Public content" > public.txt
echo "Secret content" > secret.txt
echo "Log data" > test.log

echo "=== Final Verification Test ==="
echo "Test directory: $TEST_DIR"
echo ""

# Test 1: Debug mode with monitoring (non-enforce)
echo "Test 1: Debug mode - monitoring (LDIGNORE_ENFORCE=0)"
export LD_PRELOAD=/home/runner/work/ldignore/ldignore/ldignore.so
export LDIGNORE_DEBUG=1
export LDIGNORE_ENFORCE=0

/home/runner/work/ldignore/ldignore/test_ldignore secret.txt > /dev/null 2>&1
/home/runner/work/ldignore/ldignore/test_ldignore public.txt > /dev/null 2>&1
/home/runner/work/ldignore/ldignore/test_ldignore test.log > /dev/null 2>&1

sleep 1
echo "Checking syslog for messages..."
journalctl -t ldignore -n 10 --no-pager 2>/dev/null | grep -E "(Initialized|Blocked)" | tail -5

echo ""
echo "Test 2: Debug mode - enforcement (LDIGNORE_ENFORCE=1)"
export LDIGNORE_ENFORCE=1

echo -n "  Trying to open secret.txt (should be blocked): "
if /home/runner/work/ldignore/ldignore/test_ldignore secret.txt > /dev/null 2>&1; then
    echo "FAIL - File was not blocked"
else
    echo "PASS - File was blocked"
fi

echo -n "  Trying to open public.txt (should succeed): "
if /home/runner/work/ldignore/ldignore/test_ldignore public.txt > /dev/null 2>&1; then
    echo "PASS - File was accessible"
else
    echo "FAIL - File was blocked incorrectly"
fi

echo -n "  Trying to open test.log (should be blocked): "
if /home/runner/work/ldignore/ldignore/test_ldignore test.log > /dev/null 2>&1; then
    echo "FAIL - File was not blocked"
else
    echo "PASS - File was blocked"
fi

sleep 1
echo ""
echo "Recent syslog messages:"
journalctl -t ldignore -n 15 --no-pager 2>/dev/null | grep -E "(Initialized|Blocked)" | tail -8

# Cleanup
cd /
rm -rf "$TEST_DIR"

echo ""
echo "=== All tests completed ==="
