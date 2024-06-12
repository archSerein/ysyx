#include <common.h>
#include "syscall.h"
#include <sys/time.h>

static int
sys_gettimeofday(void *tv, void *tz) {
  struct timeval *tp = (struct timeval *)tv;
  uint64_t us = io_read(AM_TIMER_UPTIME).us;
  tp->tv_sec = us / 1000000;
  tp->tv_usec = us % 1000000;
 
  if (tz != NULL) {
    // panic("todo: implement gettimeofday");
  }
  return 0;
}

extern int fs_open(const char *pathname, int flags, int mode);
extern size_t fs_read(int fd, void *buf, size_t len);
extern size_t fs_write(int fd, const void *buf, size_t len);
extern int fs_close(int fd);
extern size_t fs_lseek(int fd, size_t offset, int whence);

void do_syscall(Context *c) {
  uintptr_t a[4];
  a[0] = c->GPR1;

  switch (a[0]) {
    case SYS_exit:
                  halt(c->GPRx);
                  break;
    case SYS_yield:
                  yield();
                  c->GPRx = 0;
                  break;
    case SYS_write:
                  c->GPRx = fs_write(c->GPR2, (void *)c->GPR3, c->GPR4);
                  break;
    case SYS_brk:
                  // malloc(c->GPR2);
                  c->GPRx = 0;
                  break;
    case SYS_open:
                  c->GPRx = fs_open((char *)c->GPR2, c->GPR3, c->GPR4);
                  break;
    case SYS_read:
                  c->GPRx = fs_read(c->GPR2, (void *)c->GPR3, c->GPR4);
                  break;
    case SYS_close:
                  c->GPRx = 0;
                  break;
    case SYS_lseek:
                  c->GPRx = fs_lseek(c->GPR2, c->GPR3, c->GPR4);
                  break;
    case SYS_gettimeofday:
                  c->GPRx = sys_gettimeofday((void *)c->GPR2, (void *)c->GPR3);
                  break;
    default: panic("Unhandled syscall ID = %d", a[0]);
  }
}
