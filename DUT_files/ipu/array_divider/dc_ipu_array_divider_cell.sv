/*
  Single array divider combinational cell
*/
module dc_ipu_array_divider_cell(
  input wire a,
  input wire b,
  input wire s,
  input wire cin,
  output wire cout,
  output wire r
);

wire fa_a_c = a;
wire fa_b_c = !b;
wire fa_out_c = cin ^ fa_a_c ^ fa_b_c;
assign cout = (fa_a_c ^ fa_b_c) ? cin : fa_b_c;
assign r = s ? fa_out_c : a;

endmodule
