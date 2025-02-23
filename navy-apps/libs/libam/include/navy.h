#ifndef __NAVY_H__
#define __NAVY_H__

#include <stdio.h>
static inline uint8_t  inb(uintptr_t addr) { return *(volatile uint8_t  *)addr; }
static inline uint16_t inw(uintptr_t addr) { return *(volatile uint16_t *)addr; }
static inline uint32_t inl(uintptr_t addr) { return *(volatile uint32_t *)addr; }

static inline void outb(uintptr_t addr, uint8_t  data) { *(volatile uint8_t  *)addr = data; }
static inline void outw(uintptr_t addr, uint16_t data) { *(volatile uint16_t *)addr = data; }
static inline void outl(uintptr_t addr, uint32_t data) { *(volatile uint32_t *)addr = data; }

#define DEVICE_BASE 0xa0000000
#define SERIAL_PORT (DEVICE_BASE + 0x3f8)
#define RTC_ADDR    (DEVICE_BASE + 0x48)
#define VGACTL_ADDR (DEVICE_BASE + 0x100)
#define KBD_ADDR    (DEVICE_BASE + 0x60)
#define SYNC_ADDR   (VGACTL_ADDR + 4)
#define FB_ADDR     (DEVICE_BASE + 0x1000000)
#endif
