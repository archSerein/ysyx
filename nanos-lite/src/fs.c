#include <fs.h>

typedef size_t (*ReadFn) (void *buf, size_t offset, size_t len);
typedef size_t (*WriteFn) (const void *buf, size_t offset, size_t len);

typedef struct {
  char *name;
  size_t size;
  size_t disk_offset;
  ReadFn read;
  WriteFn write;
} Finfo;

enum {FD_STDIN, FD_STDOUT, FD_STDERR, FD_FB};

size_t invalid_read(void *buf, size_t offset, size_t len) {
  panic("invalid_read: should not reach here");
  return 0;
}

size_t invalid_write(const void *buf, size_t offset, size_t len) {
  panic("invalid_write: should not reach here");
  return 0;
}

/* This is the information about all files in disk. */
static Finfo file_table[] __attribute__((used)) = {
  [FD_STDIN]  = {"stdin", 0, 0, invalid_read, invalid_write},
  [FD_STDOUT] = {"stdout", 0, 0, invalid_read, invalid_write},
  [FD_STDERR] = {"stderr", 0, 0, invalid_read, invalid_write},
#include "files.h"
};

size_t disk_offset_start[24];

void init_fs() {
  // TODO: initialize the size of /dev/fb
}

#define NR_FILES 24

extern size_t serial_write(const void *buf, size_t offset, size_t len);
extern size_t ramdisk_write(const void *buf, size_t offset, size_t len);
int
fs_open(const char *pathname, int flags, int mode) {
  int fd = 0;
  for (fd = 0; fd < NR_FILES; fd++) {
    if (strcmp(pathname, file_table[fd].name) == 0) {
      disk_offset_start[fd] = file_table[fd].disk_offset;
      #ifdef CONFIG_STRACE
        printf("fs_open: open file %s\n", file_table[fd].name);
      #endif // !CONFIG_STRACE
      return fd;
    }
  }
  panic("no such file: %s", pathname);
  return -1;
}

size_t
fs_lseek(int fd, size_t offset, int whence) {
  switch (whence) {
    case SEEK_SET: file_table[fd].disk_offset = disk_offset_start[fd] + offset; break;
    case SEEK_CUR: file_table[fd].disk_offset += offset; break;
    case SEEK_END: file_table[fd].disk_offset = file_table[fd].size + offset; break;
    default: panic("should not reach here");
  }
  #ifdef CONFIG_STRACE
    printf("fs_lseek: change the file offset, current disk_offset->0x%x\n", file_table[fd].disk_offset);
  #endif // !CONFIG_STRACE
  return file_table[fd].disk_offset;
}

extern size_t ramdisk_read(void *buf, size_t offset, size_t len);
size_t
fs_read(int fd, void *buf, size_t len) {
  if (fd == FD_STDIN || fd == FD_STDOUT || fd == FD_STDERR)
    return 0;
  size_t ret = ramdisk_read(buf, file_table[fd].disk_offset, len);
  fs_lseek(fd, ret, SEEK_CUR);
  #ifdef CONFIG_STRACE
    printf("fs_read: read %d bytes form the file %s\n", ret, file_table[fd].name);
  #endif // !CONFIG_STRACE
  return ret;
}

size_t
fs_write(int fd, const void *buf, size_t len) {
  size_t ret;
  if (file_table[fd].write != NULL) {
    ret = serial_write(buf, 0, len);
    #ifdef CONFIG_STRACE
      printf("output %d bytes to terminal\n", ret);
    #endif // !CONFIG_STRACE
    return ret;
  } else {
    ret = ramdisk_write(buf, file_table[fd].disk_offset, len);
    fs_lseek(fd, ret, SEEK_CUR);
    #ifdef CONFIG_STRACE
      printf("output %d bytes to file %s\n", ret, file_table[fd].name);
    #endif // !CONFIG_STRACE
  }
  return ret;
}

int
fs_close(int fd) {
  #ifdef CONFIG_STRACE
    printf("fs_close: close the file %s\n", file_table[fd].name);
  #endif // !CONFIG_STRACE
  return 0;
}
