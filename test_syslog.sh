#!/bin/bash

# Create a test directory and files
TEST_DIR=$(mktemp -d)
cd "$TEST_DIR"

# Create a .claudeignore file
echo "ignored.txt" > .claudeignore
echo "This is the test file" > test.txt
echo "This is the ignored file" > ignored.txt

# Clear any existing ldignore entries from journalctl (if available)
# We'll use journalctl to read syslog messages if available

# Run the test program with LD_PRELOAD
echo "=== Testing syslog output with LDIGNORE_DEBUG=1 ==="
echo

# Try to read the ignored file with debug enabled
export LD_PRELOAD=/home/runner/work/ldignore/ldignore/ldignore.so
export LDIGNORE_DEBUG=1
export LDIGNORE_ENFORCE=0

echo "Attempting to open ignored.txt..."
/home/runner/work/ldignore/ldignore/test_ldignore ignored.txt 2>&1 || true

echo
echo "Attempting to open test.txt (not ignored)..."
/home/runner/work/ldignore/ldignore/test_ldignore test.txt 2>&1 || true

echo
echo "=== Checking syslog for ldignore messages ==="
echo

# Try to read from system journal or syslog
if command -v journalctl &> /dev/null; then
    echo "Using journalctl to check for ldignore messages (last 20 lines):"
    sudo journalctl -t ldignore -n 20 --no-pager 2>/dev/null || echo "Note: journalctl requires sudo or appropriate permissions"
elif [ -f /var/log/syslog ]; then
    echo "Checking /var/log/syslog for ldignore messages:"
    grep ldignore /var/log/syslog | tail -n 10
elif [ -f /var/log/messages ]; then
    echo "Checking /var/log/messages for ldignore messages:"
    grep ldignore /var/log/messages | tail -n 10
else
    echo "Cannot access syslog. Trying to read from current session..."
    # On some systems, messages might be in user journal
    journalctl --user -t ldignore -n 20 --no-pager 2>/dev/null || echo "No user journal available"
fi

# Cleanup
cd /
rm -rf "$TEST_DIR"

echo
echo "=== Test complete ==="
