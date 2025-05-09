#include <stdio.h>
#include <assert.h>
#include <stdlib.h>
#include "file.h"
#include "inode.h"
#include "diskimg.h"

#define BLOCK_SIZE 512

int file_getblock(struct unixfilesystem *fs, int inumber, int blockNum, void *buf) {
    struct inode inode_struct;
    if (inode_iget(fs, inumber, &inode_struct)<0){
        return -1;
    }
    int inode_size = inode_getsize(&inode_struct);
    int max_blocks = (inode_size + BLOCK_SIZE-1) / BLOCK_SIZE;

    if (blockNum < 0 || blockNum >=max_blocks){
        return -1;
    }

    int block_disc_index = inode_indexlookup(fs, &inode_struct, blockNum);
    if (block_disc_index < 0) return -1;
    if (diskimg_readsector(fs->dfd, block_disc_index, buf)< 0) return -1;
    
    int last_block_bytes = inode_size % BLOCK_SIZE;
    if (last_block_bytes == 0 && blockNum == max_blocks -1){
        last_block_bytes = BLOCK_SIZE;
    }
    int valid_bytes;
    if (blockNum == max_blocks - 1) {
        valid_bytes = last_block_bytes;
    } else {
        valid_bytes = BLOCK_SIZE;
    }
    return valid_bytes;
}

