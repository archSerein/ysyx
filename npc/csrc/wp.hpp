#ifndef __WP_HPP_
#define __WP_HPP_

typedef struct watchpoint {
  int NO;
  uint32_t result;
  char str[32];
  int hit_count;
  bool enable;
  struct watchpoint *next;

  /* TODO: Add more members if necessary */

} WP;

uint32_t expr(char *e, bool *success);
WP* new_wp(char *e);
int free_wp(int NO);
void init_wp_pool();
void info_w();

#endif // __WP_HPP_