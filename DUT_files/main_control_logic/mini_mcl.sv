
module mini_mcl #(
  parameter LINE_NUMBER_WIDTH = 16
)(
  input wire clk,
  input wire nrst,
  input wire en,

  input wire line_data_ready,
  output wire[(LINE_NUMBER_WIDTH-1):0] line_number
);

wire[(LINE_NUMBER_WIDTH-1):0] line_number_nxt_c;
wire line_number_en_c;
reg[(LINE_NUMBER_WIDTH-1):0] line_number_r;
assign line_number_en_c = en && line_data_ready;
assign line_number_nxt_c = (line_number_r < LINE_NUMBER_WIDTH'('d127)) ? 
                            line_number_r + LINE_NUMBER_WIDTH'('h1) : 
                            '0;
always @(posedge clk, negedge nrst) begin
  if(!nrst) begin
    line_number_r <= '0;
  end else if(line_number_en_c == 1) begin
    line_number_r <= line_number_nxt_c;
  end
end
assign line_number = line_number_r;

endmodule
