#include <NDL.h>
#include <sdl-timer.h>
#include <stdio.h>

SDL_TimerID SDL_AddTimer(uint32_t interval, SDL_NewTimerCallback callback, void *param) {
  return NULL;
}

int SDL_RemoveTimer(SDL_TimerID id) {
  return 1;
}

static uint32_t start_time = -1;
uint32_t SDL_GetTicks() {
  uint32_t ticks = NDL_GetTicks();
  if (start_time == -1) {
    start_time = ticks;
    return 0;
  } else {
    return ticks - start_time;
  }
}

void SDL_Delay(uint32_t ms) {
}
