#include "VGA_PLL.hpp"

PLL::PLL(){
    this->H_ctr = 0;
    this->V_ctr = 0;
}

void PLL::Increment_Ctr(){
    if((this->H_ctr >= H_max_counter) && (this->V_ctr >= V_max_counter)){
        this->H_ctr = 0;
        this->V_ctr = 0;
    } else if(this->H_ctr >= H_max_counter){
        this->H_ctr = 0;
        this->V_ctr++;
    } else {
        this->H_ctr++;
    }
}
