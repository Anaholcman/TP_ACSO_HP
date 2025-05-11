
#include "pathname.h"
#include "directory.h"
#include "inode.h"
#include "diskimg.h"
#include <stdio.h>
#include <string.h>
#include <assert.h>

#define ROOT_INODE 1

int pathname_lookup(struct unixfilesystem *fs, const char *pathname) {
	int inumber = ROOT_INODE;

    char path_copy[strlen(pathname) + 1];
    strcpy(path_copy, pathname);

    
    char *token = strtok(path_copy, "/");
    while (token != NULL) {
        struct direntv6 entry;
        int dir_name = directory_findname(fs, token, inumber, &entry);
        if (dir_name < 0) {
            return -1;  
        }
        inumber = entry.d_inumber;
        token = strtok(NULL, "/");
    }

    return inumber;
}
