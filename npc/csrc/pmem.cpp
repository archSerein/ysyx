#include <cstdint>
#include "pmem.hpp"
#include <iostream>
#include <cassert>
#include <cstring>
#include <chrono>
#include "defs.hpp"
#include "debug.hpp"

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
pmem_read(int raddr, int len)
{
    if (raddr == 0xa0000048)
        return  (int)(std::chrono::duration_cast<std::chrono::milliseconds>(
                        std::chrono::system_clock::now().time_since_epoch()).count());
    if (raddr == 0xa000004c)
        return (int)(std::chrono::duration_cast<std::chrono::microseconds>(
                        std::chrono::system_clock::now().time_since_epoch()).count() >> 32) ;
    uint8_t *paddr = guest_to_host((uint32_t)raddr);

    switch (len)
    {
        case 4:
            // mtrace
            #ifdef CONFIG_MTRACE
                printf("read %d bytes at addr = %08x, value = %08x\n",
                        len, raddr, *(uint32_t *)paddr);
            #endif // CONFIG_MTRACE
            return *(uint32_t *)paddr;
        case 2:
            // mtrace
            #ifdef CONFIG_MTRACE
                printf("read %d bytes at addr = %08x, value = %08x\n",
                        len, raddr, *(uint32_t *)paddr);
            #endif // CONFIG_MTRACE
            return *(uint16_t *)paddr;
        case 1:
            // mtrace
            #ifdef CONFIG_MTRACE
                printf("read %d bytes at addr = %08x, value = %08x\n",
                        len, raddr, *(uint32_t *)paddr);
            #endif // CONFIG_MTRACE
            return *(uint8_t *)paddr;
        default:
            printf("pmem_read fault at raddr %08x\n", raddr);
            return -1;
    }

}

extern "C" void
pmem_write(int vaddr, int len, int data)
{
    if (vaddr == 0xa00003f8) {
        printf("%c", data & 0xff);
        return;
    }
    uint8_t *paddr = guest_to_host((uint32_t)vaddr);
    switch(len)
    {
        case 4:
            *(uint32_t *)paddr = data; break;
        case 2:
            *(uint16_t *)paddr = data; break;
        case 1:
            *(uint8_t *)paddr = data; break;
        default:
            printf("paddr_write fault\n");
    }

    // mtrace
    #ifdef CONFIG_MTRACE
        printf("write %d bytes at addr = %08x, value = %08x\n",
                len, vaddr, data);
    #endif // CONFIG_MTRACE
}

extern "C" int
inst_read(int vaddr)
{
    uint8_t *paddr = guest_to_host((uint32_t)vaddr);

    return *(uint32_t *)paddr;
}

uint32_t
vaddr_read(uint32_t addr, int len)
{
    int vaddr = (int)addr;
    int ret;
    switch(len)
    {
        case 1:
            ret = pmem_read(vaddr, 1);
        case 2:
            ret = pmem_read(vaddr, 2);
        case 4:
            ret = pmem_read(vaddr, 4);
        default:
            assert(0);
    }

    return (uint32_t)ret;
}

void
free()
{
    free(mem);
}
