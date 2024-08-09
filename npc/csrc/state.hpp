#ifndef __STATE_HPP_
#define __STATE_HPP_

enum { RUNNING, STOP, END, ABORT, QUIT };

typedef struct {
  int state;
  uint32_t halt_pc;
  uint32_t halt_ret;
} NPCState;

extern NPCState npc_state;

#endif // __STATE_HPP_