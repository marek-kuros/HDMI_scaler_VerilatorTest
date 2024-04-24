module dc_bu_buff_func_manager #(
  parameter BUFFER_NUM = 5 
)(
  input wire clk,
  input wire en,
  input wire nrst,  

  input wire next_line,
  input wire no_func_switch,
  output wire[(BUFFER_NUM-1):0] write_buff,
  output wire[(BUFFER_NUM-1):0] y0_buff,
  output wire[(BUFFER_NUM-1):0] y1_buff,
  output wire[(BUFFER_NUM-1):0] y2_buff,
  output wire[(BUFFER_NUM-1):0] y3_buff
);

localparam BUFF_0 = BUFFER_NUM'('b00001);
localparam BUFF_1 = BUFFER_NUM'('b00010);
localparam BUFF_2 = BUFFER_NUM'('b00100);
localparam BUFF_3 = BUFFER_NUM'('b01000);
localparam BUFF_4 = BUFFER_NUM'('b10000);

wire[(BUFFER_NUM-1):0] write_buff_nxt_c;
wire[(BUFFER_NUM-1):0] y0_buff_nxt_c;
wire[(BUFFER_NUM-1):0] y1_buff_nxt_c;
wire[(BUFFER_NUM-1):0] y2_buff_nxt_c;
wire[(BUFFER_NUM-1):0] y3_buff_nxt_c;
reg[(BUFFER_NUM-1):0] write_buff_r;
reg[(BUFFER_NUM-1):0] y0_buff_r;
reg[(BUFFER_NUM-1):0] y1_buff_r;
reg[(BUFFER_NUM-1):0] y2_buff_r;
reg[(BUFFER_NUM-1):0] y3_buff_r;
wire buffer_func_en_c;
assign buffer_func_en_c = next_line && (~no_func_switch);
assign write_buff_nxt_c = y0_buff_r;
assign y0_buff_nxt_c = y1_buff_r;
assign y1_buff_nxt_c = y2_buff_r;
assign y2_buff_nxt_c = y3_buff_r;
assign y3_buff_nxt_c = write_buff_r;
always_ff @(posedge clk, negedge nrst) begin
  if(!nrst) begin
    write_buff_r <= BUFF_0;
    y0_buff_r <= BUFF_1;
    y1_buff_r <= BUFF_2;
    y2_buff_r <= BUFF_3;
    y3_buff_r <= BUFF_4;
  end else if(buffer_func_en_c) begin
    write_buff_r <= write_buff_nxt_c;
    y0_buff_r <= y0_buff_nxt_c;
    y1_buff_r <= y1_buff_nxt_c;
    y2_buff_r <= y2_buff_nxt_c;
    y3_buff_r <= y3_buff_nxt_c;
  end
end
assign write_buff = write_buff_r;
assign y0_buff = y0_buff_r;
assign y1_buff = y1_buff_r;
assign y2_buff = y2_buff_r;
assign y3_buff = y3_buff_r;

endmodule