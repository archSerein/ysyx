#include <stdio.h>
#include <fixedptc.h>

int main() {
    uint32_t a = fixedpt_rconst(3.25);
    uint32_t b = fixedpt_rconst(1.75);

    uint32_t result_add = fixedpt_add(a, b);
    printf("Addition: (fixedpt: %d)\n", result_add);

    // 减法测试
    int32_t result_sub = fixedpt_sub(a, b);
    printf("Subtraction: (fixedpt: %d)\n", result_sub);

    // 乘法测试
    int32_t result_mul = fixedpt_mul(a, b);
    printf("Multiplication: (fixedpt: %d)\n", result_mul);

    // 除法测试
    if (b != 0) {
        int32_t result_div = fixedpt_div(a, b);
        printf("Division: (fixedpt: %d)\n", result_div);
    }

    // 向下取整测试
    int32_t result_floor = fixedpt_floor(a);
    printf("Floor: (fixedpt: %d)\n", result_floor);

    // 向上取整测试
    int32_t result_ceil = fixedpt_ceil(a);
    printf("Ceil: (fixedpt: %d)\n", result_ceil);

    return 0;
 }
