#define _GNU_SOURCE
#include <dlfcn.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdarg.h>
#include <linux/limits.h>
#include "ignore_parser.h"

/* Function pointers to the real syscalls */
static int (*real_open)(const char *pathname, int flags, ...) = NULL;
static int (*real_openat)(int dirfd, const char *pathname, int flags, ...) = NULL;
static ssize_t (*real_readlink)(const char *pathname, char *buf, size_t bufsiz) = NULL;
static ssize_t (*real_readlinkat)(int dirfd, const char *pathname, char *buf, size_t bufsiz) = NULL;

/* Environment variable to control behavior */
static int enforce_mode = 0;
static int debug_mode = 0;
static int initialized = 0;

/* Initialize the library */
static void __attribute__((constructor)) ldignore_init(void) {
    if (initialized) {
        return;
    }
    
    /* Get real function pointers */
    real_open = dlsym(RTLD_NEXT, "open");
    real_openat = dlsym(RTLD_NEXT, "openat");
    real_readlink = dlsym(RTLD_NEXT, "readlink");
    real_readlinkat = dlsym(RTLD_NEXT, "readlinkat");
    
    /* Initialize ignore parser */
    ignore_init();
    
    /* Check environment variables */
    const char *enforce_env = getenv("LDIGNORE_ENFORCE");
    enforce_mode = (enforce_env && strcmp(enforce_env, "1") == 0);
    
    const char *debug_env = getenv("LDIGNORE_DEBUG");
    debug_mode = (debug_env && strcmp(debug_env, "1") == 0);
    
    if (debug_mode) {
        fprintf(stderr, "[ldignore] Initialized (enforce=%d)\n", enforce_mode);
    }
    
    initialized = 1;
}

/* Cleanup function */
static void __attribute__((destructor)) ldignore_cleanup(void) {
    if (initialized) {
        ignore_cleanup();
        initialized = 0;
    }
}

/* Helper function to resolve path from dirfd */
static char* resolve_dirfd_path(int dirfd, const char *pathname, char *buf, size_t bufsize) {
    if (!pathname) {
        return NULL;
    }
    
    /* If pathname is absolute, use it directly */
    if (pathname[0] == '/') {
        strncpy(buf, pathname, bufsize - 1);
        buf[bufsize - 1] = '\0';
        return buf;
    }
    
    /* If dirfd is AT_FDCWD, use current directory */
    if (dirfd == AT_FDCWD) {
        char cwd[PATH_MAX];
        if (getcwd(cwd, sizeof(cwd))) {
            snprintf(buf, bufsize, "%s/%s", cwd, pathname);
            return buf;
        }
        return NULL;
    }
    
    /* Try to get path from dirfd using /proc/self/fd */
    char fd_path[64];
    snprintf(fd_path, sizeof(fd_path), "/proc/self/fd/%d", dirfd);
    
    char dir_path[PATH_MAX];
    ssize_t len = real_readlink ? real_readlink(fd_path, dir_path, sizeof(dir_path) - 1) : -1;
    if (len > 0) {
        dir_path[len] = '\0';
        snprintf(buf, bufsize, "%s/%s", dir_path, pathname);
        return buf;
    }
    
    /* Fallback: just use the pathname */
    strncpy(buf, pathname, bufsize - 1);
    buf[bufsize - 1] = '\0';
    return buf;
}

/* Overloaded open() */
int open(const char *pathname, int flags, ...) {
    mode_t mode = 0;
    
    /* Handle variable arguments for mode */
    if (flags & O_CREAT) {
        va_list args;
        va_start(args, flags);
        mode = va_arg(args, mode_t);
        va_end(args);
    }
    
    if (!initialized) {
        ldignore_init();
    }
    
    if (pathname && should_ignore(pathname)) {
        if (debug_mode) {
            fprintf(stderr, "[ldignore] Blocked open: %s\n", pathname);
        }
        
        if (enforce_mode) {
            errno = EACCES;
            return -1;
        }
    }
    
    /* Call real open */
    if (flags & O_CREAT) {
        return real_open(pathname, flags, mode);
    } else {
        return real_open(pathname, flags);
    }
}

/* Overloaded openat() */
int openat(int dirfd, const char *pathname, int flags, ...) {
    mode_t mode = 0;
    
    /* Handle variable arguments for mode */
    if (flags & O_CREAT) {
        va_list args;
        va_start(args, flags);
        mode = va_arg(args, mode_t);
        va_end(args);
    }
    
    if (!initialized) {
        ldignore_init();
    }
    
    /* Resolve full path */
    char full_path[PATH_MAX];
    if (pathname && resolve_dirfd_path(dirfd, pathname, full_path, sizeof(full_path))) {
        if (should_ignore(full_path)) {
            if (debug_mode) {
                fprintf(stderr, "[ldignore] Blocked openat: %s\n", full_path);
            }
            
            if (enforce_mode) {
                errno = EACCES;
                return -1;
            }
        }
    }
    
    /* Call real openat */
    if (flags & O_CREAT) {
        return real_openat(dirfd, pathname, flags, mode);
    } else {
        return real_openat(dirfd, pathname, flags);
    }
}

/* Overloaded readlink() */
ssize_t readlink(const char *pathname, char *buf, size_t bufsiz) {
    if (!initialized) {
        ldignore_init();
    }
    
    if (pathname && should_ignore(pathname)) {
        if (debug_mode) {
            fprintf(stderr, "[ldignore] Blocked readlink: %s\n", pathname);
        }
        
        if (enforce_mode) {
            errno = EACCES;
            return -1;
        }
    }
    
    /* Call real readlink */
    return real_readlink(pathname, buf, bufsiz);
}

/* Overloaded readlinkat() */
ssize_t readlinkat(int dirfd, const char *pathname, char *buf, size_t bufsiz) {
    if (!initialized) {
        ldignore_init();
    }
    
    /* Resolve full path */
    char full_path[PATH_MAX];
    if (pathname && resolve_dirfd_path(dirfd, pathname, full_path, sizeof(full_path))) {
        if (should_ignore(full_path)) {
            if (debug_mode) {
                fprintf(stderr, "[ldignore] Blocked readlinkat: %s\n", full_path);
            }
            
            if (enforce_mode) {
                errno = EACCES;
                return -1;
            }
        }
    }
    
    /* Call real readlinkat */
    return real_readlinkat(dirfd, pathname, buf, bufsiz);
}
