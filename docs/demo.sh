#!/bin/bash
# Example demonstration of ldignore

echo "=== ldignore Demonstration ==="
echo ""

# Create example directory structure
mkdir -p example_project
cd example_project

# Create some files
cat > main.c << 'EOF'
#include <stdio.h>
int main() {
    printf("Hello World\n");
    return 0;
}
EOF

cat > secret_key.txt << 'EOF'
API_KEY=super_secret_12345
DATABASE_PASSWORD=my_password
EOF

cat > README.txt << 'EOF'
This is a public README file.
EOF

# Create .claudeignore
cat > .claudeignore << 'EOF'
# Ignore secret files
secret_key.txt
*.key
*.pem
EOF

echo "Created example project with:"
ls -la

echo ""
echo "=== Example 1: Normal file access (without ldignore) ==="
cat secret_key.txt
echo ""

echo "=== Example 2: With ldignore in monitoring mode ==="
echo "Notice it logs but still allows access:"
LDIGNORE_DEBUG=1 LD_PRELOAD=../ldignore.so cat secret_key.txt
echo ""

echo "=== Example 3: With ldignore in enforcement mode ==="
echo "This will block access to secret_key.txt:"
LDIGNORE_DEBUG=1 LDIGNORE_ENFORCE=1 LD_PRELOAD=../ldignore.so cat secret_key.txt 2>&1 || echo "Access denied!"
echo ""

echo "=== Example 4: Accessing non-ignored file with enforcement ==="
echo "This should work fine:"
LDIGNORE_DEBUG=1 LDIGNORE_ENFORCE=1 LD_PRELOAD=../ldignore.so cat README.txt
echo ""

# Cleanup
cd ..
rm -rf example_project

echo "=== Demonstration complete ==="
