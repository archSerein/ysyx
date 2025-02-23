#include <am.h>
#include <klib-macros.h>

typedef void (*handler_t)(void *buf);
static void fail(void *buf) { panic("access nonexist register"); }

void __am_timer_init();
void __am_gpu_init();
void __am_audio_init();
void __am_input_keybrd(AM_INPUT_KEYBRD_T *);
void __am_timer_rtc(AM_TIMER_RTC_T *);
void __am_timer_uptime(AM_TIMER_UPTIME_T *);
void __am_gpu_config(AM_GPU_CONFIG_T *);
void __am_gpu_status(AM_GPU_STATUS_T *);
void __am_gpu_fbdraw(AM_GPU_FBDRAW_T *);
void __am_audio_config(AM_AUDIO_CONFIG_T *);
void __am_audio_ctrl(AM_AUDIO_CTRL_T *);
void __am_audio_status(AM_AUDIO_STATUS_T *);
void __am_audio_play(AM_AUDIO_PLAY_T *);
void __am_disk_config(AM_DISK_CONFIG_T *cfg);
void __am_disk_status(AM_DISK_STATUS_T *stat);
void __am_disk_blkio(AM_DISK_BLKIO_T *io);

static void __am_timer_config(AM_TIMER_CONFIG_T *cfg) { cfg->present = true; cfg->has_rtc = true; }
static void __am_input_config(AM_INPUT_CONFIG_T *cfg) { cfg->present = true;  }
static void __am_uart_config(AM_UART_CONFIG_T *cfg)   { cfg->present = false; }
static void __am_net_config (AM_NET_CONFIG_T *cfg)    { cfg->present = false; }

typedef void (*handler_t)(void *buf);
static void *lut[128] = {
  [AM_TIMER_CONFIG] = __am_timer_config,
  [AM_TIMER_RTC   ] = __am_timer_rtc,
  [AM_TIMER_UPTIME] = __am_timer_uptime,
  [AM_INPUT_CONFIG] = __am_input_config,
  [AM_INPUT_KEYBRD] = __am_input_keybrd,
  [AM_GPU_CONFIG  ] = __am_gpu_config,
  [AM_GPU_FBDRAW  ] = __am_gpu_fbdraw,
  // [AM_GPU_STATUS  ] = __am_gpu_status,
  [AM_UART_CONFIG ] = __am_uart_config,
  // [AM_AUDIO_CONFIG] = __am_audio_config,
  // [AM_AUDIO_CTRL  ] = __am_audio_ctrl,
  // [AM_AUDIO_STATUS] = __am_audio_status,
  // [AM_AUDIO_PLAY  ] = __am_audio_play,
  // [AM_DISK_CONFIG ] = __am_disk_config,
  // [AM_DISK_STATUS ] = __am_disk_status,
  // [AM_DISK_BLKIO  ] = __am_disk_blkio,
  [AM_NET_CONFIG  ] = __am_net_config,
};
bool ioe_init() {
  for (int i = 0; i < LENGTH(lut); i++)
    if (!lut[i]) lut[i] = fail;
  __am_timer_init();
  __am_gpu_init();
  return true;
}

void ioe_read (int reg, void *buf) { ((handler_t)lut[reg])(buf); }
void ioe_write(int reg, void *buf) { ((handler_t)lut[reg])(buf); }
void __am_timer_init() {

}
void __am_timer_rtc(AM_TIMER_RTC_T *rtc) {
  rtc->second = 0;
  rtc->minute = 0;
  rtc->hour   = 0;
  rtc->day    = 0;
  rtc->month  = 0;
  rtc->year   = 1900;
 }
void __am_timer_uptime(AM_TIMER_UPTIME_T *uptime) {
  uptime->us = inl(RTC_ADDR + 4);
  uptime->us = uptime->us << 32 | inl(RTC_ADDR);
}
#define HEIGHT_MASK 0x0000ffff
void __am_gpu_config(AM_GPU_CONFIG_T *cfg) {
  uint32_t vga_ctl = inl(VGACTL_ADDR);
  uint32_t width = (vga_ctl & ~HEIGHT_MASK) >> 16;
  uint32_t height = vga_ctl & HEIGHT_MASK;
  *cfg = (AM_GPU_CONFIG_T) {
    .present = true, .has_accel = false,
    .width = width, .height = height,
    .vmemsz = 0
  };
}
#define KEYDOWN_MASK 0x8000
void __am_input_keybrd(AM_INPUT_KEYBRD_T *kbd) {
  uint32_t keycode = inl(KBD_ADDR);
  kbd->keydown = keycode & KEYDOWN_MASK;
  kbd->keycode = keycode & ~KEYDOWN_MASK;
}
void __am_gpu_init() {

}
void __am_gpu_status(AM_GPU_STATUS_T *status) {

}
void __am_gpu_fbdraw(AM_GPU_FBDRAW_T *ctl) {
  int x = ctl->x;
  int y = ctl->y;
  int w = ctl->w;
  int h = ctl->h;

  if (!ctl->sync && (w == 0 || h == 0)) return;
  uint32_t *pixels = ctl->pixels;

  uint32_t *fb = (uint32_t *)(uintptr_t)FB_ADDR;

  uint32_t screen_width = (inl(VGACTL_ADDR) & ~HEIGHT_MASK) >> 16;

  for (int j = y; j < y + h; j ++) {
    for (int i = x; i < x + w; i ++) {
      fb[j * screen_width + i] = pixels[(j - y) * w + (i - x)];
    }
  }

  if (ctl->sync) {
    outl(SYNC_ADDR, 1);
  }
}
void __am_audio_config(AM_AUDIO_CONFIG_T *cfg) {

}
void __am_audio_ctrl(AM_AUDIO_CTRL_T *ctrl) {

}
void __am_audio_status(AM_AUDIO_STATUS_T *status) {

}
void __am_audio_play(AM_AUDIO_PLAY_T *ctl) {

}
void __am_disk_config(AM_DISK_CONFIG_T *cfg) {

}
void __am_disk_status(AM_DISK_STATUS_T *stat) {

}
void __am_disk_blkio(AM_DISK_BLKIO_T *io) {

}