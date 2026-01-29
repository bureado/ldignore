#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>

int main(int argc, char *argv[]) {
    if (argc < 2) {
        fprintf(stderr, "Usage: %s <file_to_open>\n", argv[0]);
        return 1;
    }
    
    const char *filepath = argv[1];
    
    printf("Attempting to open: %s\n", filepath);
    
    int fd = open(filepath, O_RDONLY);
    if (fd < 0) {
        printf("Failed to open: %s (errno=%d: %s)\n", filepath, errno, strerror(errno));
        return 1;
    }
    
    printf("Successfully opened: %s (fd=%d)\n", filepath, fd);
    
    /* Read some data */
    char buffer[256];
    ssize_t bytes_read = read(fd, buffer, sizeof(buffer) - 1);
    if (bytes_read > 0) {
        buffer[bytes_read] = '\0';
        printf("Read %zd bytes: %.50s...\n", bytes_read, buffer);
    }
    
    close(fd);
    
    /* Test readlink on /proc/self/exe */
    printf("\nAttempting to readlink /proc/self/exe\n");
    char link_buf[1024];
    ssize_t link_len = readlink("/proc/self/exe", link_buf, sizeof(link_buf) - 1);
    if (link_len > 0) {
        link_buf[link_len] = '\0';
        printf("Successfully read link: %s\n", link_buf);
    } else {
        printf("Failed to readlink (errno=%d: %s)\n", errno, strerror(errno));
    }
    
    return 0;
}
