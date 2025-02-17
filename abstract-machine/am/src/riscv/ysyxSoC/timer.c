#include <am.h>

#define RTC_ADDR        (0x02000000 + 0x0000048)
void __am_timer_init() {
}

void __am_timer_uptime(AM_TIMER_UPTIME_T *uptime) {
  uint32_t low, high;
  asm volatile("lw %0, 0(%1)" : "=r"(low) : "r"(RTC_ADDR));
  asm volatile("lw %0, 4(%1)" : "=r"(high) : "r"(RTC_ADDR));

  uptime->us = high;
  uptime->us = uptime->us << 32 | low;
}

void __am_timer_rtc(AM_TIMER_RTC_T *rtc) {
  rtc->second = 0;
  rtc->minute = 0;
  rtc->hour   = 0;
  rtc->day    = 0;
  rtc->month  = 0;
  rtc->year   = 1900;
}
