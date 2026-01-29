#!/bin/bash

# Test that syslog is not opened when debug mode is disabled
TEST_DIR=$(mktemp -d)
cd "$TEST_DIR"

echo "secret.txt" > .claudeignore
echo "Secret content" > secret.txt
echo "Public content" > public.txt

# Get current syslog line count
BEFORE_COUNT=$(journalctl -t ldignore --no-pager 2>/dev/null | wc -l)

echo "=== Testing without debug mode (LDIGNORE_DEBUG not set) ==="
export LD_PRELOAD=/home/runner/work/ldignore/ldignore/ldignore.so
export LDIGNORE_ENFORCE=1
unset LDIGNORE_DEBUG

# Try to access files - should work but not log to syslog
/home/runner/work/ldignore/ldignore/test_ldignore public.txt > /dev/null 2>&1
/home/runner/work/ldignore/ldignore/test_ldignore secret.txt > /dev/null 2>&1 || true

sleep 1

# Get new syslog line count
AFTER_COUNT=$(journalctl -t ldignore --no-pager 2>/dev/null | wc -l)

echo "Syslog lines before test: $BEFORE_COUNT"
echo "Syslog lines after test:  $AFTER_COUNT"
echo "New messages: $((AFTER_COUNT - BEFORE_COUNT))"

if [ $((AFTER_COUNT - BEFORE_COUNT)) -eq 0 ]; then
    echo "✓ PASS: No syslog messages when debug is disabled"
else
    echo "✗ FAIL: Unexpected syslog messages found when debug is disabled"
fi

# Cleanup
cd /
rm -rf "$TEST_DIR"
