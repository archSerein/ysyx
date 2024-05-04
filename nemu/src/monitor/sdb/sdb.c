/***************************************************************************************
* Copyright (c) 2014-2022 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of the Mulan PSL v2.
* You may obtain a copy of Mulan PSL v2 at:
*          http://license.coscl.org.cn/MulanPSL2
*
* THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
* EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
* MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
*
* See the Mulan PSL v2 for more details.
***************************************************************************************/

#include <isa.h>
#include <cpu/cpu.h>
#include <readline/readline.h>
#include <readline/history.h>
#include "sdb.h"

extern NEMUState nemu_state;
static int is_batch_mode = false;

void init_regex();
void init_wp_pool();

/* We use the `readline' library to provide more flexibility to read from stdin. */
static char* rl_gets() {
  static char *line_read = NULL;

  if (line_read) {
    free(line_read);
    line_read = NULL;
  }

  line_read = readline("(nemu) ");

  if (line_read && *line_read) {
    add_history(line_read);
  }

  return line_read;
}

static int cmd_c(char *args) {
  cpu_exec(-1);
  return 0;
}


static int cmd_q(char *args) {
  return -1;
}

static int cmd_help(char *args);

static int cmd_si(char *args)
{
  uint64_t N;
  if(args != NULL)
    N = atoi(args);
  else {
    N = 1;
  }
  cpu_exec(N);
  return 0;
}

static int cmd_info(char *args)
{
  if(strcmp(args, "r") == 0)
  {
    isa_reg_display();
  }
  else {
    info_w();
  }
  return 0;
}

static int cmd_x(char *args)
{
  int N = atoi(strtok(args, " "));
  char *addr = strtok(NULL, "");
  bool success = true;
  uint32_t result = expr(addr, &success);
  sprintf(addr, "0x%x", result);
  paddr_t vaddr = (paddr_t)strtol(addr, NULL, 16);
  for(int i = 0; i < N; i++)
  {
    word_t data = vaddr_read((vaddr + 4 * i), 4);
    printf("0x%08x\n", data);
  }

  return 0;
}

static int cmd_p(char *args)
{
  bool success = true;
  uint32_t result = expr(args, &success);
  if(success)
  {
    printf("%s -> %d\t0x%x\n", args, result, result);
    return 0;
  }
  else {
    return -1;
  }
}

static int cmd_w(char *args)
{
  if(new_wp(args))
    return 0;
  else return -1;
}

static int cmd_d(char *args)
{
  return free_wp(atoi(args));
}

#ifdef CONFIG_FTRACE
extern void print_func_stack();
static int cmd_print(char *args)
{
  print_func_stack();
  return 0;
}
#endif

static struct {
  const char *name;
  const char *description;
  int (*handler) (char *);
} cmd_table [] = {
  { "help", "Display information about all supported commands", cmd_help },
  { "c", "Continue the execution of the program", cmd_c },
  { "q", "Exit NEMU", cmd_q },
  {"si", "Lets the program pause after executing N instructions in a single step.When N is not given, the default is 1.", cmd_si},
  {"info", "Printing Register Status or watchpoint information", cmd_info},
  {"x", "Outputs N consecutive 4-bytes in hexadecimal form", cmd_x},
  {"p", "Find the value of the expression EXPR", cmd_p},
  {"w", "Suspends program execution when the value of expression EXPR changes.", cmd_w},
  {"d", "Delete the monitoring point with serial number N.", cmd_d},
  #ifdef CONFIG_FTRACE
  {"print", "print the function stack", cmd_print},
  #endif

  /* TODO: Add more commands */

};

#define NR_CMD ARRLEN(cmd_table)

static int cmd_help(char *args) {
  /* extract the first argument */
  char *arg = strtok(NULL, " ");
  int i;

  if (arg == NULL) {
    /* no argument given */
    for (i = 0; i < NR_CMD; i ++) {
      printf("%s - %s\n", cmd_table[i].name, cmd_table[i].description);
    }
  }
  else {
    for (i = 0; i < NR_CMD; i ++) {
      if (strcmp(arg, cmd_table[i].name) == 0) {
        printf("%s - %s\n", cmd_table[i].name, cmd_table[i].description);
        return 0;
      }
    }
    printf("Unknown command '%s'\n", arg);
  }
  return 0;
}

void sdb_set_batch_mode() {
  is_batch_mode = true;
}

void sdb_mainloop() {
  /*
  int count = 0;
  FILE *in = fopen("/home/serein/ysyx/ysyx-workbench/nemu/tools/gen-expr/build/input", "r");
  assert(in);
  char str[65536];

  bool success = true;
  while (fgets(str, sizeof(str), in) != NULL){
    str[strlen(str)-1] = '\0';
    uint32_t sum = (uint32_t)atoi(strtok(str, " "));
    char *expression = strtok(NULL, "");
    uint32_t result = expr(expression, &success);
    if(result != sum)
    {
      printf("%s -> %u ? %u\n", expression, sum, result);
      ++count;
    }
  }

  fclose(in);
  printf("count->%d\n", count);
  */
  if (is_batch_mode) {
    cmd_c(NULL);
    return;
  }

  for (char *str; (str = rl_gets()) != NULL; ) {
    char *str_end = str + strlen(str);

    /* extract the first token as the command */
    char *cmd = strtok(str, " ");
    if (cmd == NULL) { continue; }

    /* treat the remaining string as the arguments,
     * which may need further parsing
     */
    char *args = cmd + strlen(cmd) + 1;
    if (args >= str_end) {
      args = NULL;
    }

#ifdef CONFIG_DEVICE
    extern void sdl_clear_event_queue();
    sdl_clear_event_queue();
#endif

    int i;
    for (i = 0; i < NR_CMD; i ++) {
      if (strcmp(cmd, cmd_table[i].name) == 0) {
        if (cmd_table[i].handler(args) < 0) {
          if(strcmp(cmd, "q") == 0)
            nemu_state.state = NEMU_QUIT;
          return; 
        }
        break;
      }
    }

    if (i == NR_CMD) { printf("Unknown command '%s'\n", cmd); }
  }
}

void init_sdb() {
  /* Compile the regular expressions. */
  init_regex();

  /* Initialize the watchpoint pool. */
  init_wp_pool();
}
