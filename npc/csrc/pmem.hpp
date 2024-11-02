#ifndef __PMEM_HPP__
#define __PMEM_HPP__

#define CONFIG_MEM_SIZE (128 * 1024 * 1024 / sizeof(uint32_t))  // 128MB，假设每个uint32_t占4字节
#define CONFIG_MBASE         0x80000000

long init_mem(char *);
void free();
extern "C" int pmem_read(int);
uint32_t vaddr_read(uint32_t, int);

uint8_t *guest_to_host(uint32_t paddr);
extern "C" void flash_read(int32_t addr, int32_t *data) { assert(0); }
extern "C" void mrom_read(int32_t addr, int32_t *data) { assert(0); }
#endif // __PMEM_HPP__
