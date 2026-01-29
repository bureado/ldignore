#define _GNU_SOURCE
#include "ignore_parser.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <libgen.h>
#include <fnmatch.h>
#include <sys/stat.h>
#include <errno.h>
#include <limits.h>

static int initialized = 0;

void ignore_init(void) {
    if (!initialized) {
        initialized = 1;
    }
}

void ignore_cleanup(void) {
    initialized = 0;
}

/**
 * Normalize a path to absolute form
 */
static char* normalize_path(const char *path, char *buf, size_t bufsize) {
    if (!path || !buf || bufsize == 0) {
        return NULL;
    }
    
    /* If already absolute, copy it */
    if (path[0] == '/') {
        strncpy(buf, path, bufsize - 1);
        buf[bufsize - 1] = '\0';
        return buf;
    }
    
    /* Get current working directory and append relative path */
    char cwd[MAX_PATH_LEN];
    if (getcwd(cwd, sizeof(cwd)) == NULL) {
        return NULL;
    }
    
    snprintf(buf, bufsize, "%s/%s", cwd, path);
    return buf;
}

/**
 * Read patterns from an ignore file
 * Returns number of patterns read
 */
static int read_patterns_from_file(const char *filepath, char patterns[][MAX_PATTERN_LEN], int max_patterns) {
    FILE *fp = fopen(filepath, "r");
    if (!fp) {
        return 0;
    }
    
    int count = 0;
    char line[MAX_PATTERN_LEN];
    
    while (count < max_patterns && fgets(line, sizeof(line), fp)) {
        /* Remove trailing newline */
        size_t len = strlen(line);
        if (len > 0 && line[len - 1] == '\n') {
            line[len - 1] = '\0';
            len--;
        }
        
        /* Skip empty lines and comments */
        if (len == 0 || line[0] == '#') {
            continue;
        }
        
        /* Copy pattern */
        strncpy(patterns[count], line, MAX_PATTERN_LEN - 1);
        patterns[count][MAX_PATTERN_LEN - 1] = '\0';
        count++;
    }
    
    fclose(fp);
    return count;
}

/**
 * Check if a path matches any pattern
 */
static bool matches_pattern(const char *path, const char *pattern, const char *basedir) {
    if (!path || !pattern) {
        return false;
    }
    
    /* Create relative path from basedir */
    const char *relpath = path;
    if (basedir && strncmp(path, basedir, strlen(basedir)) == 0) {
        relpath = path + strlen(basedir);
        while (*relpath == '/') {
            relpath++;
        }
    }
    
    /* Match against full path */
    if (fnmatch(pattern, relpath, FNM_PATHNAME) == 0) {
        return true;
    }
    
    /* Match against basename */
    char *path_copy = strdup(relpath);
    if (path_copy) {
        char *base = basename(path_copy);
        if (fnmatch(pattern, base, 0) == 0) {
            free(path_copy);
            return true;
        }
        free(path_copy);
    }
    
    /* Match with wildcards */
    char pattern_with_prefix[MAX_PATTERN_LEN];
    snprintf(pattern_with_prefix, sizeof(pattern_with_prefix), "**/%s", pattern);
    if (fnmatch(pattern_with_prefix, relpath, FNM_PATHNAME) == 0) {
        return true;
    }
    
    return false;
}

/**
 * Check if path should be ignored by looking up directory hierarchy
 */
bool should_ignore(const char *path) {
    if (!initialized) {
        ignore_init();
    }
    
    if (!path) {
        return false;
    }
    
    /* Normalize the path */
    char abs_path[MAX_PATH_LEN];
    if (!normalize_path(path, abs_path, sizeof(abs_path))) {
        return false;
    }
    
    /* Walk up the directory hierarchy */
    char current_dir[MAX_PATH_LEN];
    char *path_copy = strdup(abs_path);
    if (!path_copy) {
        return false;
    }
    
    char *dir = dirname(path_copy);
    strncpy(current_dir, dir, sizeof(current_dir) - 1);
    current_dir[sizeof(current_dir) - 1] = '\0';
    free(path_copy);
    
    /* Keep going up until we reach root */
    while (strlen(current_dir) > 0) {
        /* Check for .claudeignore and .copilotignore */
        const char *ignore_files[] = {".claudeignore", ".copilotignore"};
        
        for (int i = 0; i < 2; i++) {
            char ignore_path[MAX_PATH_LEN];
            snprintf(ignore_path, sizeof(ignore_path), "%s/%s", current_dir, ignore_files[i]);
            
            /* Check if ignore file exists */
            struct stat st;
            if (stat(ignore_path, &st) == 0 && S_ISREG(st.st_mode)) {
                /* Read patterns from file */
                char patterns[MAX_PATTERNS][MAX_PATTERN_LEN];
                int pattern_count = read_patterns_from_file(ignore_path, patterns, MAX_PATTERNS);
                
                /* Check if path matches any pattern */
                for (int j = 0; j < pattern_count; j++) {
                    if (matches_pattern(abs_path, patterns[j], current_dir)) {
                        return true;
                    }
                }
            }
        }
        
        /* Move up one directory */
        if (strcmp(current_dir, "/") == 0) {
            break;
        }
        
        path_copy = strdup(current_dir);
        if (!path_copy) {
            break;
        }
        
        dir = dirname(path_copy);
        strncpy(current_dir, dir, sizeof(current_dir) - 1);
        current_dir[sizeof(current_dir) - 1] = '\0';
        free(path_copy);
        
        /* Avoid infinite loop */
        if (strcmp(current_dir, ".") == 0 || strlen(current_dir) == 0) {
            break;
        }
    }
    
    return false;
}
