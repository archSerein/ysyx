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
int64_t inst_cnt = 0;
int64_t cycle_cnt = 0;
int64_t ifu_inst_cnt = 0;
int64_t lsu_load_cnt = 0;
int64_t exu_alu_cnt = 0;
int64_t cal_inst_cnt = 0;
int64_t mem_inst_cnt = 0;
int64_t csr_inst_cnt = 0;
int64_t br_inst_cnt = 0;
int64_t jump_inst_cnt = 0;
int64_t default_inst_cnt = 0;
int64_t mem_cycle_cnt = 0;

extern "C" void ending(int num) { e = num; }
extern "C" void putch(int ch) { putchar(ch); }
static void update_register_array();

#ifdef CONFIG_TRACE_WAVE
bool is_open_trace_wave = false;
void open_trace_wave(uint32_t pc) {
    if (!is_open_trace_wave) {
        is_open_trace_wave = true;
        Log("open trace wave");
    }
}
void close_trace_wave(uint32_t pc) {
    // if (is_open_trace_wave && ()) {
    //     is_open_trace_wave = false;
    //     Log("close trace wave");
    // }
}
#endif // CONFIG_TRACE_WAVE
    
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
    #ifdef CONFIG_TRACE_WAVE
        open_trace_wave(get_pc_reg());
        close_trace_wave(get_pc_reg());
    #endif // CONFIG_TRACE_WAVE
    top.clock = 0; // 切换时钟状态
    top.eval();
    #ifdef CONFIG_TRACE_WAVE
        if (is_open_trace_wave) {
            contextp->timeInc(1);
            tfp->dump(contextp->time());
        }
    #endif // CONFIG_TRACE_WAVE
    top.clock = 1; // 切换
    top.eval();
    #ifdef CONFIG_TRACE_WAVE
        if (is_open_trace_wave) {
            contextp->timeInc(1);
            tfp->dump(contextp->time());
        }
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
    #ifdef CONFIG_TRACE_PERFORMANCE
        char path[] = "/home/serein/ysyx/ysyx-workbench/npc/performance.txt";
        FILE *fp = fopen(path, "w");
        if (fp == NULL) {
            Log("open file performance.txt failed");
            return;
        }
        fprintf(fp, "Cycle: %ld Instructions: %ld, IPC: %.04f", cycle_cnt, inst_cnt, (double)inst_cnt / cycle_cnt);
        fprintf(fp, "IFU Instructions: %ld, LSU Load/Store Instructions: %ld, EXU ALU Instructions: %ld", ifu_inst_cnt, lsu_load_cnt, exu_alu_cnt);
        fprintf(fp, "CAL Instructions: %ld, MEM Instructions: %ld, CSR Instructions: %ld, BR Instructions: %ld, JUMP Instructions: %ld, DEFAULT Instructions: %ld", cal_inst_cnt, mem_inst_cnt, csr_inst_cnt, br_inst_cnt, jump_inst_cnt, default_inst_cnt);
        float total_inst = (double)inst_cnt;
        fprintf(fp, "CAL Instructions Ratio: %.04f", cal_inst_cnt / total_inst);
        fprintf(fp, "MEM Instructions Ratio: %.04f", mem_inst_cnt / total_inst);
        fprintf(fp, "CSR Instructions Ratio: %.04f", csr_inst_cnt / total_inst);
        fprintf(fp, "BR Instructions Ratio: %.04f", br_inst_cnt / total_inst);
        fprintf(fp, "JUMP Instructions Ratio: %.04f", jump_inst_cnt / total_inst);
        fprintf(fp, "DEFAULT Instructions Ratio: %.04f", default_inst_cnt / total_inst);
        fprintf(fp, "Memory Access Cycle: %ld, average memory access cycle: %.04f", mem_cycle_cnt, (double)mem_cycle_cnt / lsu_load_cnt);
        fprintf(fp, "综合面积: 34860.098000um^2, 频率: 500MHz");
        fclose(fp);
    #endif // CONFIG_TRACE_PERFORMANCE
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
  #ifdef CONFIG_YSYXSOC
    return top.rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__core_module__DOT__ifu_module__DOT__ifu_pc;
  #else
    return 0;
  #endif
}

uint32_t get_inst_reg() {
  #ifdef CONFIG_YSYXSOC
    return top.rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__core_module__DOT__bdu_module__DOT__bdu_inst_r;
  #else
    return 0;
  #endif
}

uint32_t get_reg_val(int index) {
  #ifdef CONFIG_YSYXSOC
    return top.rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__core_module__DOT__rf_module__DOT__regfile[index];
  #else
    return 0;
  #endif
}

uint32_t get_csr_val(int addr) {
  #ifdef CONFIG_YSYXSOC
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
  #else
    return 0;
  #endif
}

void nvboard_bind_all_pins(TOP_NAME *top);
void nvboard_init_warp() {
    nvboard_bind_all_pins(&top);
    nvboard_init();
}

#ifdef CONFIG_TRACE_PERFORMANCE
extern "C" void inst_count(void) {
    ++inst_cnt;
}

extern "C" void ifu_inst_count() {
    ++ifu_inst_cnt;
}

extern "C" void inst_type_count(uint8_t type) {
    switch (type) {
        case 0:
            ++cal_inst_cnt;
            break;
        case 1:
            ++mem_inst_cnt;
            break;
        case 2:
            ++csr_inst_cnt;
            break;
        case 3:
            ++br_inst_cnt;
            break;
        case 4:
            ++jump_inst_cnt;
            break;
        default:
            ++default_inst_cnt;
            break;
    }
}

extern "C" void lsu_load_store_count(void) {
    ++lsu_load_cnt;
}

extern "C" void exu_alu_count(void) {
    ++exu_alu_cnt;
}

extern "C" void mem_cycle_count(void) {
    ++mem_cycle_cnt;
}
void cycle_count(void) {
    ++cycle_cnt;
}
#endif // CONFIG_TRACE_PERFORMANCE
