#include <iostream>
#include <stdlib.h>
#include <memory>

#include <verilated.h>
#include "VDE10_LITE_SDRAM_Nios_Test.h"

#include "VGA_PLL.hpp"


//for printing inputs/outputs
#define SHOW_INPUTS
#define SHOW_OUTPUTS

#define FRAMES_NO 2

// void Set_Blanking(VDE10_LITE_SDRAM_Nios_Test * top, PLL VGA_PLL){

//     if(VGA_PLL.H_ctr >= H_BLANK){
//         top->horizontal_blanking = 1;
//     } else {
//         top->horizontal_blanking = 0;
//     }
//     if(VGA_PLL.V_ctr >= V_BLANK){
//         top->vertical_blanking = 1;
//     } else {
//         top->vertical_blanking = 0;
//     }
// }

void Print_All_Signals(VDE10_LITE_SDRAM_Nios_Test * top){
    //inputs
    #ifdef SHOW_INPUTS
    std::cout << "\n" << std::endl;
    std::cout << "inputs" << std::endl;
    // std::cout << "clk = " << top->MAX10_CLK2_50 << std::endl; //sometimes cout doesn't print value
    printf("clk = %d\n", top->MAX10_CLK2_50);
    std::cout << "nrst = " << (top->SW & 0x1) << std::endl;
    std::cout << "SW = " << top->SW << std::endl;
    std::cout << "\n";
    std::cout << "sw_test_en = " << ((top->SW & 0x2) >> 1) << std::endl;
    std::cout << "sw_layer_0_pos = " << ((top->SW & 0x1C) >> 2) << std::endl;
    std::cout << "sw_layer_0_scaling = " << ((top->SW & 0xE0) >> 5) << std::endl;
    std::cout << "sw_scaling_method = " << ((top->SW & 0x300) >> 8) << std::endl;
    #endif

    //outputs
    #ifdef SHOW_OUTPUTS
    std::cout << "\n" << std::endl;
    std::cout << "outputs" << std::endl;
    // std::cout << "R = " << top->VGA_R << std::endl;
    // std::cout << "G = " << top->VGA_G << std::endl;
    // std::cout << "B = " << top->VGA_B << std::endl;
    // std::cout << "HS = " << top->VGA_HS << std::endl;
    // std::cout << "VS = " << top->VGA_VS << std::endl;

    printf("R = %d\nG = %d\nB = %d\nHS = %d\nVS = %d\n", 
            top->VGA_R, top->VGA_G, top->VGA_B, top->VGA_HS, top->VGA_VS);
    #endif
}


int main(int argc, char** argv){
    //my stuff
    // PLL VGA_PLL;

    //verilator stuff
    const std::unique_ptr<VerilatedContext> contextp{new VerilatedContext};

    contextp->debug(0);
    contextp->randReset(2);
    contextp->traceEverOn(true);
    contextp->commandArgs(argc, argv);

    const std::unique_ptr<VDE10_LITE_SDRAM_Nios_Test> top{new VDE10_LITE_SDRAM_Nios_Test{contextp.get(), "TOP"}};

    //inputs
    top->MAX10_CLK2_50 = 0;
    top->SW = 0x2 | 0x4 | 0x20 | 0x100;

    // outputs
    top->VGA_R = 12;
    top->VGA_G = 1;
    top->VGA_B = 4;
    top->VGA_HS = 0;
    top->VGA_VS = 0;
    
    //const
    
    while(!(contextp->gotFinish())){

        //increment timing
        contextp->timeInc(1);
        top->MAX10_CLK2_50 = !top->MAX10_CLK2_50 & 0x1;

        //reset signal
        if(contextp->time() < 15){
            top->SW = top->SW & (~0x1);
        } else {
            top->SW = top->SW | (0x1);
        }

        //watch signals
        Print_All_Signals(top.get());

        // std::cout << "clk " << top->clk << std::endl;
        // printf("clk - %d\n", top->clk);

        top->eval();

        //finish after printing 2 frame(s)
        if((contextp->time() > FRAMES_NO*20*1'000'000 + 15)){
            Print_All_Signals(top.get());
            break;
        }
    }

    top->final();

    return 0;
}
