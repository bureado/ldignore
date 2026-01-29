#!/bin/bash

echo "================================================================"
echo "SYSLOG INTEGRATION DEMONSTRATION"
echo "================================================================"
echo ""

# Create a test environment
TEST_DIR=$(mktemp -d)
cd "$TEST_DIR"

echo "Setting up test directory..."
echo "secret.txt" > .claudeignore
echo "*.key" >> .claudeignore
echo "This is a secret file" > secret.txt
echo "This is a public file" > public.txt
echo "API_KEY=12345" > config.key

echo "Created test files:"
ls -la
echo ""
echo "Ignore patterns (.claudeignore):"
cat .claudeignore
echo ""

# Export variables
export LD_PRELOAD=/home/runner/work/ldignore/ldignore/ldignore.so
export LDIGNORE_DEBUG=1
export LDIGNORE_ENFORCE=1

echo "================================================================"
echo "Running tests with LDIGNORE_DEBUG=1 and LDIGNORE_ENFORCE=1"
echo "================================================================"
echo ""

echo "1. Trying to open 'public.txt' (not in .claudeignore)..."
if /home/runner/work/ldignore/ldignore/test_ldignore public.txt 2>&1 | head -2; then
    echo "   ✓ Access allowed (as expected)"
else
    echo "   ✗ Access denied (unexpected)"
fi
echo ""

echo "2. Trying to open 'secret.txt' (in .claudeignore)..."
if /home/runner/work/ldignore/ldignore/test_ldignore secret.txt 2>&1 | head -2; then
    echo "   ✗ Access allowed (unexpected)"
else
    echo "   ✓ Access denied (as expected)"
fi
echo ""

echo "3. Trying to open 'config.key' (matches *.key pattern)..."
if /home/runner/work/ldignore/ldignore/test_ldignore config.key 2>&1 | head -2; then
    echo "   ✗ Access allowed (unexpected)"
else
    echo "   ✓ Access denied (as expected)"
fi
echo ""

sleep 1

echo "================================================================"
echo "SYSLOG OUTPUT (last 10 ldignore messages):"
echo "================================================================"
journalctl -t ldignore -n 10 --no-pager 2>/dev/null | sed 's/^/  /'
echo ""

# Cleanup
cd /
rm -rf "$TEST_DIR"

echo "================================================================"
echo "DEMONSTRATION COMPLETE"
echo "================================================================"
echo ""
echo "Key points:"
echo "  • Debug messages now appear in system log (journalctl)"
echo "  • Messages include process ID for tracking"
echo "  • Both blocked access and initialization messages are logged"
echo "  • Syslog is ONLY initialized when LDIGNORE_DEBUG=1 (performance)"
echo ""
