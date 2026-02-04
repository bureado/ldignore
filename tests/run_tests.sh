#!/bin/bash

set -e

echo "=== Building test program ==="
make test_ldignore

echo ""
echo "=== Setting up test environment ==="

# Create test directory structure
mkdir -p test_dir/subdir
echo "Test file content" > test_dir/test.txt
echo "Secret content" > test_dir/secret.txt
echo "Subdir file" > test_dir/subdir/file.txt

# Create .claudeignore in test_dir
cat > test_dir/.claudeignore << 'EOF'
# Test ignore patterns
secret.txt
*.log
EOF

echo "Created test directory structure"
ls -la test_dir/

echo ""
echo "=== Test 1: Without LD_PRELOAD (baseline) ==="
./test_ldignore test_dir/test.txt

echo ""
echo "=== Test 2: With LD_PRELOAD but LDIGNORE_ENFORCE=0 (monitoring mode) ==="
LDIGNORE_DEBUG=1 LD_PRELOAD=./ldignore.so ./test_ldignore test_dir/test.txt

echo ""
echo "=== Test 3: Try to access ignored file with LDIGNORE_ENFORCE=0 ==="
LDIGNORE_DEBUG=1 LD_PRELOAD=./ldignore.so ./test_ldignore test_dir/secret.txt || echo "Access denied (expected in enforce mode)"

echo ""
echo "=== Test 4: With LDIGNORE_ENFORCE=1 (enforcement mode) - allowed file ==="
LDIGNORE_DEBUG=1 LDIGNORE_ENFORCE=1 LD_PRELOAD=./ldignore.so ./test_ldignore test_dir/test.txt

echo ""
echo "=== Test 5: With LDIGNORE_ENFORCE=1 - blocked file ==="
LDIGNORE_DEBUG=1 LDIGNORE_ENFORCE=1 LD_PRELOAD=./ldignore.so ./test_ldignore test_dir/secret.txt && echo "ERROR: Should have been blocked!" || echo "Successfully blocked access"

echo ""
echo "=== Test 6: Test subdir access ==="
LDIGNORE_DEBUG=1 LDIGNORE_ENFORCE=1 LD_PRELOAD=./ldignore.so ./test_ldignore test_dir/subdir/file.txt

echo ""
echo "=== Cleanup ==="
rm -rf test_dir

echo ""
echo "=== All tests completed successfully! ==="
