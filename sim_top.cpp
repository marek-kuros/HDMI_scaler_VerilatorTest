#include <iostream>
#include <stdlib.h>
#include <memory>

#include <verilated.h>
#include <verilated_vcd_c.h>
#include "Vdc_toplevel.h"

#include "VGA_PLL.hpp"


//for printing inputs/outputs
#define SHOW_INPUTS
#define SHOW_OUTPUTS

#define FRAMES_NO 2

//bitmasks
#define SW_TEST_EN 1
#define SW_LAYER_0_POS 2
#define SW_LAYER_0_SCALING 5
#define SW_SCALING_METHOD 8

void Set_Blanking(Vdc_toplevel * top, PLL VGA_PLL){

    if(VGA_PLL.H_ctr >= H_BLANK){
        top->horizontal_blanking = !1;
    } else {
        top->horizontal_blanking = !0;
    }
    if(VGA_PLL.V_ctr >= V_BLANK){
        top->vertical_blanking = !1;
    } else {
        top->vertical_blanking = !0;
    }
}

void Print_All_Signals(Vdc_toplevel * top){
    //inputs
    #ifdef SHOW_INPUTS
    std::cout << "\n\ninputs" << std::endl;
    // std::cout << "clk = " << top->MAX10_CLK2_50 << std::endl; //sometimes cout doesn't print value
    printf("clk = %d\nnrst= %d\nen = %d\nsw_test_en = %d\nsw_layer_0_pos = %d\nsw_layer_0_scaling = %d\n"
            "sw_scaling_method = %d\nuser_int_valid = %d\nvertical_blanking = %d\nhorizontal_blanking = %d\n"
            "ipu_pixel_ready = %d\n", 
            top->clk, top->nrst, top->en, top->sw_test_en, top->sw_layer_0_pos, top->sw_layer_0_scaling,
            top->sw_scaling_method, top->user_int_valid, top->vertical_blanking, top->horizontal_blanking,
            top->ipu_pixel_ready);

    #endif

    //outputs
    #ifdef SHOW_OUTPUTS
    std::cout << "\noutputs" << std::endl;
    printf("led_frame_underrun = %d\nled_frame_finished = %d\nuser_int_ready = %d\n"
            "ipu_pixel_valid = %d\nipu_pixel_border = %d\nipu_pixel_data = %d\n", 
            top->led_frame_underrun, top->led_frame_finished, top->user_int_ready,
            top->ipu_pixel_valid, top->ipu_pixel_border, top->ipu_pixel_data);
    #endif
}


int main(int argc, char** argv){
    //my stuff
    PLL VGA_PLL;

    //verilator stuff

    // Create logs/ directory in case we have traces to put under it
    Verilated::mkdir("logs");

    const std::unique_ptr<VerilatedContext> contextp{new VerilatedContext};

    contextp->debug(0);
    contextp->randReset(2);
    contextp->traceEverOn(true);
    contextp->commandArgs(argc, argv);

    const std::unique_ptr<Vdc_toplevel> top{new Vdc_toplevel{contextp.get(), "TOP"}};

    //inputs
    top->clk = 0;
    top->nrst = 0;

    top->en = 1; //<- seems important
    top->sw_test_en = 1;
    top->sw_layer_0_pos = 1;
    top->sw_layer_0_scaling = 1;
    top->sw_scaling_method = 1;
    top->user_int_valid = 1;
    
    top->vertical_blanking = 0;
    top->horizontal_blanking = 0;
    top->ipu_pixel_ready = 0;

    top->input_pixel_data = 7;

    //outputs
    top->led_frame_underrun = 0;
    top->led_frame_finished = 0;
    top->user_int_ready = 0;
    top->ipu_pixel_valid = 0;
    top->ipu_pixel_border = 0;
    top->ipu_pixel_data = 0;

    //const
    top->const_input_size_width = 128;
    top->const_input_size_height = 128;
    top->const_output_size_width = 640;
    top->const_output_size_height = 480;
    top->const_initial_address = 0;
    top->const_border_color = 0;

    //enable trace------------------
    VerilatedVcdC* tfp = nullptr;
    tfp = new VerilatedVcdC;
    top->trace(tfp, 99);
    Verilated::mkdir("logs");
    tfp->open("logs/vlt_dump.vcd");
    //------------------------------

    while(!(contextp->gotFinish())){

        //increment timing
        contextp->timeInc(1);
        top->clk = !top->clk & 0x1;
        VGA_PLL.Increment_Ctr();

        //drive blanking
        Set_Blanking(top.get(), VGA_PLL);

        //reset signal
        if(contextp->time() < 15){
            top->nrst = 0 & (~0x1);
            VGA_PLL.Reset();
        } else {
            top->nrst = 1 | (0x1);
        }

        top->eval();

        //add trace
        tfp->dump(contextp->time());

        //finish after printing 2 frame(s)
        if((contextp->time() > FRAMES_NO*20*1'000'000 + 15)){
            Print_All_Signals(top.get());
            break;
        }
    }

    top->final();

    //trace close
    if (tfp) {
        tfp->close();
        tfp = nullptr;
    }

    return 0;
}
