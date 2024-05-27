#include <am.h>
#include <klib.h>
#include <klib-macros.h>
#include <stdarg.h>

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)

static char digital[] = "0123456789abcdef";


static int
cpustr(char *dst, int num, int base)
{
  if(num == 0)
  {
    *dst = digital[0];
    return 1;
  }
  
  int tmp = num;
  int count = 0;
  while(tmp != 0)
  {
    tmp /= 10;
    ++count;
  }
  dst += (count-1);

  while(num != 0)
  {
    *dst = digital[num % base];
    num /= 10;
    --dst;
  }

  return count;
}

static char NumberToChar[64] = {};
static void
printint(unsigned num, int base, int sign, int width) {
  if(num == 0)
  {
    putch('0');
    return;
  }
  
  bool neg = false;
  if ((int)num < 0 && sign) {
    neg = true;
  }
  int i = 0;
  do {
      NumberToChar[i++] = digital[num % base];
      num /= base;
  } while(num != 0);

  if (width > 0)
  {
    while(i < width - 1)
    {
      NumberToChar[i++] = '0';
    }
  }
  if (neg) {
    NumberToChar[i++] = '-';
  } else if (width > 0) {
    NumberToChar[i++] = '0';
  }

  while(--i >= 0) {
    putch(NumberToChar[i]);
  }
}

static void
printptr(unsigned long num) {
  int i;

  for (i = 0; i < (sizeof(unsigned long) << 1); i++) {
    putch(digital[(num >> ((sizeof(unsigned long) << 3) - 4)) & 0xf]);
    num <<= 4;
  }
}

int printf(const char *fmt, ...) {
  // panic("Not implemented");
  va_list ap;

  va_start(ap, fmt);
  size_t i;

  for (i = 0; fmt[i] != '\0'; i++) {
    if (fmt[i] == '%') {
      ++i;
      int width = 0;
      if (fmt[i] >= '0' && fmt[i] <= '9') {
        while(fmt[i] >= '0' && fmt[i] <= '9') {
          width = width * 10 + fmt[i] - '0';
          ++i;
        }
      }
      switch (fmt[i]) {
        case 'd': {
          printint(va_arg(ap, int), 10, 1, width);
          break;
        }
        case 's': {
          putstr(va_arg(ap, char *));
          break;
        }
        case 'x': {
          printint(va_arg(ap, unsigned), 16, 0, width);
          break;
        }
        case '%': {
          putch('%');
          break;
        }
        case 'c': {
          putch(va_arg(ap, int));
          break;
        }
        case 'p': {
          putch('0');
          putch('x');
          printptr(va_arg(ap, unsigned long));
        }
        default: putch(fmt[i]); panic("Not implemented");
      }
    } else {
      putch(fmt[i]);
    }
  }

  return (int)i;
}

int vsprintf(char *out, const char *fmt, va_list ap) {
  panic("Not implemented");
  
}

int sprintf(char *out, const char *fmt, ...) {
  // panic("Not implemented");
  va_list ap;

  va_start(ap, fmt);
  size_t i;
  size_t j = 0;
  for(i = 0; fmt[i] != '\0'; i++)
  {
      int num = 0;
      if(fmt[i] == '%')
      {
        ++i;
        switch(fmt[i])
        {
          case 'd' :
              num = va_arg(ap, int);
              j += cpustr(out + j, num, 10);
              break;
          case 's':
              const char *str = va_arg(ap, char *);
              strcpy(out + j, str);
              j += strlen(str);
              break;
          case 'x':
              num = va_arg(ap, int);
              j += cpustr(out + j, num, 16);
              break;
          case '%' :
              *out++ = '%';
              break;
          default:  panic("Not implemented");
        }
      }
      else {
          strncpy(out + j, &fmt[i], 1);
          ++j;
      }
  }

  va_end(ap);
  *(out + j) = '\0';
  return (int)j;
}

int snprintf(char *out, size_t n, const char *fmt, ...) {
  panic("Not implemented");
}

int vsnprintf(char *out, size_t n, const char *fmt, va_list ap) {
  panic("Not implemented");
}

#endif
