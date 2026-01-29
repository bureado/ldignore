# ldignore

Uses LD_PRELOAD to enforce .claudeignore and .copilotignore files

## Overview

`ldignore` is a library that intercepts file system operations (open, openat, readlink, readlinkat) and checks if the accessed paths are listed in `.claudeignore` or `.copilotignore` files in the directory hierarchy. This allows you to enforce access controls based on ignore patterns using LD_PRELOAD.

## Features

- Intercepts `open()`, `openat()`, `readlink()`, and `readlinkat()` system calls
- Searches for `.claudeignore` and `.copilotignore` files up the directory tree
- Supports glob patterns using fnmatch
- Two modes of operation:
  - **Monitoring mode** (default): Logs blocked access attempts but allows them
  - **Enforcement mode**: Actually blocks access to ignored files with EACCES

## Building

```bash
make
```

This will create `ldignore.so` in the current directory.

## Usage

### Basic Usage

Run any program with the library preloaded:

```bash
LD_PRELOAD=./ldignore.so your_program [args...]
```

### Enable Enforcement Mode

By default, the library only monitors and logs access attempts. To actually block access to ignored files:

```bash
LDIGNORE_ENFORCE=1 LD_PRELOAD=./ldignore.so your_program [args...]
```

### Enable Debug Output

To see which files are being blocked, debug messages are logged to syslog:

```bash
LDIGNORE_DEBUG=1 LD_PRELOAD=./ldignore.so your_program [args...]
```

Debug messages can be viewed using `journalctl`:
```bash
journalctl -t ldignore -f
```

Or by checking `/var/log/syslog` or `/var/log/messages` depending on your system configuration.

**Security Note**: Debug log messages include file paths that are blocked or accessed. These messages are stored in system logs which may be accessible to other users or log aggregation systems. Be aware of this when enabling debug mode in production environments.

### Combined Example

```bash
LDIGNORE_DEBUG=1 LDIGNORE_ENFORCE=1 LD_PRELOAD=./ldignore.so cat secret.txt
```

## Ignore File Format

Create a `.claudeignore` or `.copilotignore` file in any directory. The library will search up the directory tree from the accessed file.

Example `.claudeignore`:
```
# Comments start with #
secret.txt
*.log
*.tmp
build/
node_modules/
```

Patterns are matched using fnmatch with FNM_PATHNAME flag.

## Testing

Run the test suite:

```bash
make test
```

## Environment Variables

- `LDIGNORE_ENFORCE`: Set to `1` to enable enforcement mode (default: `0`)
- `LDIGNORE_DEBUG`: Set to `1` to enable debug logging (default: `0`)

## Installation

To install system-wide:

```bash
sudo make install
```

This installs the library to `/usr/local/lib/`.

## How It Works

1. The library uses `dlsym(RTLD_NEXT, ...)` to get pointers to the real system calls
2. When a program calls `open()`, `openat()`, `readlink()`, or `readlinkat()`, our wrapper is called first
3. The wrapper normalizes the path and searches up the directory tree for `.claudeignore` or `.copilotignore` files
4. If found, it reads the patterns and checks if the accessed path matches any pattern
5. In enforcement mode, access is denied with EACCES if the path matches
6. Otherwise, the call is passed through to the real system call

## Limitations

- Pattern matching uses simple fnmatch, not full gitignore-style patterns
- Performance impact on programs that open many files
- Only intercepts the specified system calls (open family and readlink family)
- Requires LD_PRELOAD to be set for each process

## License

See repository license.
