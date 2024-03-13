// #include <nvboard.h>
#include <Vtop.h>
#include <iostream>

static TOP_NAME top;
int e = 0;
// void nvboard_bind_all_pins(Vtop* top);

void single_cycle() {
    top.clk = 0;
    top.eval();
    top.clk = 1;
    top.eval();
}

void reset(int n) {
    top.rst = 1;
    while (n-- > 0)
        single_cycle();
    top.rst = 0;
}

extern "C" void ending(int num) { e = num; }

int main() {
    // nvboard_bind_all_pins(&top);
    // nvboard_init();

    reset(10);

    while (1) {
        // nvboard_update();
        if (e)
            break;
        single_cycle();
        printf("%d\n", top.out);
    }
    return 0;
}
