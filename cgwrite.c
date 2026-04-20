/*
 * cgwrite.c — setuid root helper for writing to cgroup files
 * Restricted to /sys/fs/cgroup/ paths only.
 * Replaces sudo+tee for dmem cgroup writes, eliminating PAM overhead.
 *
 * Build: gcc -O2 -o cgwrite cgwrite.c
 * Install: install -Dm4755 cgwrite /usr/lib/hyprland-dmemcg-boost/cgwrite
 */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <errno.h>

#define CGROUP_PREFIX "/sys/fs/cgroup/"
#define BUFSIZE 512

int main(int argc, char *argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Usage: cgwrite <cgroup-file>\n");
        return 1;
    }

    /* Restrict writes to /sys/fs/cgroup/ only */
    if (strncmp(argv[1], CGROUP_PREFIX, strlen(CGROUP_PREFIX)) != 0) {
        fprintf(stderr, "cgwrite: path must be under %s\n", CGROUP_PREFIX);
        return 1;
    }

    /* Reject path traversal attempts */
    if (strstr(argv[1], "..") != NULL) {
        fprintf(stderr, "cgwrite: path traversal not allowed\n");
        return 1;
    }

    FILE *f = fopen(argv[1], "w");
    if (!f) {
        fprintf(stderr, "cgwrite: cannot open %s: %s\n", argv[1], strerror(errno));
        return 1;
    }

    char buf[BUFSIZE];
    if (fgets(buf, sizeof(buf), stdin)) {
        if (fputs(buf, f) == EOF) {
            fprintf(stderr, "cgwrite: write failed: %s\n", strerror(errno));
            fclose(f);
            return 1;
        }
    }

    fclose(f);
    return 0;
}
