#include <iostream>
#include <stdlib.h>
#include <memory>

#include <verilated.h>
#include "Vdc_toplevel.h"

#include "VGA_PLL.hpp"

void Set_Blanking(Vdc_toplevel * top, PLL VGA_PLL){

    if(VGA_PLL.H_ctr >= H_BLANK){
        top->horizontal_blanking = 1;
    } else {
        top->horizontal_blanking = 0;
    }
    if(VGA_PLL.V_ctr >= V_BLANK){
        top->vertical_blanking = 1;
    } else {
        top->vertical_blanking = 0;
    }
}

void Print_All_Signals(Vdc_toplevel * top){
    std::cout << top->clk << std::endl;
    std::cout << top->nrst << std::endl;
    std::cout << top->en << std::endl;
    std::cout << top->sw_test_en << std::endl;
    std::cout << top->sw_layer_0_pos << std::endl;
    std::cout << top->sw_layer_0_scaling << std::endl;
    std::cout << top->sw_scaling_method << std::endl;
    std::cout << top->user_int_valid << std::endl;
    std::cout << top->vertical_blanking << std::endl;
    std::cout << top->horizontal_blanking << std::endl;
    std::cout << top->ipu_pixel_ready << std::endl;
    std::cout << top->input_color_data << std::endl;
    std::cout << top->const_input_size_width << std::endl;
    std::cout << top->const_input_size_height << std::endl; 
    std::cout << top->const_output_size_width << std::endl;
    std::cout << top->const_output_size_height << std::endl; 
    std::cout << top->const_initial_address << std::endl;
    std::cout << top->const_border_color << std::endl; 
}


int main(int argc, char** argv){
    //my stuff
    PLL VGA_PLL;

    //verilator stuff
    const std::unique_ptr<VerilatedContext> contextp{new VerilatedContext};

    (*contextp).debug(0);
    contextp->randReset(2);
    contextp->traceEverOn(true);
    contextp->commandArgs(argc, argv);

    const std::unique_ptr<Vdc_toplevel> top{new Vdc_toplevel{contextp.get(), "TOP"}};

    //inputs
    top->clk = 0;
    top->nrst = 0;
    top->en = 1; //must be 1
    top->sw_test_en = 0;
    top->sw_layer_0_pos = 0;
    top->sw_layer_0_scaling = 0;
    top->sw_scaling_method = 0;
    top->user_int_valid = 1; //must be 1
    top->vertical_blanking = 0;
    top->horizontal_blanking = 0;
    top->ipu_pixel_ready = 1;
    top->input_color_data = 0;

    //const
    top->const_input_size_width = 128;
    top->const_input_size_height = 128;
    top->const_output_size_width = 640;
    top->const_output_size_height = 480;
    top->const_initial_address = 0;
    top->const_border_color = 0;

    //set cout formatting -- to do
    
    while(!(contextp->gotFinish())){

        //increment timing
        contextp->timeInc(1);
        top->clk = !top->clk;
        VGA_PLL.Increment_Ctr();

        //reset signal
        if(contextp->time() < 15){
            top->nrst = 0;
            VGA_PLL.Reset();
        } else {
            top->nrst = 1;
        }

        //blanking
        Set_Blanking(top.get(), VGA_PLL);

        //drive internal signals
        top->ipu_pixel_ready = top->ipu_pixel_valid;

        //watch signals

        
        // std::cout << "clk " << top->clk << std::endl;
        // printf("clk - %d\n", top->clk);

        top->eval();

        if((top->ipu_pixel_data) && (contextp->time() > 25)){
            break;
        }

        //finish after printing one frame
        if((contextp->time() > 40*1000'000)){
            Print_All_Signals(top.get());
            break;
        }
    }

    top->final();

    return 0;
}
