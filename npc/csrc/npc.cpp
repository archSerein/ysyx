#include "Vtop.h"
#include "Vtop___024root.h"
#include "verilated.h"
#include "verilated_vcd_c.h"
#include "state.hpp"
#include "defs.hpp"
#include "reg.hpp"
#include "debug.hpp"

static TOP_NAME top;
VerilatedContext* contextp = NULL;
VerilatedVcdC* tfp = NULL;

uint32_t register_file[37];
int e = 0;

extern "C" void ending(int num) { e = num; }
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
        cur_inst->pc = top.rootp->top__DOT__ifu_module__DOT__ifu_pc;
        cur_inst->inst = top.rootp->top__DOT__ifu_module__DOT__sram_module__DOT__sram_inst;
    }        
    top.clk_i = 0; // 切换时钟状态
    top.eval();
    // contextp->timeInc(1);
    // tfp->dump(contextp->time());
    top.clk_i = 1; // 切换
    top.eval();
    // contextp->timeInc(1);
    // tfp->dump(contextp->time());
    update_register_array();
}

void
reset(int n) {
    top.rst_i = 1;
    while (n-- > 0)
    {
        single_cycle(0);
    }
    top.rst_i = 0;
}

void
sim_exit(){
  single_cycle(0);
  // tfp->close();
}

void 
sim_init()
{
    Verilated::traceEverOn(true);
    contextp = new VerilatedContext;
    tfp = new VerilatedVcdC;
    contextp->traceEverOn(true);
    top.trace(tfp, 0);
    tfp->open("Vtop.vcd");
}

void
isa_reg_display()
{
    for(int i = 0; i < 37; i++)
    {
        printf("%s: %08x\n", regs[i], 
            register_file[i]);
    }
}

uint32_t
get_reg_val(int idx)
{
    return top.rootp->top__DOT__rf_module__DOT__regfile[idx];
}

static void
update_register_array()
{
    for(int i = 0; i < 32; i++)
    {
        register_file[i] = get_reg_val(i);
    }

    register_file[32] = top.rootp->top__DOT__ifu_module__DOT__ifu_pc;
    register_file[33] = top.rootp->top__DOT__csr_module__DOT__MSTATUS;
    register_file[34] = top.rootp->top__DOT__csr_module__DOT__MEPC;
    register_file[35] = top.rootp->top__DOT__csr_module__DOT__MCAUSE;
    register_file[36] = top.rootp->top__DOT__csr_module__DOT__MTVEC;
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
    return top.rootp->top__DOT__ifu_module__DOT__ifu_pc;
  }
  return 0;
}

bool is_difftest(){
    if (top.difftest_o == 1) {
        return true;
    } else {
        return false;
    }
}
