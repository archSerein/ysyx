#ifndef __DEBUG_HPP_
#define __DEBUG_HPP_

#include <cassert>
#define panic(fmt, ...) \
    do { \
        fprintf(stderr, "\033[1;31m[panic]\033[0m \033[1;34m[%s:%d]\033[0m " fmt "\n", __FILE__, __LINE__, ## __VA_ARGS__); \
        assert(0); \
    } while (0)

#define Log(fmt, ...) \
    do { \
        fprintf(stdout, "\033[1;34m[log-tracer]\033[0m \033[1;34m[%s:%d]\033[0m " fmt "\n", __FILE__, __LINE__, ## __VA_ARGS__); \
    } while (0)

#endif // __DEBUG_HPP_