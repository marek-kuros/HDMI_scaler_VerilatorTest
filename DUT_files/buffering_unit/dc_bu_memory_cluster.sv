
module dc_bu_memory_cluster #(
  parameter BUFFER_SIZE,
  parameter BITS_PER_PIXEL,
  parameter BUFF_ADDR_WIDTH,
  parameter BUFFER_NUM = 5 
)(
  input wire clk,
  input wire en,
  input wire nrst,

  input wire[(BUFFER_NUM-1):0] write_buff_en,
  input wire[(BUFF_ADDR_WIDTH-1):0] write_addr,
  input wire[(BITS_PER_PIXEL-1):0] pixel_data,

  input wire[(BUFFER_NUM-1):0] read_buff_en,
  input wire[(BUFF_ADDR_WIDTH-1):0] read_addr,
  output wire[(BITS_PER_PIXEL-1):0] rdata_b0,
  output wire[(BITS_PER_PIXEL-1):0] rdata_b1,
  output wire[(BITS_PER_PIXEL-1):0] rdata_b2,
  output wire[(BITS_PER_PIXEL-1):0] rdata_b3,
  output wire[(BITS_PER_PIXEL-1):0] rdata_b4,   // 8 means number of bits in byte
  output wire new_data
);

wire[(BITS_PER_PIXEL-1):0] buff_outputs[0:(BUFFER_NUM-1)];
genvar i;
generate 
  for(i = 0; i < BUFFER_NUM; i = i+1) begin : mem_clust_gen
    dc_bu_memory #(
      .BUFF_ADDR_WIDTH(BUFF_ADDR_WIDTH),
      .MEMORY_HEIGHT(BUFFER_SIZE),
      .WORD_WIDTH(BITS_PER_PIXEL)
    ) bn (
      .clk(clk),
      .ce(en),
  
      .we(write_buff_en[i]),
      .waddr(write_addr),
      .wdata(pixel_data),
  
      .re(read_buff_en[i]),
      .raddr(read_addr),
      .rdata(buff_outputs[i])
    );
  end
endgenerate

wire new_data_in_c;
wire new_data_en_c;
//reg[1:0] new_data_r;
reg new_data_r;
assign new_data_en_c = en;
assign new_data_in_c = read_buff_en != '0;
always_ff @(posedge clk, negedge nrst) begin
  if(nrst == 0) begin
    new_data_r <= '0;
  end else if(new_data_en_c) begin
    new_data_r <= new_data_in_c;//{new_data_r[0], new_data_in_c};
  end
end

assign new_data = new_data_r;//[1];
assign rdata_b0 = buff_outputs[0];
assign rdata_b1 = buff_outputs[1];
assign rdata_b2 = buff_outputs[2];
assign rdata_b3 = buff_outputs[3];
assign rdata_b4 = buff_outputs[4];

endmodule
