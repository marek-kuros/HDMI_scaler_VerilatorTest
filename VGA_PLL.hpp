#pragma once

#include <stdint.h>

#define V_max_counter 524
#define H_max_counter 799 

class PLL{
    public:
        uint16_t H_ctr;
        uint16_t V_ctr;

        PLL();
        void Increment_Ctr();
};
