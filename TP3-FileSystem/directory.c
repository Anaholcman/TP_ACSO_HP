#include "directory.h"
#include "inode.h"
#include "diskimg.h"
#include "file.h"
#include <stdio.h>
#include <string.h>
#include <assert.h>

#define BLOCK_SIZE 512
#define DIR_NAME_SIZE 14

int directory_findname(struct unixfilesystem *fs, const char *name, int dirinumber, struct direntv6 *dirEnt) {
  
  struct inode dir_inode;
  if (inode_iget(fs, dirinumber, &dir_inode) < 0) return -1;
  if ((dir_inode.i_mode & IFMT) != IFDIR) return -1;

  int size = inode_getsize(&dir_inode);
  int max_blocks = (size + BLOCK_SIZE - 1) / BLOCK_SIZE;

  for (int b = 0; b < max_blocks; b++) {
    struct direntv6 buffer[BLOCK_SIZE / sizeof(struct direntv6)];
    int valid = file_getblock(fs, dirinumber, b, buffer);
    if (valid < 0) return -1;

    int num_entries = valid / sizeof(struct direntv6);
    for (int i = 0; i < num_entries; i++) {
        if (strncmp(buffer[i].d_name, name, DIR_NAME_SIZE) == 0) {
            *dirEnt = buffer[i];
            return 0;
        }
    }
  }
    return -1;

}
