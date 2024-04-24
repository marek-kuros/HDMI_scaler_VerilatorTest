#include <iostream>
#include <stdlib.h>
#include <memory>

#include <verilated.h>
#include "Vdc_toplevel.h"

#include "VGA_PLL.hpp"


//for printing inputs/outputs
#define SHOW_INPUTS
#define SHOW_OUTPUTS

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
    //inputs
    #ifdef SHOW_INPUTS
    std::cout << "\n\n" << std::endl;
    std::cout << "inputs" << std::endl;
    std::cout << "clk = " << top->clk << std::endl;
    std::cout << "nrst = " << top->nrst << std::endl;
    std::cout << "en = " << top->en << std::endl;
    std::cout << "sw_test_en = " << top->sw_test_en << std::endl;
    std::cout << "sw_layer_0_pos = " << top->sw_layer_0_pos << std::endl;
    std::cout << "sw_layer_0_scaling = " << top->sw_layer_0_scaling << std::endl;
    std::cout << "sw_scaling_method = " << top->sw_scaling_method << std::endl;
    std::cout << "user_int_valid = " << top->user_int_valid << std::endl;
    std::cout << "vertical_blanking = " << top->vertical_blanking << std::endl;
    std::cout << "horizontal_blanking = " << top->horizontal_blanking << std::endl;
    std::cout << "ipu_pixel_ready = " << top->ipu_pixel_ready << std::endl;
    std::cout << "input_color_data = " << top->input_color_data << std::endl;
    std::cout << "const_input_size_width = " << top->const_input_size_width << std::endl;
    std::cout << "const_input_size_height = " << top->const_input_size_height << std::endl; 
    std::cout << "const_output_size_width = " << top->const_output_size_width << std::endl;
    std::cout << "const_output_size_height = " << top->const_output_size_height << std::endl; 
    std::cout << "const_initial_address = " << top->const_initial_address << std::endl;
    std::cout << "const_border_color = " << top->const_border_color << std::endl;
    #endif
    //outputs
    #ifdef SHOW_OUTPUTS
    std::cout << "\n\n" << std::endl;
    std::cout << "outputs" << std::endl;
    std::cout << "ipu_pixel_data = " << top->ipu_pixel_data << std::endl;
    std::cout << "user_int_ready = " << top->user_int_ready << std::endl;
    std::cout << "ipu_pixel_valid = " << top->ipu_pixel_valid << std::endl;
    #endif
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
    top->sw_test_en = 1;
    top->sw_layer_0_pos = 0;
    top->sw_layer_0_scaling = 0;
    top->sw_scaling_method = 0;
    top->user_int_valid = 1; //must be 1
    top->vertical_blanking = 0;
    top->horizontal_blanking = 0;
    top->ipu_pixel_ready = 1;
    top->input_color_data = 7'000'000;

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
        top->ipu_pixel_ready = !top->ipu_pixel_ready;

        //watch signals
        if(top->ipu_pixel_valid){
            printf("ipu_pixel_valid = %d\n", top->ipu_pixel_valid);
        }
        
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
