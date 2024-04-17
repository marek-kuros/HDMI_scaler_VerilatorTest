module dc_bu_lines_ordering #(
  parameter BITS_PER_PIXEL,
  parameter BUFFER_NUM = 5,
  parameter PIXELS_PER_LINE_WIDTH 
)(
  input wire clk,
  input wire en,
  input wire nrst,

  input wire output_en,
  input wire last_read_pixel,
  input wire[(PIXELS_PER_LINE_WIDTH-1):0] pixels_per_line,
  input wire next_line,

  input wire[(BITS_PER_PIXEL-1):0] b0,
  input wire[(BITS_PER_PIXEL-1):0] b1,
  input wire[(BITS_PER_PIXEL-1):0] b2,
  input wire[(BITS_PER_PIXEL-1):0] b3,
  input wire[(BITS_PER_PIXEL-1):0] b4,
  input wire new_data,

  input wire[(BUFFER_NUM-1):0] y0_buff,
  input wire[(BUFFER_NUM-1):0] y1_buff,
  input wire[(BUFFER_NUM-1):0] y2_buff,
  input wire[(BUFFER_NUM-1):0] y3_buff,
  
  output wire[(BITS_PER_PIXEL-1):0] y0,
  output wire[(BITS_PER_PIXEL-1):0] y1,
  output wire[(BITS_PER_PIXEL-1):0] y2,
  output wire[(BITS_PER_PIXEL-1):0] y3,
  output wire pixel_data_valid,
  input wire pixel_data_ready
);

localparam BUFF_0 = BUFFER_NUM'('b00001);
localparam BUFF_1 = BUFFER_NUM'('b00010);
localparam BUFF_2 = BUFFER_NUM'('b00100);
localparam BUFF_3 = BUFFER_NUM'('b01000);
localparam BUFF_4 = BUFFER_NUM'('b10000);

wire[(BITS_PER_PIXEL-1):0] y0_nxt_c;
wire[(BITS_PER_PIXEL-1):0] y1_nxt_c;
wire[(BITS_PER_PIXEL-1):0] y2_nxt_c;
wire[(BITS_PER_PIXEL-1):0] y3_nxt_c;
reg[(BITS_PER_PIXEL-1):0] y0_r;
reg[(BITS_PER_PIXEL-1):0] y1_r;
reg[(BITS_PER_PIXEL-1):0] y2_r;
reg[(BITS_PER_PIXEL-1):0] y3_r; 
wire y_en_c;

assign y_en_c = en && pixel_data_ready;
assign y0_nxt_c = (!output_en) ? '0 :
                  (y0_buff == BUFF_0) ? b0 :
                  (y0_buff == BUFF_1) ? b1 :
                  (y0_buff == BUFF_2) ? b2 :
                  (y0_buff == BUFF_3) ? b3 :
                                      b4;

assign y1_nxt_c = (!output_en) ? '0 :
                  (y1_buff == BUFF_0) ? b0 :
                  (y1_buff == BUFF_1) ? b1 :
                  (y1_buff == BUFF_2) ? b2 :
                  (y1_buff == BUFF_3) ? b3 :
                                      b4;

assign y2_nxt_c = (!output_en) ? '0 :
                  (y2_buff == BUFF_0) ? b0 :
                  (y2_buff == BUFF_1) ? b1 :
                  (y2_buff == BUFF_2) ? b2 :
                  (y2_buff == BUFF_3) ? b3 :
                                      b4;

assign y3_nxt_c = (!output_en) ? '0 :
                  (y3_buff == BUFF_0) ? b0 :
                  (y3_buff == BUFF_1) ? b1 :
                  (y3_buff == BUFF_2) ? b2 :
                  (y3_buff == BUFF_3) ? b3 :
                                      b4;

always_ff @(posedge clk, negedge nrst) begin
  if(!nrst) begin
    y0_r <= '0;
    y1_r <= '0;
    y2_r <= '0;
    y3_r <= '0;
  end else if(y_en_c) begin
    y0_r <= y0_nxt_c;
    y1_r <= y1_nxt_c;
    y2_r <= y2_nxt_c;
    y3_r <= y3_nxt_c;
  end
end
assign y0 = y0_r;
assign y1 = y1_r;
assign y2 = y2_r;
assign y3 = y3_r;

// next_line needs to be delayed because it causes counter to reset too early 
reg next_line_r;
wire next_line_en;
assign next_line_en = en;
always_ff @(posedge clk, negedge nrst) begin
  if(!nrst) begin
    next_line_r <= '0;
  end else if(next_line_en) begin
    next_line_r <= next_line;
  end
end

wire valid_en_nxt_c;
wire valid_en_en_c;
reg valid_en_r;
assign valid_en_en_c = en;
assign valid_en_nxt_c = (!output_en) ? '0 :
                        (new_data) ? 1'h1 :
                        valid_en_r;
always_ff @(posedge clk, negedge nrst) begin
  if(!nrst) begin
    valid_en_r <= '0;
  end else if(valid_en_en_c) begin
    valid_en_r <= valid_en_nxt_c;
  end
end

wire[(PIXELS_PER_LINE_WIDTH-1):0] handshake_cnt_nxt_c;
wire handshake_cnt_en_c;
reg[(PIXELS_PER_LINE_WIDTH-1):0] handshake_cnt_r;
wire[(PIXELS_PER_LINE_WIDTH-1):0] handshake_cnt_inc_c;
assign handshake_cnt_en_c = en && ((pixel_data_ready && pixel_data_valid) || next_line_r);
assign handshake_cnt_inc_c = handshake_cnt_r + PIXELS_PER_LINE_WIDTH'('h1);
assign handshake_cnt_nxt_c = (next_line_r) ? '0 :
                             (!output_en) ? '1:
                             (handshake_cnt_r < (pixels_per_line + PIXELS_PER_LINE_WIDTH'('h1))) ? 
                             handshake_cnt_inc_c :
                             handshake_cnt_r;
always_ff @(posedge clk, negedge nrst) begin
  if(!nrst) begin
    handshake_cnt_r <= '0;
  end else if(handshake_cnt_en_c) begin
    handshake_cnt_r <= handshake_cnt_nxt_c;
  end
end


wire pixel_data_valid_nxt_c;
wire pixel_data_valid_en_c;
reg pixel_data_valid_r;
assign pixel_data_valid_en_c = en;
assign pixel_data_valid_nxt_c = (handshake_cnt_r < pixels_per_line) && output_en;
always_ff @(posedge clk, negedge nrst) begin
  if(!nrst) begin
    pixel_data_valid_r <= '0;
  end else if(pixel_data_valid_en_c) begin
    pixel_data_valid_r <= pixel_data_valid_nxt_c;
  end
end
assign pixel_data_valid = pixel_data_valid_r && valid_en_r;

endmodule
