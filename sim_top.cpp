#include <iostream>
#include <stdlib.h>
#include <memory>

#include <verilated.h>
#include "Vdc_toplevel.h"

int main(int argc, char** argv){

    const std::unique_ptr<VerilatedContext> contextp{new VerilatedContext};

    (*contextp).debug(0);
    contextp->randReset(2);
    contextp->traceEverOn(true);
    contextp->commandArgs(argc, argv);

    const std::unique_ptr<Vdc_toplevel> top{new Vdc_toplevel{contextp.get(), "TOP"}};

    //inputs
    top->clk = 0;
    top->nrst = 0;
    top->en = 1;
    top->sw_test_en = 0;
    top->sw_layer_0_pos = 0;
    top->sw_layer_0_scaling = 0;
    top->sw_scaling_method = 0;
    top->user_int_valid = 1;
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
    
    while(!(contextp->gotFinish())){

        contextp->timeInc(1);
        top->clk = !top->clk;

        //reset signal
        if(contextp->time() < 15){
            top->nrst = 0;
        } else {
            top->nrst = 1;
        }
        
        printf("inloop");

        top->eval();
    }

    top->final();

    return 0;
}