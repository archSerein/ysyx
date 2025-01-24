#ifndef __PMEM_HPP__
#define __PMEM_HPP__

#define CONFIG_MEM_SIZE (128 * 1024 * 1024 / sizeof(uint32_t))  // 128MB，假设每个uint32_t占4字节
#define CONFIG_MBASE         0x80000000
#define CONFIG_MROM_SIZE     0x1000
#define CONFIG_MROM_BASE     0x20000000
#define CONFIG_SRAM_SIZE     0x2000
#define CONFIG_SRAM_BASE     0x0f000000
#define CONFIG_FLASH_BASE    0x30000000
#define CONFIG_FLASH_SIZE    0x04000000
#define CONFIG_PSRAM_BASE    0x80000000
#define CONFIG_PSRAM_SIZE    0x1fffffff

long init_mem(char *);
void free();
void flash_test();
extern "C" int pmem_read(int);
uint32_t vaddr_read(uint32_t, int);

uint8_t *guest_to_host(uint32_t paddr);
uint8_t *mrom_to_host(uint32_t paddr);
uint8_t *sram_to_host(uint32_t paddr);
uint8_t *flash_to_host(uint32_t paddr);
uint8_t *psram_to_host(uint32_t paddr);
extern "C" void flash_read(int32_t addr, int32_t *data);
extern "C" void mrom_read(int32_t addr, int32_t *data);
extern "C" void psram_read(int32_t addr, int32_t *data);
extern "C" void psram_write(int32_t addr, int8_t data);
#endif // __PMEM_HPP__
