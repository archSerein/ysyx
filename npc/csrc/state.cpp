#include <cstdint>
#include "defs.hpp"
#include "state.hpp"
#include <iostream>

extern NPCState npc_state;

int
is_exit_state(int state)
{
    if (state == 0 && npc_state.halt_ret == 0 &&
        npc_state.state != ABORT ) {
        // ANSI 转义序列开始
        std::cout << "\033[32m";  // 设置颜色为绿色
        std::cout << "HIT GOOD TRAP!" << std::endl;
        // 重置终端颜色
        std::cout << "\033[0m";   // 重置颜色为默认
        return 0;
    }
    else {
        // ANSI 转义序列开始
        std::cout << "\033[31m";  // 设置颜色为红色
        std::cout << "HIT BAD TRAP!" << std::endl;
        // 重置终端颜色
        std::cout << "\033[0m";   // 重置颜色为默认
        return -1;
    }
}
