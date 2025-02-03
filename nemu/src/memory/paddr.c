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

#include <memory/host.h>
#include <memory/paddr.h>
#include <device/mmio.h>
#include <isa.h>

#if   defined(CONFIG_PMEM_MALLOC)
  static uint8_t *pmem = NULL;
  #ifdef CONFIG_YSYXSOC
    uint8_t *sram = NULL;
    uint8_t *psram = NULL;
    static uint32_t sram_size = 0x2000;
    static uint32_t psram_size = 0x1000000;
    static uint32_t memsize = CONFIG_MSIZE;
  #else
    static uint32_t memsize = CONFIG_MSIZE;
  #endif
#else // CONFIG_PMEM_GARRAY
static uint8_t pmem[CONFIG_MSIZE] PG_ALIGN = {};
#endif



#ifdef CONFIG_YSYXSOC
  uint8_t* guest_to_host(paddr_t paddr) {
    if (paddr >= PMEM_LEFT && paddr <= PMEM_RIGHT) return pmem + paddr - PMEM_LEFT;
    if (paddr >= 0x80000000 && paddr <= 0x80ffffff) return psram + paddr - 0x80000000;
    if (paddr >= 0x0f000000 && paddr <= 0x0f001fff) return sram + paddr - 0x0f000000;
    return NULL;
  }
  paddr_t host_to_guest(uint8_t *haddr) {
    if (haddr >= pmem && haddr < pmem + memsize) return haddr - pmem + PMEM_LEFT;
    if (haddr >= sram && haddr < sram + sram_size) return haddr - sram + 0x0f000000;
    if (haddr >= psram && haddr < psram + psram_size) return haddr - psram + 0x80000000;
    return 0;
  }
#else
  uint8_t* guest_to_host(paddr_t paddr) { return pmem + paddr - CONFIG_MBASE; }
  paddr_t host_to_guest(uint8_t *haddr) { return haddr - pmem + CONFIG_MBASE; }
#endif

static word_t pmem_read(paddr_t addr, int len) {
  word_t ret = host_read(guest_to_host(addr), len);
  #ifdef CONFIG_MTRACE
    printf("read %d bytes at address %08x data: %08x\n", len, addr, ret);
  #endif
  return ret;
}

static void pmem_write(paddr_t addr, int len, word_t data) {
  host_write(guest_to_host(addr), len, data);
}

static void out_of_bound(paddr_t addr) {
  panic("address = " FMT_PADDR " is out of bound of pmem [" FMT_PADDR ", " FMT_PADDR "] at pc = " FMT_WORD,
      addr, PMEM_LEFT, PMEM_RIGHT, cpu.pc);
}

void init_mem() {
#if   defined(CONFIG_PMEM_MALLOC)
  pmem = malloc(memsize);
  assert(pmem);
#endif
#ifdef CONFIG_YSYXSOC
  sram = malloc(sram_size);
  psram = malloc(psram_size);
  assert(sram);
  assert(psram);
  // IFDEF(CONFIG_MEM_RANDOM, memset(sram, rand(), sram_size));
#endif
  IFDEF(CONFIG_MEM_RANDOM, memset(pmem, rand(), memsize));
  Log("physical memory area [" FMT_PADDR ", " FMT_PADDR "]", PMEM_LEFT, PMEM_RIGHT);
}

word_t paddr_read(paddr_t addr, int len) {
  if (likely(in_pmem(addr))) return pmem_read(addr, len);
  IFDEF(CONFIG_DEVICE, return mmio_read(addr, len));
  out_of_bound(addr);
  return 0;
}

void paddr_write(paddr_t addr, int len, word_t data) {
  #ifdef CONFIG_MTRACE
    printf("write %d bytes at address %08x data: %08x\n", len, addr, data);
  #endif
  if (likely(in_pmem(addr))) { pmem_write(addr, len, data); return; }
  IFDEF(CONFIG_DEVICE, mmio_write(addr, len, data); return);
  out_of_bound(addr);
}
