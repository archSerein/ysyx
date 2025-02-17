#include <unistd.h>
#include <stdio.h>
#include <NDL.h>

int main() {
  uint32_t ticks;
  NDL_Init(0);
  ticks = NDL_GetTicks();
  __uint64_t ms = 500;
  while (1) {
    while (ticks < ms) {
      ticks = NDL_GetTicks();
    }
    ms += 500;
    printf("Hello world!\n");
  }
}
