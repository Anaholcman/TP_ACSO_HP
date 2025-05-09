#include <stdio.h>
#include <assert.h>
#include <stdlib.h>
#include "inode.h"
#include "diskimg.h"


#define INODES_PER_BLOCK 16
#define BLOCK_SIZE 512
#define NUMS_PER_BLOCK 256

int inode_iget(struct unixfilesystem *fs, int inumber, struct inode *inp) {
    if (inumber <= 0 || inumber > fs->superblock.s_isize * INODES_PER_BLOCK) {
        return -1; 
    } 
    int sector = INODE_START_SECTOR + (inumber - 1) / INODES_PER_BLOCK;
    struct inode inodes[INODES_PER_BLOCK];
    if (diskimg_readsector(fs->dfd, sector, inodes) < 0)  {
        return -1; 
    }
    int index = (inumber - 1) % INODES_PER_BLOCK;
    *inp = inodes[index];
    return 0;
}


int inode_indexlookup(struct unixfilesystem *fs, struct inode *inp, int blockNum) {  
    if ((inp->i_mode & IALLOC) == 0) {
        return -1; 
    }

    int file_size = inode_getsize(inp);
    int max_blocks = (file_size + BLOCK_SIZE - 1) / BLOCK_SIZE;

    if (blockNum < 0 || blockNum >= max_blocks) {
        return -1; 
    }

    // small file
    if ((inp->i_mode & ILARG) == 0) {
        return inp->i_addr[blockNum]; 
    }

    // large file
    if (blockNum < 7 * NUMS_PER_BLOCK) {
        int indirect_index = blockNum / NUMS_PER_BLOCK;
        int offset = blockNum % NUMS_PER_BLOCK;
        int indirect_block = inp->i_addr[indirect_index];
        uint16_t buffer[NUMS_PER_BLOCK];
        
        if (diskimg_readsector(fs->dfd, buffer, indirect_block) < 0) {
            return -1;
        }
        return buffer[offset];
    } else {
        int adjusted_blockNum = blockNum - 7 * NUMS_PER_BLOCK;
        int dbl_indirect_block = inp->i_addr[7];
        uint16_t dbl_buffer[NUMS_PER_BLOCK];

        if (diskimg_readsector(fs->dfd, dbl_buffer, dbl_indirect_block) < 0) {
            return -1;
        }

        int second_indirect_index = adjusted_blockNum / NUMS_PER_BLOCK;
        int offset = adjusted_blockNum % NUMS_PER_BLOCK;
        int second_indirect_block = dbl_buffer[second_indirect_index];
        uint16_t second_buffer[NUMS_PER_BLOCK];

        if (diskimg_readsector(fs->dfd, second_buffer, second_indirect_block) < 0) {
            return -1;
        }

        return second_buffer[offset];
    }
}


int inode_getsize(struct inode *inp) {
  return ((inp->i_size0 << 16) | inp->i_size1); 
}
