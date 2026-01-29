#ifndef IGNORE_PARSER_H
#define IGNORE_PARSER_H

#include <stdbool.h>

/* Maximum number of patterns to store */
#define MAX_PATTERNS 1024

/* Maximum pattern length */
#define MAX_PATTERN_LEN 4096

/* Maximum path length */
#define MAX_PATH_LEN 4096

/**
 * Initialize the ignore pattern cache
 * This should be called once before any pattern matching
 */
void ignore_init(void);

/**
 * Check if a path should be ignored based on .claudeignore/.copilotignore files
 * in the directory hierarchy
 * 
 * @param path The path to check (absolute or relative)
 * @return true if the path should be ignored, false otherwise
 */
bool should_ignore(const char *path);

/**
 * Clear all cached patterns
 */
void ignore_cleanup(void);

#endif /* IGNORE_PARSER_H */
