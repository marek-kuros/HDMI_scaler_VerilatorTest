#pragma once

#include <stdint.h>

#define V_max_counter 524
#define H_max_counter 799

#define H_BLANK 639
#define V_BLANK 479

class PLL{
    public:
        uint16_t H_ctr;
        uint16_t V_ctr;

        PLL();
        void Increment_Ctr();
        void Reset();
};
