#include <am.h>

Area heap;

void putch(char ch) {
    outb(SERIAL_PORT, ch);
}

void halt(int code) {
    asm volatile("mv a0, %0" : : "r"(code));
    asm volatile("ebreak");
    while (1);
}
