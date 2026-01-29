# ldignore Usage Examples

This document provides practical examples of using ldignore to enforce ignore patterns.

## Example 1: Basic Usage

Prevent a program from accessing sensitive files:

```bash
# Create an ignore file
echo "passwords.txt" > .claudeignore

# Run a program with ldignore in monitoring mode
LDIGNORE_DEBUG=1 LD_PRELOAD=./ldignore.so cat passwords.txt

# Run with enforcement
LDIGNORE_DEBUG=1 LDIGNORE_ENFORCE=1 LD_PRELOAD=./ldignore.so cat passwords.txt
# This will fail with "Permission denied"
```

## Example 2: Protecting Development Secrets

```bash
# In your project directory
cat > .claudeignore << EOF
# API keys and secrets
.env
.env.local
secrets/
*.key
*.pem
credentials.json

# Build artifacts that might contain secrets
dist/
build/
EOF

# Run your build tool with ldignore
LDIGNORE_ENFORCE=1 LD_PRELOAD=/path/to/ldignore.so npm run build
```

## Example 3: Preventing Access to Node Modules

```bash
echo "node_modules/" > .claudeignore

# Any program trying to read files in node_modules will be blocked
LDIGNORE_DEBUG=1 LDIGNORE_ENFORCE=1 LD_PRELOAD=./ldignore.so find . -name "*.js"
```

## Example 4: Hierarchical Ignore Files

ldignore searches up the directory tree for ignore files:

```
/project/.claudeignore          # Contains: *.log
/project/subdir/.claudeignore   # Contains: temp.txt
```

When accessing `/project/subdir/temp.txt`, both ignore files are checked.

## Example 5: Using with Servers

Prevent web servers from accessing sensitive files:

```bash
cat > .copilotignore << EOF
/etc/passwd
/etc/shadow
~/.ssh/
/root/
EOF

# Run nginx with ldignore
LDIGNORE_ENFORCE=1 LD_PRELOAD=/usr/local/lib/ldignore.so nginx
```

## Example 6: Debugging

Use debug mode to see what files are being checked:

```bash
LDIGNORE_DEBUG=1 LD_PRELOAD=./ldignore.so ls -la
```

This will print messages like:
```
[ldignore] Initialized (enforce=0)
[ldignore] Blocked open: secret.txt
```

## Example 7: Glob Patterns

ldignore supports glob patterns:

```bash
cat > .claudeignore << EOF
# Block all log files
*.log

# Block all files in build directory
build/*

# Block specific extensions
*.tmp
*.cache
EOF
```

## Environment Variables

- `LDIGNORE_ENFORCE=1` - Enable enforcement mode (blocks access)
- `LDIGNORE_DEBUG=1` - Enable debug output to stderr
- `LD_PRELOAD=/path/to/ldignore.so` - Preload the library

## System-Wide Installation

After installing with `sudo make install`:

```bash
# Add to /etc/ld.so.preload for all processes (use with caution!)
echo "/usr/local/lib/ldignore.so" | sudo tee -a /etc/ld.so.preload

# Or set in systemd service files
[Service]
Environment="LD_PRELOAD=/usr/local/lib/ldignore.so"
Environment="LDIGNORE_ENFORCE=1"
```

## Limitations

- Only intercepts open(), openat(), readlink(), readlinkat()
- Does not intercept direct syscalls (programs using syscall())
- Pattern matching uses fnmatch, not full gitignore syntax
- Performance overhead on file-heavy operations
