//Modified version  terasic example of video_sync_generator
  
module video_sync_generator#(parameter CONFIG_H_ACTIVE_SIZE = 640,
													CONFIG_H_BACK_PORCH_SIZE = 48,
													CONFIG_H_SYNC_PULSE_SIZE = 96,
													CONFIG_H_FRONT_PORCH_SIZE = 16,
													CONFIG_V_ACTIVE_SIZE = 480,
													CONFIG_V_BACK_PORCH_SIZE = 33,
													CONFIG_V_SYNC_PULSE_SIZE = 2,
													CONFIG_V_FRONT_PORCH_SIZE = 10)
											
													(reset,
													 vga_clk,
													 blank_n,
													 HS,
													 VS,
													 v_blank,
													 h_blank
													 );
                            
input reset;
input vga_clk;
output reg blank_n;
output reg v_blank; //not active  horizontal display interval
output reg h_blank; //not active vertical display interval

output reg HS;
output reg VS;

///////////////////
/*
--VGA Timing
--Horizontal :
--                ______________                 _____________
--               |              |               |
--_______________|  VIDEO       |_______________|  VIDEO (next line)

--___________   _____________________   ______________________
--           |_|                     |_|
--            B <-C-><----D----><-E->
--           <------------A--------->
--The Unit used below are pixels;  
--  B->Sync_cycle                   :H_SYNC_CYCLE
--  C->Back_porch                   :HORI_BACK
--  D->Visable Area
--  E->Front porch                  :HORI_FRONT
--  A->horizontal line total length :HORI_LINE
--Vertical :
--               ______________                 _____________
--              |              |               |          
--______________|  VIDEO       |_______________|  VIDEO (next frame)
--
--__________   _____________________   ______________________
--          |_|                     |_|
--           P <-Q-><----R----><-S->
--          <-----------O---------->
--The Unit used below are horizontal lines;  
--  P->Sync_cycle                   :V_SYNC_CYCLE
--  Q->Back_porch                   :VERT_BACK
--  R->Visable Area
--  S->Front porch                  :VERT_FRONT
--  O->vertical line total length :VERT_LINE
*////////////////////////////////////////////
////////////////////////                          
//parameter
localparam HORI_LINE  = CONFIG_H_ACTIVE_SIZE + CONFIG_H_BACK_PORCH_SIZE + CONFIG_H_SYNC_PULSE_SIZE + CONFIG_H_FRONT_PORCH_SIZE ;  //Total pixels                         
localparam HORI_BACK  = CONFIG_H_SYNC_PULSE_SIZE + CONFIG_H_BACK_PORCH_SIZE; //H_LOW + HBP
localparam HORI_FRONT = CONFIG_H_FRONT_PORCH_SIZE;	 //HFP
localparam VERT_LINE  = CONFIG_V_ACTIVE_SIZE + CONFIG_V_BACK_PORCH_SIZE + CONFIG_V_SYNC_PULSE_SIZE + CONFIG_V_FRONT_PORCH_SIZE ; //Total lines
localparam VERT_BACK  = CONFIG_V_BACK_PORCH_SIZE + CONFIG_V_SYNC_PULSE_SIZE ; //VBP + Vlow
localparam VERT_FRONT = CONFIG_V_FRONT_PORCH_SIZE; //VFP
localparam H_SYNC_CYCLE = CONFIG_H_SYNC_PULSE_SIZE; //H_low
localparam V_SYNC_CYCLE = CONFIG_V_SYNC_PULSE_SIZE;	//V_low
localparam H_BLANK = HORI_FRONT+H_SYNC_CYCLE ; //add by yang
//////////////////////////

localparam H_CNT_NUM_BIT = $clog2(HORI_LINE);
localparam V_CNT_NUM_BIT = $clog2(VERT_LINE);


reg [H_CNT_NUM_BIT -1 :0] h_cnt;
reg [V_CNT_NUM_BIT -1 :0]  v_cnt;
wire cHD,cVD,cDEN,hori_valid,vert_valid;
wire cHblank , cVblank;
///////
always@(negedge vga_clk,posedge reset)
begin
  if (reset)
  begin
     h_cnt<={H_CNT_NUM_BIT{1'b0}};
     v_cnt<={V_CNT_NUM_BIT{1'b0}};
  end
    else
    begin
      if (h_cnt==HORI_LINE-1) 
      begin 
         h_cnt<={H_CNT_NUM_BIT{1'b0}};
         if (v_cnt==VERT_LINE-1)
            v_cnt<={V_CNT_NUM_BIT{1'b0}};
         else
            v_cnt<=v_cnt + {{(V_CNT_NUM_BIT-1){1'b0}},1'b1};
      end
      else
         h_cnt<=h_cnt+ {{(H_CNT_NUM_BIT-1){1'b0}},1'b1}; ;
    end
end
/////
assign cHD = (h_cnt<H_SYNC_CYCLE)?1'b0:1'b1;
assign cVD = (v_cnt<V_SYNC_CYCLE)?1'b0:1'b1;

assign hori_valid = (h_cnt<(HORI_LINE-HORI_FRONT)&& h_cnt>=HORI_BACK)?1'b1:1'b0;
assign vert_valid = (v_cnt<(VERT_LINE-VERT_FRONT)&& v_cnt>=VERT_BACK)?1'b1:1'b0;

assign cDEN = hori_valid && vert_valid;

assign cHblank = ~ hori_valid;
assign cVblank = ~ vert_valid;


always@(negedge vga_clk)
begin
  HS<=cHD;
  VS<=cVD;
  blank_n<=cDEN;
  h_blank<= cHblank;
  v_blank<= cVblank;
end

endmodule


