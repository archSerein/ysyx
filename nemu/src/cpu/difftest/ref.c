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
#include <difftest-def.h>
#include <memory/paddr.h>

__EXPORT void difftest_memcpy(paddr_t addr, void *buf, size_t n, bool direction) {
  // assert(0);
  if (direction == DIFFTEST_TO_REF) {
    int i;
    word_t *p = (word_t *)buf;
    for (i = 0; i < n; i += 4)
    {
      paddr_write(addr + i, 4, *(p + i / 4));
    }
    for (i -= 4; i < n; i++)
    {
      paddr_write(addr + i, 1, *((uint8_t *)p + i));
    }
  } else {
    word_t data = paddr_read(addr, n);
    memcpy(buf, &data, n);
  }
}

__EXPORT void difftest_regcpy(void *dut, bool direction) {
  // assert(0);
  if (direction == DIFFTEST_TO_DUT) {
    memcpy(dut, cpu.gpr, sizeof(cpu.gpr));
    memcpy(dut + sizeof(cpu.gpr), &cpu.pc, sizeof(cpu.pc));
    memcpy(dut + sizeof(cpu.gpr) + sizeof(cpu.pc), cpu.csr, sizeof(cpu.csr));
  } else {
    memcpy(cpu.gpr, dut, sizeof(cpu.gpr));
    memcpy(&cpu.pc, dut + sizeof(cpu.gpr), sizeof(cpu.pc));
    memcpy(cpu.csr, dut+sizeof(cpu.gpr)+sizeof(cpu.pc), sizeof(cpu.csr));
  }
}

__EXPORT void difftest_exec(uint64_t n) {
  // assert(0);
  cpu_exec(n);
}

__EXPORT void difftest_raise_intr(word_t NO) {
  assert(0);
}

__EXPORT void difftest_init(int port) {
  void init_mem();
  init_mem();
  /* Perform ISA dependent initialization. */
  init_isa();
}
