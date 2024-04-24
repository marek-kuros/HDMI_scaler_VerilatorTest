module dc_bu_memory #(
  parameter BUFF_ADDR_WIDTH = 10,
  parameter MEMORY_HEIGHT = 128,
  parameter WORD_WIDTH = 24
)(
  input wire clk,
  input wire ce,
  input wire we,
  input wire[(BUFF_ADDR_WIDTH-1):0] waddr,
  input wire[(WORD_WIDTH-1):0] wdata,
  input wire re,
  input wire[(BUFF_ADDR_WIDTH-1):0] raddr,
  output wire[(WORD_WIDTH-1):0] rdata
);

reg[(WORD_WIDTH-1):0] mem[0:(MEMORY_HEIGHT-1)];


// read
wire[(WORD_WIDTH-1):0] rdata_nxt_c;
reg[(WORD_WIDTH-1):0] rdata_r;
wire rdata_en_c;
assign rdata_nxt_c = mem[raddr];
assign rdata_en_c = re && !we && ce;  // write has priority over read
always_ff @(posedge clk) begin
  if(rdata_en_c) begin
    rdata_r <= rdata_nxt_c;
  end
end
assign rdata = rdata_r;

//write
wire wdata_en_c;
assign wdata_en_c = we && ce;
always @(posedge clk) begin
  if(wdata_en_c) begin
    mem[waddr] <= wdata;
  end
end

endmodule