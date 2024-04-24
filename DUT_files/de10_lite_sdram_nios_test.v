// ============================================================================
// Copyright (c) 2016 by Terasic Technologies Inc.
// ============================================================================
//
// Permission:
//
//   Terasic grants permission to use and modify this code for use
//   in synthesis for all Terasic Development Boards and Altera Development 
//   Kits made by Terasic.  Other use of this code, including the selling 
//   ,duplication, or modification of any portion is strictly prohibited.
//
// Disclaimer:
//
//   This VHDL/Verilog or C/C++ source code is intended as a design reference
//   which illustrates how these types of functions can be implemented.
//   It is the user's responsibility to verify their design for
//   consistency and functionality through the use of formal
//   verification methods.  Terasic provides no warranty regarding the use 
//   or functionality of this code.
//
// ============================================================================
//           
//  Terasic Technologies Inc
//  9F., No.176, Sec.2, Gongdao 5th Rd, East Dist, Hsinchu City, 30070. Taiwan
//  
//  
//                     web: http://www.terasic.com/  
//                     email: support@terasic.com
//
// ============================================================================
//Date:  Wed May 11 09:51:57 2016
// ============================================================================


module DE10_LITE_SDRAM_Nios_Test(

      ///////// Clocks /////////
      input              ADC_CLK_10,
      input              MAX10_CLK1_50,
      input              MAX10_CLK2_50,

      ///////// KEY /////////
      input    [ 1: 0]   KEY,

      ///////// SW /////////
      input    [ 9: 0]   SW,

      ///////// LEDR /////////
      output   [ 9: 0]   LEDR,

      ///////// HEX /////////
      output   [ 7: 0]   HEX0,
      output   [ 7: 0]   HEX1,
      output   [ 7: 0]   HEX2,
      output   [ 7: 0]   HEX3,
      output   [ 7: 0]   HEX4,
      output   [ 7: 0]   HEX5,

      ///////// SDRAM /////////
      output             DRAM_CLK,
      output             DRAM_CKE,
      output   [12: 0]   DRAM_ADDR,
      output   [ 1: 0]   DRAM_BA,
      inout    [15: 0]   DRAM_DQ,
      output             DRAM_LDQM,
      output             DRAM_UDQM,
      output             DRAM_CS_N,
      output             DRAM_WE_N,
      output             DRAM_CAS_N,
      output             DRAM_RAS_N,

      ///////// VGA /////////
      output             VGA_HS,
      output             VGA_VS,
      output   [ 3: 0]   VGA_R,
      output   [ 3: 0]   VGA_G,
      output   [ 3: 0]   VGA_B,

      ///////// Clock Generator I2C /////////
      output             CLK_I2C_SCL,
      inout              CLK_I2C_SDA,

      ///////// GSENSOR /////////
      output             GSENSOR_SCLK,
      inout              GSENSOR_SDO,
      inout              GSENSOR_SDI,
      input    [ 2: 1]   GSENSOR_INT,
      output             GSENSOR_CS_N,

      ///////// GPIO /////////
      inout    [35: 0]   GPIO,

      ///////// ARDUINO /////////
      inout    [15: 0]   ARDUINO_IO,
      inout              ARDUINO_RESET_N

     

);


//=======================================================
//  REG/WIRE declarations
//=======================================================

  localparam AXI_ARADDR_WIDTH = 32;
  localparam PIXELS_PER_LINE_WIDTH = 12;
  localparam LINE_NUMBER_WIDTH = 8;
  localparam BYTES_PER_PIXEL = 3;
  localparam READ_DATA_SIZE = 1;
  localparam FETCHING_WORD_CNT_WIDTH = 16;
  localparam BUFFER_SIZE = 128;
  localparam BUFF_ADDR_WIDTH = 7;
  localparam BUFFER_NUM = 5;
  localparam SCR_SIZE_WIDTH = 12;
  localparam SCALE_METHOD_WIDTH = 2;
  localparam BITS_PER_PIXEL = BYTES_PER_PIXEL*8;

  // inputs/outputs connected to FPGA switches and leds 
  wire sw_display_en;
  wire sw_test_en;
  wire[2:0] sw_layer_0_pos;
  wire[2:0] sw_layer_0_scaling;
  wire[1:0] sw_scaling_method;  // sw inputs are connected to switches on board
  wire[(SCR_SIZE_WIDTH-1):0] const_input_size_width;
  wire[(SCR_SIZE_WIDTH-1):0] const_input_size_height;  // input image dims
  wire[(SCR_SIZE_WIDTH-1):0] const_output_size_width;
  wire[(SCR_SIZE_WIDTH-1):0] const_output_size_height;  // display dims
  wire[(AXI_ARADDR_WIDTH-1):0] const_initial_address;
  wire[(BITS_PER_PIXEL-1):0] const_border_color;
  wire led_frame_underrun;
  wire led_frame_finished;

  wire vertical_blanking;
  wire horizontal_blanking;
  wire ipu_pixel_valid;
  wire ipu_pixel_ready;
  wire[(BITS_PER_PIXEL-1):0] ipu_pixel_data;
  wire ipu_pixel_border;

  assign sw_display_en = 1'h1;
  assign sw_test_en = SW[1];
  assign sw_layer_0_pos = SW[4:2];
  assign sw_layer_0_scaling = SW[7:5];
  assign sw_scaling_method = SW[9:8];
  assign const_input_size_width = SCR_SIZE_WIDTH'('d128);
  assign const_input_size_height = SCR_SIZE_WIDTH'('d128);
  assign const_output_size_width = SCR_SIZE_WIDTH'('d640);
  assign const_output_size_height = SCR_SIZE_WIDTH'('d480);
  assign const_initial_address = '0;
  assign const_border_color = BITS_PER_PIXEL'('hFFFFFF);
  
  
//axi connect wire
  // AXI read address
   wire[7:0] axi_arid;    
   wire[(AXI_ARADDR_WIDTH-1):0] axi_araddr;  
   wire[7:0] axi_arlen;   
   wire[2:0] axi_arsize;  
   wire[1:0] axi_arburst; 
   wire[1:0] axi_arlock;  
   wire[3:0] axi_arcache; 
   wire[2:0] axi_arprot;  
   wire[3:0] axi_arqos;   
   wire[3:0] axi_arregion;
   wire axi_arvalid; 
   wire axi_arready; 

  // AXI read data
   wire[7:0] axi_rid;   
   wire[15:0] axi_rdata; 
   wire[1:0] axi_rresp; 
   wire axi_rlast;
   wire axi_rvalid;
   wire axi_rready;
	
// VGA 25MHz clock

wire VGA_CTRL_CLK;

//=======================================================
//  Structural coding
//=======================================================

pll_vga u1(
	.areset(1'b0),
	.inclk0(MAX10_CLK2_50),
	.c0(VGA_CTRL_CLK),
	.locked());



DE10_LITE_Qsys u0 (
        .clk_clk                           (VGA_CTRL_CLK),                           //                        clk.clk
        .reset_reset_n                     (SW[0]),                     //                      reset.reset_n
        .altpll_0_locked_conduit_export    (),    //    altpll_0_locked_conduit.export
        .altpll_0_phasedone_conduit_export (), // altpll_0_phasedone_conduit.export
        .altpll_0_areset_conduit_export    (),     //    altpll_0_areset_conduit.export
    
        .key_external_connection_export    (KEY),    //    key_external_connection.export
		//SDRAM
		.clk_sdram_clk(DRAM_CLK),                  //               clk_sdram.clk
	   .sdram_wire_addr(DRAM_ADDR),                //              sdram_wire.addr
		.sdram_wire_ba(DRAM_BA),                  //                        .ba
		.sdram_wire_cas_n(DRAM_CAS_N),               //                        .cas_n
		.sdram_wire_cke(DRAM_CKE),                 //                        .cke
		.sdram_wire_cs_n(DRAM_CS_N),                //                        .cs_n
		.sdram_wire_dq(DRAM_DQ),                  //                        .dq
		.sdram_wire_dqm({DRAM_UDQM,DRAM_LDQM}),                 //                        .dqm
		.sdram_wire_ras_n(DRAM_RAS_N),               //                        .ras_n
		.sdram_wire_we_n(DRAM_WE_N),                 //                        .we_n
                // DMA AXI Slave IF
		.axi_bridge_0_s0_awid                    (),                    //             axi_bridge_0_s0.awid
		.axi_bridge_0_s0_awaddr                  (),                  //                            .awaddr
		.axi_bridge_0_s0_awlen                   (),                   //                            .awlen
		.axi_bridge_0_s0_awsize                  (),                  //                            .awsize
		.axi_bridge_0_s0_awburst                 (),                 //                            .awburst
		.axi_bridge_0_s0_awlock                  (),                  //                            .awlock
		.axi_bridge_0_s0_awcache                 (),                 //                            .awcache
		.axi_bridge_0_s0_awprot                  (),                  //                            .awprot
		.axi_bridge_0_s0_awqos                   (),                   //                            .awqos
		.axi_bridge_0_s0_awregion                (),                //                            .awregion
		.axi_bridge_0_s0_awvalid                 (),                 //                            .awvalid
		.axi_bridge_0_s0_awready                 (),                 //                            .awready
		.axi_bridge_0_s0_wdata                   (),                   //                            .wdata
		.axi_bridge_0_s0_wstrb                   (),                   //                            .wstrb
		.axi_bridge_0_s0_wlast                   (),                   //                            .wlast
		.axi_bridge_0_s0_wvalid                  (),                  //                            .wvalid
		.axi_bridge_0_s0_wready                  (),                  //                            .wready
		.axi_bridge_0_s0_bid                     (),                     //                            .bid
		.axi_bridge_0_s0_bresp                   (),                   //                            .bresp
		.axi_bridge_0_s0_bvalid                  (),                  //                            .bvalid
		.axi_bridge_0_s0_bready                  (),                  //                            .bready
		.axi_bridge_0_s0_arid                    (axi_arid),                    //                            .arid
		.axi_bridge_0_s0_araddr                  (axi_araddr),                  //                            .araddr
		.axi_bridge_0_s0_arlen                   (axi_arlen),                   //                            .arlen
		.axi_bridge_0_s0_arsize                  (axi_arsize),                  //                            .arsize
		.axi_bridge_0_s0_arburst                 (axi_arburst),                 //                            .arburst
		.axi_bridge_0_s0_arlock                  (axi_arlock),                  //                            .arlock
		.axi_bridge_0_s0_arcache                 (axi_arcache),                 //                            .arcache
		.axi_bridge_0_s0_arprot                  (axi_arprot),                  //                            .arprot
		.axi_bridge_0_s0_arqos                   (axi_arqos),                   //                            .arqos
		.axi_bridge_0_s0_arregion                (axi_arregion),                //                            .arregion
		.axi_bridge_0_s0_arvalid                 (axi_arvalid),                 //                            .arvalid
		.axi_bridge_0_s0_arready                 (axi_arready),                 //                            .arready
		.axi_bridge_0_s0_rid                     (axi_rid),                     //                            .rid
		.axi_bridge_0_s0_rdata                   (axi_rdata),                   //                            .rdata
		.axi_bridge_0_s0_rresp                   (axi_rresp),                   //                            .rresp
		.axi_bridge_0_s0_rlast                   (axi_rlast),                   //                            .rlast
		.axi_bridge_0_s0_rvalid                  (axi_rvalid),                  //                            .rvalid
		.axi_bridge_0_s0_rready                  (axi_rready)                   //                            .rready

	 
	 );
	 
  dc_toplevel #(
    .AXI_ARADDR_WIDTH(AXI_ARADDR_WIDTH),
    .PIXELS_PER_LINE_WIDTH(PIXELS_PER_LINE_WIDTH),
    .LINE_NUMBER_WIDTH(LINE_NUMBER_WIDTH),
    .READ_DATA_SIZE(READ_DATA_SIZE),
    .FETCH_WORD_COUNT_WIDTH (FETCHING_WORD_CNT_WIDTH),
    .BUFFER_SIZE(BUFFER_SIZE),
    .BUFF_ADDR_WIDTH(BUFF_ADDR_WIDTH),
    .BUFFER_NUM(BUFFER_NUM),
    .SCR_SIZE_WIDTH(SCR_SIZE_WIDTH),
    .SCALE_METHOD_WIDTH(SCALE_METHOD_WIDTH),
    .BITS_PER_PIXEL(BITS_PER_PIXEL)
  )dut(
    .clk(VGA_CTRL_CLK),//TODO:
    .en(1'b1),
    .nrst(SW[0]),
  
    // input/soutputs connected to FPGA switches and leds 
    .sw_test_en(sw_test_en),
    .sw_layer_0_pos(sw_layer_0_pos),
    .sw_layer_0_scaling(sw_layer_0_scaling),
    .sw_scaling_method(sw_scaling_method),  // sw inputs are connected to switches on board
    .const_input_size_width(const_input_size_width),
    .const_input_size_height(const_input_size_height),  // input image dims
    .const_output_size_width(const_output_size_width),
    .const_output_size_height(const_output_size_height),  // display dims
    .const_initial_address(const_initial_address),
    .const_border_color(const_border_color),
    .led_frame_underrun(led_frame_underrun),
    .led_frame_finished(led_frame_finished), 
    .user_int_valid(1'b1),

    .vertical_blanking(vertical_blanking),
    .horizontal_blanking(horizontal_blanking),
    .ipu_pixel_valid(ipu_pixel_valid),
    .ipu_pixel_ready(ipu_pixel_ready),
    .ipu_pixel_data(ipu_pixel_data),
    .ipu_pixel_border(ipu_pixel_border),
  
    .axi_arid(axi_arid),  
    .axi_araddr(axi_araddr),  
    .axi_arlen(axi_arlen),   
    .axi_arsize(axi_arsize),  
    .axi_arburst(axi_arburst), 
    .axi_arlock(axi_arlock),  
    .axi_arcache(axi_arcache), 
    .axi_arprot(axi_arprot),  
    .axi_arqos(axi_arqos),   
    .axi_arregion(axi_arregion),
    .axi_arvalid(axi_arvalid),
    .axi_arready(axi_arready), 
  
    .axi_rid(axi_rid),   
    .axi_rdata(axi_rdata), 
    .axi_rresp(axi_rresp), 
    .axi_rlast(axi_rlast), 
    .axi_rvalid(axi_rvalid),
    .axi_rready(axi_rready)
  );




  dc_vga_controller#(
	  .CONFIG_H_ACTIVE_SIZE(640),
		.CONFIG_H_BACK_PORCH_SIZE(40),
		.CONFIG_H_SYNC_PULSE_SIZE(96),
		.CONFIG_H_FRONT_PORCH_SIZE(8),
		.CONFIG_V_ACTIVE_SIZE(480),
		.CONFIG_V_BACK_PORCH_SIZE(25),
		.CONFIG_V_SYNC_PULSE_SIZE(2),
		.CONFIG_V_FRONT_PORCH_SIZE(2)
  )vga(
    .iRST_n(SW[0]),//TODO:
		.iVGA_CLK(VGA_CTRL_CLK),
		.sw_test_en(sw_test_en),
		.pixel_valid(ipu_pixel_valid),
		.pixel_ready(ipu_pixel_ready),
		.pixel_data(ipu_pixel_data),
		.v_blank(vertical_blanking),
		.h_blank(horizontal_blanking),
		.oHS(VGA_HS),
		.oVS(VGA_VS),
		.oVGA_B(VGA_B),
		.oVGA_G(VGA_G),
		.oVGA_R(VGA_R));
  
	 


endmodule
