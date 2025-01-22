#include "VysyxSoCFull.h"
#include "VysyxSoCFull___024root.h"
#include "verilated.h"
#include "verilated_vcd_c.h"
#include "state.hpp"
#include "defs.hpp"
#include "reg.hpp"
#include "debug.hpp"
#include <cstdio>
#include <nvboard.h>

static TOP_NAME top;
#ifdef CONFIG_TRACE_WAVE
    VerilatedContext* contextp = NULL;
    VerilatedVcdC* tfp = NULL;
#endif // CONFIG_TRACE_WAVE

uint32_t register_file[37];
int e = 0;

extern "C" void ending(int num) { e = num; }
extern "C" void putch(int ch) { putchar(ch); }
static void update_register_array();

void
single_cycle(inst_i *cur_inst) {
    if (e)
    {
        if (get_reg_val(10) == 0)
        {
            npc_state.halt_ret = 0;
            npc_state.state = END;
        }
            
        else
        {
            npc_state.halt_ret = 1;
            npc_state.state = ABORT;
        }
    }

    if (cur_inst != NULL)
    {
        cur_inst->pc = get_pc_reg();
        cur_inst->inst = get_inst_reg();
    }
    top.clock = 0; // 切换时钟状态
    top.eval();
    #ifdef CONFIG_TRACE_WAVE
        contextp->timeInc(1);
        tfp->dump(contextp->time());
    #endif // CONFIG_TRACE_WAVE
    top.clock = 1; // 切换
    top.eval();
    #ifdef CONFIG_TRACE_WAVE
        contextp->timeInc(1);
        tfp->dump(contextp->time());
    #endif // CONFIG_TRACE_WAVE
    update_register_array();
}

void
reset(int n) {
    top.reset = 1;
    while (n-- > 0)
    {
        single_cycle(0);
    }
    top.reset = 0;
}

void
sim_exit(){
    single_cycle(0);
    #ifdef CONFIG_TRACE_WAVE
        tfp->close();
    #endif // CONFIG_TRACE_WAVE
}

#ifdef CONFIG_TRACE_WAVE
void 
sim_init()
{
    Verilated::traceEverOn(true);
    contextp = new VerilatedContext;
    tfp = new VerilatedVcdC;
    contextp->traceEverOn(true);
    top.trace(tfp, 0);
    tfp->open("VysyxSoCFull.vcd");
}
#endif // CONFIG_TRACE_WAVE

void
isa_reg_display()
{
    for(int i = 0; i < 37; i++)
    {
        printf("%s: %08x\n", regs[i], 
            register_file[i]);
    }
}

static void
update_register_array()
{
    for(int i = 0; i < 32; i++)
    {
        register_file[i] = get_reg_val(i);
    }

    register_file[32] = get_pc_reg();
    register_file[33] = get_csr_val(0x341);
    register_file[34] = get_csr_val(0x300);
    register_file[35] = get_csr_val(0x305);
    register_file[36] = get_csr_val(0x342);
}

uint32_t
isa_reg_str2val(const char *s) {
  const char *reg_name = s + 1;
  for(int i = 0; i < 32; i++)
  {
    if(strcmp(reg_name, regs[i]) == 0)
    {
      return get_reg_val(i);
    }
  }

  if(strcmp(reg_name, "pc") == 0)
  {
    return get_pc_reg();
  }
  return 0;
}

#ifdef CONFIG_DIFFTEST
bool    is_difftest_time = false;
extern "C" void is_difftest(char difftest){
    is_difftest_time = difftest == 1;
}
bool is_difftest_cycle() {
    return is_difftest_time;
}
#endif

uint32_t get_pc_reg() {
    return top.rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__core_module__DOT__ifu_module__DOT__ifu_pc;
}

uint32_t get_inst_reg() {
    return top.rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__core_module__DOT__bdu_module__DOT__bdu_inst_r;
}

uint32_t get_reg_val(int index) {
    return top.rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__core_module__DOT__rf_module__DOT__regfile[index];
}

uint32_t get_csr_val(int addr) {
    switch (addr) {
        case 0x300:
            return top.rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__core_module__DOT__csr_module__DOT__MSTATUS;
        case 0x342:
            return top.rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__core_module__DOT__csr_module__DOT__MCAUSE;
        case 0x305:
            return top.rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__core_module__DOT__csr_module__DOT__MTVEC;
        case 0x341:
            return top.rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__core_module__DOT__csr_module__DOT__MEPC;
        default:
            panic("get_csr_val fault addr: %x", addr);
    }
}

void nvboard_bind_all_pins(TOP_NAME *top);
void nvboard_init_warp() {
    nvboard_bind_all_pins(&top);
    nvboard_init();
}