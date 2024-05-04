#include <klib.h>
#include <klib-macros.h>
#include <stdint.h>

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)

size_t strlen(const char *s) {
  // panic("Not implemented");
  size_t len = 0;
  while(*(s + len)) ++len;
  return len;
}

char *strcpy(char *dst, const char *src) {
  // panic("Not implemented");
  size_t i;
  for(i = 0; *(src + i); *(dst + i) = *(src + i), ++i);
  *(dst + i) = '\0';
  return dst;
}

char *strncpy(char *dst, const char *src, size_t n) {
  // panic("Not implemented");
  size_t i;
  for(i = 0; i < n && *(src + i) != '\0'; i++)
    *(dst + i) = *(src + i);
  for(; i < n; i++)
    *(dst + i) = '\0';

  return dst;
}

char *strcat(char *dst, const char *src) {
  // panic("Not implemented");
  size_t dst_len = strlen(dst);
  size_t i;

  for(i = 0; src[i] != '\0'; i++)
  {
    dst[dst_len + i] = src[i];
  }

  dst[dst_len + i] = '\0';

  return dst;
}

int strcmp(const char *s1, const char *s2) {
  // panic("Not implemented");
  size_t i;
  for(i = 0; s1[i] != '\0' || s2[i] != '\0'; i++)
  {
    int ret = s1[i] - s2[i];
    if(ret)
      return ret;
  }

  return 0;
}

int strncmp(const char *s1, const char *s2, size_t n) {
  // panic("Not implemented");
  size_t i;
  for(i = 0; i < n && (s1[i] != '\0' || s2[i] != '\0'); i++)
  {
    int ret = s1[i] - s2[i];
    if(ret)
      return ret;
  }

  return 0;
}

void *memset(void *s, int c, size_t n) {
  // panic("Not implemented");
  char *tmp = (char *)s;
  size_t i;
  if(s == NULL || n < 0)
    return NULL;
  for(i = 0; i < n; i++)
    *(tmp + i) = (char)c;

  return s;
}

void *memmove(void *dst, const void *src, size_t n) {
  // panic("Not implemented");
  const char *s;
  char *d;

  if(n == 0)
    return dst;
  s = src;
  d = dst;

  if(s < d && s + n > d)
  {
    s += n;
    d += n;

    while(n-- > 0)
      *--d = *--s;
  } else {
    while(n-- > 0)
      *d++ = *s++;
  }
  return dst;
}

void *memcpy(void *out, const void *in, size_t n) {
  // panic("Not implemented");
  size_t i;

  char *cout = (char *)out;
  const char *cin = (char *)in;
  for(i = 0; i < n; i++)
  {
    *(cout + i) = *(cin + i);
  }

  return out;
}

int memcmp(const void *s1, const void *s2, size_t n) {
  // panic("Not implemented");
  if(n == 0)
    return 0;

  const char *cs1 = (char *)s1;
  const char *cs2 = (char *)s2;
  size_t i;
  for(i = 0; i < n; i++)
  {
    if(*(cs1 + i) != *(cs2 + i))
      return *(cs1 + i) - *(cs2 + i);
  }

  return 0;
}

#endif
