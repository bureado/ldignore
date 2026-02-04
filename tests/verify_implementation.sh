#!/bin/bash
# Final comprehensive verification of syslog implementation

set -e

echo "======================================"
echo "Final Verification of Syslog Changes"
echo "======================================"
echo ""

# 1. Check that syslog header is included
echo "✓ Checking syslog header inclusion..."
grep -q "#include <syslog.h>" ldignore.c && echo "  ✓ syslog.h is included"

# 2. Check that openlog is called
echo "✓ Checking openlog() calls..."
grep -q "openlog(" ldignore.c && echo "  ✓ openlog() is present"

# 3. Check that closelog is called
echo "✓ Checking closelog() call..."
grep -q "closelog()" ldignore.c && echo "  ✓ closelog() is present"

# 4. Check that all fprintf(stderr) calls have been replaced
echo "✓ Checking for old fprintf(stderr) calls..."
if grep -q "fprintf(stderr" ldignore.c; then
    echo "  ✗ FAIL: Found fprintf(stderr) calls that should be replaced"
    exit 1
else
    echo "  ✓ No fprintf(stderr) calls found (all replaced with syslog)"
fi

# 5. Check that syslog() calls exist
echo "✓ Checking for syslog() calls..."
SYSLOG_COUNT=$(grep -c "syslog(" ldignore.c || true)
echo "  ✓ Found $SYSLOG_COUNT syslog() calls"

# 6. Build the library
echo "✓ Building library..."
make clean > /dev/null 2>&1
make > /dev/null 2>&1
echo "  ✓ Build successful"

# 7. Run existing test suite
echo "✓ Running test suite..."
make test > /tmp/test_output.txt 2>&1
if grep -q "All tests completed successfully" /tmp/test_output.txt; then
    echo "  ✓ All tests pass"
else
    echo "  ✗ FAIL: Some tests failed"
    cat /tmp/test_output.txt
    exit 1
fi

# 8. Test syslog functionality
echo "✓ Testing syslog output..."
TEST_DIR=$(mktemp -d)
cd "$TEST_DIR"
echo "blocked.txt" > .claudeignore
echo "content" > blocked.txt

export LD_PRELOAD=/home/runner/work/ldignore/ldignore/ldignore.so
export LDIGNORE_DEBUG=1
export LDIGNORE_ENFORCE=0

# Generate a syslog entry
/home/runner/work/ldignore/ldignore/test_ldignore blocked.txt > /dev/null 2>&1
sleep 1

# Check if message appears in syslog
if journalctl -t ldignore -n 5 --no-pager 2>/dev/null | grep -q "Blocked open"; then
    echo "  ✓ Syslog messages are working correctly"
else
    echo "  ✗ FAIL: No syslog messages found"
    exit 1
fi

cd /
rm -rf "$TEST_DIR"

echo ""
echo "======================================"
echo "✓ ALL VERIFICATIONS PASSED"
echo "======================================"
echo ""
echo "Summary of changes:"
echo "  • Debug output now goes to syslog instead of stderr"
echo "  • Syslog is only initialized when LDIGNORE_DEBUG=1"
echo "  • All $SYSLOG_COUNT debug points now use syslog()"
echo "  • Security note added about file paths in logs"
echo "  • All existing tests still pass"
echo ""
