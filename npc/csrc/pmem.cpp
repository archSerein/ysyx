#include <cstdint>
#include "pmem.hpp"
#include <iostream>
#include <cassert>
#include <cstring>
#include <chrono>
#include "defs.hpp"
#include "debug.hpp"
#include "difftest.hpp"

uint8_t *mem;

uint8_t* guest_to_host(uint32_t paddr) { return mem + paddr - CONFIG_MBASE; }

long
init_mem(char *path)
{
    mem = (uint8_t *)aligned_alloc(32, CONFIG_MEM_SIZE * sizeof(uint32_t));
    if(path == NULL)
    {
        printf("No image is given, exit now\n");
        exit(0);
    }

    FILE *fp = fopen(path, "rb");
    if(!fp)
    {
        printf("open image fail, exit now\n");
        exit(1);
    }

    fseek(fp, 0, SEEK_END);
    long size = ftell(fp);

    fseek(fp, 0, SEEK_SET);
    int ret = fread(mem, size, 1, fp);
    assert(ret == 1);

    fclose(fp);

    printf("mem initalization complete\n");
    return size;
}

extern "C" int
pmem_read(int raddr)
{
    if (raddr == 0xa0000048)
        return  (int)(std::chrono::duration_cast<std::chrono::milliseconds>(
                        std::chrono::system_clock::now().time_since_epoch()).count());
    if (raddr == 0xa000004c)
        return (int)(std::chrono::duration_cast<std::chrono::microseconds>(
                        std::chrono::system_clock::now().time_since_epoch()).count() >> 32) ;
    uint32_t vaddr = (uint32_t)(raddr & ~0x3u);
    uint8_t *paddr = guest_to_host(vaddr);

    uint32_t data = *(uint32_t *)paddr;
    #ifdef CONFIG_MTRACE
        printf("pmem_read-> addr: %08x data: %08x\n", raddr, data);
    #endif // CONFIG_MTRACE
    return data;
}

extern "C" void
pmem_write(int waddr, int wdata, char wmask)
{
    if (waddr == 0xa00003f8) {
        difftest_skip_ref();
        printf("%c", wdata & 0xff);
        return;
    }
    uint32_t vaddr = (uint32_t)(waddr & ~0x3u);
    uint8_t *paddr = guest_to_host(vaddr);
    uint32_t rdata = *(uint32_t *)paddr;
    switch(wmask)
    {
        case 0x0f:
            *(uint32_t *)paddr = wdata;
            break;
        case 0x0c:
            *(uint32_t *)paddr = (wdata & 0xffff0000) | (rdata & 0x0000ffff);
            break;
        case 0x08:
            *(uint32_t *)paddr = (wdata & 0xff000000) | (rdata & 0x00ffffff);
            break;
        case 0x04:
            *(uint32_t *)paddr = (wdata & 0x00ff0000) | (rdata & 0xff00ffff);
            break;
        case 0x03:
            *(uint32_t *)paddr = (wdata & 0x0000ffff) | (rdata & 0xffff0000);
            break;
        case 0x02:
            *(uint32_t *)paddr = (wdata & 0x0000ff00) | (rdata & 0xffff00ff); 
            break;
        case 0x01:
            *(uint32_t *)paddr = (wdata & 0x000000ff) | (rdata & 0xffffff00);
            break;
        default:
            printf("paddr_write fault waddr: %x\n", vaddr);
    }

    uint32_t update_data = *(uint32_t *)paddr;
    // mtrace
    #ifdef CONFIG_MTRACE
        printf("pmem_write-> addr: %08x origin_data: %08x wdata: %08x update_data: %08x wmask: %08x\n",\
                                vaddr, rdata, wdata, update_data, wmask);
    #endif // CONFIG_MTRACE
}

extern "C" int
inst_read(int vaddr)
{
    uint8_t *paddr = guest_to_host((uint32_t)vaddr);

    #ifdef CONFIG_MTRACE
        printf("inst_read: %08x %08x\n", vaddr, *(uint32_t *)paddr);
    #endif // CONFIG_MTRACE
    return *(uint32_t *)paddr;
}

uint32_t
vaddr_read(uint32_t addr, int len)
{
    uint8_t *paddr = guest_to_host((uint32_t)addr);
    switch(len)
    {
        case 1:
            return (uint32_t)*(uint8_t *)paddr;
        case 2:
            return (uint32_t)*(uint16_t *)paddr;
        case 4:
            return (uint32_t)*(uint32_t *)paddr;
        default:
            assert(0);
    }
}

void
free()
{
    free(mem);
}
