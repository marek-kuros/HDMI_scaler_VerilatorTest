module dc_vga_controller#(
						parameter CONFIG_H_ACTIVE_SIZE = 640,
											CONFIG_H_BACK_PORCH_SIZE = 48,
											CONFIG_H_SYNC_PULSE_SIZE = 96,
											CONFIG_H_FRONT_PORCH_SIZE = 16,
											CONFIG_V_ACTIVE_SIZE = 480,
											CONFIG_V_BACK_PORCH_SIZE = 33,
											CONFIG_V_SYNC_PULSE_SIZE = 2,
											CONFIG_V_FRONT_PORCH_SIZE = 10)
											(iRST_n,
											 iVGA_CLK,
											 sw_test_en,
											 pixel_valid,
											 pixel_ready,
											 pixel_data,
											 v_blank,
											 h_blank,
											 oHS,
											 oVS,
											 oVGA_B,
											 oVGA_G,
											 oVGA_R);
							 
localparam COLOR_RES = 4; //number of bits for each color on VGA output
localparam PIXEL_DATA_WIDTH = 24; // input data 3*8bits r,g,b
input iRST_n;
input iVGA_CLK;
input wire sw_test_en; //0->display pipline , 1->display pattern
output reg oHS;
output reg oVS;
output [COLOR_RES - 1:0] oVGA_B;
output [COLOR_RES - 1:0] oVGA_G;  
output [COLOR_RES - 1:0] oVGA_R; 
//IPU <-> vga_cotroler signals
output wire  pixel_ready;
input wire pixel_valid;
input wire [PIXEL_DATA_WIDTH -1:0] pixel_data;  
//To MCL signals
output wire v_blank;
output wire h_blank;                    
///////// ////                     
reg [PIXEL_DATA_WIDTH - 1:0] bgr_data;
wire cBLANK_n,cHS,cVS,rst;
////
assign rst = ~iRST_n;
reg frame_ready_c; 
reg frame_en_c ; // if 1'b1 then frame will be show on display

always_comb begin
	frame_ready_c = frame_en_c ? cBLANK_n : 1'b0 ;
end

video_sync_generator #(.CONFIG_H_ACTIVE_SIZE(CONFIG_H_ACTIVE_SIZE),
													.CONFIG_H_BACK_PORCH_SIZE(CONFIG_H_BACK_PORCH_SIZE),
													.CONFIG_H_SYNC_PULSE_SIZE(CONFIG_H_SYNC_PULSE_SIZE),
													.CONFIG_H_FRONT_PORCH_SIZE(CONFIG_H_FRONT_PORCH_SIZE),
													.CONFIG_V_ACTIVE_SIZE(CONFIG_V_ACTIVE_SIZE),
													.CONFIG_V_BACK_PORCH_SIZE(CONFIG_V_BACK_PORCH_SIZE),
													.CONFIG_V_SYNC_PULSE_SIZE(CONFIG_V_SYNC_PULSE_SIZE),
													.CONFIG_V_FRONT_PORCH_SIZE(CONFIG_V_FRONT_PORCH_SIZE)
								)


							 LTM_ins (.vga_clk(iVGA_CLK),
										 .reset(rst),
										 .blank_n(cBLANK_n),
										 .v_blank(v_blank),
										 .h_blank(h_blank),
										 .HS(cHS),
										 .VS(cVS)
										 );

										
										
										
assign pixel_ready = frame_ready_c;

always@(posedge iVGA_CLK , negedge  iRST_n) begin
	if(!iRST_n)
		bgr_data <= {PIXEL_DATA_WIDTH{1'b0}};
	else if(frame_ready_c & pixel_valid)//handshaking
		bgr_data <= pixel_data;
	else 
		bgr_data <= {PIXEL_DATA_WIDTH{1'b0}};



end



assign oVGA_B= sw_test_en ? pattern_data[23:20] : bgr_data[23:20];
assign oVGA_G=sw_test_en  ? pattern_data[15:12] : bgr_data[15:12]; 
assign oVGA_R=sw_test_en  ? pattern_data[7:4] : bgr_data[7:4];
///////////////////
//////Delay the iHD, iVD,iDEN for one clock cycle;
reg mHS, mVS;
always@(posedge iVGA_CLK)
begin
  mHS<=cHS;
  mVS<=cVS;
  oHS<=mHS;
  oVS<=mVS;
end


//VGA pattern generator
localparam addr_width = $clog2(CONFIG_H_ACTIVE_SIZE);
reg [addr_width - 1 : 0 ] addr_cnt;

 //addr gen
always@(posedge iVGA_CLK,negedge iRST_n)
begin
  if (!iRST_n)
     addr_cnt<=19'd0;
  else if (cBLANK_n==1'b1)
     addr_cnt<=addr_cnt+1;
	  else
	    addr_cnt<=19'd0;
end

reg [PIXEL_DATA_WIDTH -1:0] pattern_data;  

always@(posedge iVGA_CLK)
begin
  if (~iRST_n)
  begin
     pattern_data<=24'h000000;
  end
    else
    begin
      if (0<addr_cnt && addr_cnt <= CONFIG_H_ACTIVE_SIZE/3)
					pattern_data <= {8'hff, 8'h00, 8'h00}; // blue
				else if (addr_cnt > CONFIG_H_ACTIVE_SIZE/3 && addr_cnt <= CONFIG_H_ACTIVE_SIZE*2/3)
					pattern_data <= {8'h00,8'hff, 8'h00};  // green
				else if(addr_cnt > CONFIG_H_ACTIVE_SIZE*2/3 && addr_cnt <=CONFIG_H_ACTIVE_SIZE)
					pattern_data <= {8'h00, 8'h00, 8'hff}; // red
				else pattern_data <= 24'h0000; 
 
    end
end








//FSM If data on pixel data are not ready before Vertical Back Porch, the frame is not displayed
localparam FRAME_ENABLE_FSM_WIDTH = 2; //2 bits fsm
localparam FSM_FRAME_ENABLE_IDLE 				= 2'b00,
			  FSM_FRAME_ENABLE_DISPLAY_FRAME 	= 2'b01,
			  FSM_FRAME_ENABLE_WAIT_FOR_V_PULSE = 2'b11,
			  FSM_FRAME_ENABLE_UNUSED_10        = 2'b10;
			  

reg [FRAME_ENABLE_FSM_WIDTH -1 : 0] frame_enable_fsm_r; //curent ctate
reg [FRAME_ENABLE_FSM_WIDTH -1 : 0] frame_enable_fsm_nxt_c; //next state


always_ff @(posedge iVGA_CLK or negedge iRST_n ) 
	begin
	if(!iRST_n)
		frame_enable_fsm_r <= {FRAME_ENABLE_FSM_WIDTH{1'b0}};
	else
		frame_enable_fsm_r <= frame_enable_fsm_nxt_c;

	end



	
	



always_comb
	begin
	case(frame_enable_fsm_r)
	// before back porch data must be valid 
	  FSM_FRAME_ENABLE_IDLE:
		frame_enable_fsm_nxt_c = (pixel_valid & (!cVS)) ? FSM_FRAME_ENABLE_DISPLAY_FRAME :
																											FSM_FRAME_ENABLE_IDLE;
	//wait for Vsync high level																	  
	  FSM_FRAME_ENABLE_DISPLAY_FRAME:
		frame_enable_fsm_nxt_c = cVS ? FSM_FRAME_ENABLE_WAIT_FOR_V_PULSE :
																	 FSM_FRAME_ENABLE_DISPLAY_FRAME;
	// wait until Vsync will be low
	  FSM_FRAME_ENABLE_WAIT_FOR_V_PULSE:
		frame_enable_fsm_nxt_c = (!cVS) ? FSM_FRAME_ENABLE_IDLE :
																			FSM_FRAME_ENABLE_WAIT_FOR_V_PULSE;
	  default:
		frame_enable_fsm_nxt_c = {FRAME_ENABLE_FSM_WIDTH{1'b0}};
	
	endcase
	end


//output state fsm
always_comb
	begin
	case(frame_enable_fsm_r)
	  FSM_FRAME_ENABLE_IDLE:
		frame_en_c = 1'b0;

	  FSM_FRAME_ENABLE_DISPLAY_FRAME:
		frame_en_c = 1'b1;

	  FSM_FRAME_ENABLE_WAIT_FOR_V_PULSE:
		frame_en_c = 1'b1;
		
	  default:
		frame_en_c = 1'b0;
	
	endcase
	end



endmodule




