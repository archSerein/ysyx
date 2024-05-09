#include <am.h>

#define FB_ADDR         (0xa0000000 + 0x1000000)
#define VGACTL_ADDR     (0xa0000000 + 0x0000100)
#define SYNC_ADDR (VGACTL_ADDR + 4)
#define HEIGHT_MASK 0x0000ffff
void __am_gpu_init() {
  // int i;
  // int w = 400, h = 300;
  // uint32_t *fb = (uint32_t *)(uintptr_t)FB_ADDR;
  // for (i = 0; i < w * h; i ++) fb[i] = i;
  // outl(SYNC_ADDR, 1);
}

void __am_gpu_config(AM_GPU_CONFIG_T *cfg) {

  uint32_t vga_ctl = 0;
  asm volatile("lw %0, 0(%1)" : "=r"(vga_ctl) : "r"(VGACTL_ADDR));
  uint32_t width = (vga_ctl & ~HEIGHT_MASK) >> 16;
  uint32_t height = vga_ctl & HEIGHT_MASK;
  *cfg = (AM_GPU_CONFIG_T) {
    .present = true, .has_accel = false,
    .width = width, .height = height,
    .vmemsz = 0
  };
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
    // outl(SYNC_ADDR, 1);
    asm volatile("sw %0, 0(%1)" : : "r"(1) , "r"(SYNC_ADDR));
  }
}

void __am_gpu_status(AM_GPU_STATUS_T *status) {
  status->ready = true;
}
