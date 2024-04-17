enum bit[1:0] {
  DC_IPU_SCALE_METHOD_NEAREST = 2'b00,
  DC_IPU_SCALE_METHOD_LINEAR  = 2'b01,
  DC_IPU_SCALE_METHOD_CUBIC   = 2'b10,
  DC_IPU_SCALE_METHOD_MAGIC   = 2'b11
} dc_ipu_scale_method;

module dc_ipu_filter #(
  parameter COEFF_WIDTH,
  parameter COLOR_WIDTH
)(
  clk,
  nreset,
  clr,

  scale_method,

  in_valid,
  in_ready,
  texel_quad,
  coeff_x,
  coeff_y,

  out_valid,
  out_ready,
  out_pixel
);

genvar i;

localparam METHOD_WIDTH = 2;
localparam RGB_WIDTH = 3 * COLOR_WIDTH;
localparam WEIGHT_WIDTH = 16;
localparam WEIGHT_FRACT_WIDTH = 12;

// ------------------------------------- Inputs/outputs (Quartus ugliness)

input wire clk;
input wire nreset;
input wire clr;

input wire[METHOD_WIDTH-1:0] scale_method;

input wire in_valid;
output wire in_ready;
input wire[RGB_WIDTH-1:0] texel_quad[0:3][0:3];
input wire[COEFF_WIDTH-1:0] coeff_x;
input wire[COEFF_WIDTH-1:0] coeff_y;

output wire out_valid;
input wire out_ready;
output wire[RGB_WIDTH-1:0] out_pixel;

// ------------------------------------- Mode selection signals

wire nearest_selected_c = (scale_method == DC_IPU_SCALE_METHOD_NEAREST);
wire linear_selected_c = (scale_method == DC_IPU_SCALE_METHOD_LINEAR);
wire cubic_selected_c = (scale_method == DC_IPU_SCALE_METHOD_CUBIC);
wire magic_selected_c = (scale_method == DC_IPU_SCALE_METHOD_MAGIC);

wire outer_product_in_ready;

// ------------------------------------- Nearest

wire nearest_in_valid;
wire nearest_in_ready;
wire nearest_out_valid;
wire nearest_out_ready;
wire[RGB_WIDTH-1:0] nearest_out_texel_matrix[0:3][0:3];
wire signed[WEIGHT_WIDTH-1:0] nearest_out_weights_x[0:3];
wire signed[WEIGHT_WIDTH-1:0] nearest_out_weights_y[0:3];

assign nearest_in_valid  = in_valid && nearest_selected_c;
assign nearest_out_ready = outer_product_in_ready && nearest_selected_c;

dc_ipu_filter_nearest #(
  .RGB_WIDTH(RGB_WIDTH),
  .COEFF_WIDTH(COEFF_WIDTH),
  .WEIGHT_WIDTH(WEIGHT_WIDTH),
  .WEIGHT_FRACT_WIDTH(WEIGHT_FRACT_WIDTH)
)
u_nearest(
  .clk(clk),
  .nreset(nreset),
  .clr(clr),

  .in_valid(nearest_in_valid),
  .in_ready(nearest_in_ready),
  .in_texel_matrix(texel_quad),
  .coeff_x(coeff_x),
  .coeff_y(coeff_y),
  
  .out_valid(nearest_out_valid),
  .out_ready(nearest_out_ready),
  .out_texel_matrix(nearest_out_texel_matrix),
  .out_weights_x(nearest_out_weights_x),
  .out_weights_y(nearest_out_weights_y)
);

// ------------------------------------- Linear

wire linear_in_valid;
wire linear_in_ready;
wire linear_out_valid;
wire linear_out_ready;
wire[RGB_WIDTH-1:0] linear_out_texel_matrix[0:3][0:3];
wire signed[WEIGHT_WIDTH-1:0] linear_out_weights_x[0:3];
wire signed[WEIGHT_WIDTH-1:0] linear_out_weights_y[0:3];

assign linear_in_valid  = in_valid && linear_selected_c;
assign linear_out_ready = outer_product_in_ready && linear_selected_c;

dc_ipu_filter_linear #(
  .RGB_WIDTH(RGB_WIDTH),
  .COEFF_WIDTH(COEFF_WIDTH),
  .WEIGHT_WIDTH(WEIGHT_WIDTH),
  .WEIGHT_FRACT_WIDTH(WEIGHT_FRACT_WIDTH)
)
u_linear(
  .clk(clk),
  .nreset(nreset),
  .clr(clr),

  .in_valid(linear_in_valid),
  .in_ready(linear_in_ready),
  .in_texel_matrix(texel_quad),
  .coeff_x(coeff_x),
  .coeff_y(coeff_y),
  
  .out_valid(linear_out_valid),
  .out_ready(linear_out_ready),
  .out_texel_matrix(linear_out_texel_matrix),
  .out_weights_x(linear_out_weights_x),
  .out_weights_y(linear_out_weights_y)
);

// ------------------------------------- Magic

wire magic_in_valid;
wire magic_in_ready;
wire magic_out_valid;
wire magic_out_ready;
wire[RGB_WIDTH-1:0] magic_out_texel_matrix[0:3][0:3];
wire signed[WEIGHT_WIDTH-1:0] magic_out_weights_x[0:3];
wire signed[WEIGHT_WIDTH-1:0] magic_out_weights_y[0:3];

assign magic_in_valid  = in_valid && magic_selected_c;
assign magic_out_ready = outer_product_in_ready && magic_selected_c;

dc_ipu_filter_magic #(
  .RGB_WIDTH(RGB_WIDTH),
  .COEFF_WIDTH(COEFF_WIDTH),
  .WEIGHT_WIDTH(WEIGHT_WIDTH),
  .WEIGHT_FRACT_WIDTH(WEIGHT_FRACT_WIDTH)
)
u_magic(
  .clk(clk),
  .nreset(nreset),
  .clr(clr),

  .in_valid(magic_in_valid),
  .in_ready(magic_in_ready),
  .in_texel_matrix(texel_quad),
  .coeff_x(coeff_x),
  .coeff_y(coeff_y),
  
  .out_valid(magic_out_valid),
  .out_ready(magic_out_ready),
  .out_texel_matrix(magic_out_texel_matrix),
  .out_weights_x(magic_out_weights_x),
  .out_weights_y(magic_out_weights_y)
);

// ------------------------------------- Cubic

wire cubic_in_valid;
wire cubic_in_ready;
wire cubic_out_valid;
wire cubic_out_ready;
wire[RGB_WIDTH-1:0] cubic_out_texel_matrix[0:3][0:3];
wire signed[WEIGHT_WIDTH-1:0] cubic_out_weights_x[0:3];
wire signed[WEIGHT_WIDTH-1:0] cubic_out_weights_y[0:3];

assign cubic_in_valid  = in_valid && cubic_selected_c;
assign cubic_out_ready = outer_product_in_ready && cubic_selected_c;

dc_ipu_filter_cubic #(
  .RGB_WIDTH(RGB_WIDTH),
  .COEFF_WIDTH(COEFF_WIDTH),
  .WEIGHT_WIDTH(WEIGHT_WIDTH),
  .WEIGHT_FRACT_WIDTH(WEIGHT_FRACT_WIDTH)
)
u_cubic(
  .clk(clk),
  .nreset(nreset),
  .clr(clr),

  .in_valid(cubic_in_valid),
  .in_ready(cubic_in_ready),
  .in_texel_matrix(texel_quad),
  .coeff_x(coeff_x),
  .coeff_y(coeff_y),
  
  .out_valid(cubic_out_valid),
  .out_ready(cubic_out_ready),
  .out_texel_matrix(cubic_out_texel_matrix),
  .out_weights_x(cubic_out_weights_x),
  .out_weights_y(cubic_out_weights_y)
);

// ------------------------------------- Algorithm switching

wire outer_product_in_valid_c = 
  nearest_selected_c ? nearest_out_valid :
  linear_selected_c  ? linear_out_valid  :
  cubic_selected_c   ? cubic_out_valid   :
  magic_selected_c   ? magic_out_valid   :
                       nearest_out_valid;

wire[RGB_WIDTH-1:0] texel_matrix_c[0:3][0:3];
assign texel_matrix_c =
  nearest_selected_c ? nearest_out_texel_matrix :
  linear_selected_c  ? linear_out_texel_matrix  :
  cubic_selected_c   ? cubic_out_texel_matrix   :
  magic_selected_c   ? magic_out_texel_matrix   :
                       nearest_out_texel_matrix;

wire signed[WEIGHT_WIDTH-1:0] weights_x_c[0:3];
assign weights_x_c[0:3] =
  nearest_selected_c ? nearest_out_weights_x :
  linear_selected_c  ? linear_out_weights_x  :
  cubic_selected_c   ? cubic_out_weights_x   :
  magic_selected_c   ? magic_out_weights_x   :
                       nearest_out_weights_x;

wire signed[WEIGHT_WIDTH-1:0] weights_y_c[0:3];
assign weights_y_c[0:3] =
  nearest_selected_c ? nearest_out_weights_y :
  linear_selected_c  ? linear_out_weights_y  :
  cubic_selected_c   ? cubic_out_weights_y   :
  magic_selected_c   ? magic_out_weights_y   :
                       nearest_out_weights_y;

assign in_ready =
  nearest_selected_c ? nearest_in_ready :
  linear_selected_c  ? linear_in_ready  :
  cubic_selected_c   ? cubic_in_ready   :
  magic_selected_c   ? magic_in_ready   :
                       nearest_in_ready;

// ------------------------------------- Weights outer product

wire outer_product_out_valid;
wire outer_product_out_ready;
wire[RGB_WIDTH-1:0] outer_product_out_texel_matrix[0:3][0:3];
wire signed[WEIGHT_WIDTH-1:0] outer_product_out_weights_matrix[0:3][0:3];

dc_ipu_filter_outer_product #(
  .RGB_WIDTH(RGB_WIDTH),
  .WEIGHT_FRACT_WIDTH(WEIGHT_FRACT_WIDTH),
  .WEIGHT_WIDTH(WEIGHT_WIDTH)
)
u_outer_product(
  .clk(clk),
  .nreset(nreset),
  .clr(clr),
  
  .in_valid(outer_product_in_valid_c),
  .in_ready(outer_product_in_ready),
  .in_texel_matrix(texel_matrix_c),
  .weights_x(weights_x_c),
  .weights_y(weights_y_c),
  
  .out_valid(outer_product_out_valid),
  .out_ready(outer_product_out_ready),
  .out_texel_matrix(outer_product_out_texel_matrix),
  .weights_matrix(outer_product_out_weights_matrix)
);

// ------------------------------------- Texel weighing cores for each channel

wire core_in_valid = outer_product_out_valid;
wire core_in_ready;
assign outer_product_out_ready = core_in_ready;
wire core_out_valid;
wire core_out_ready;

// Split channels
reg[COLOR_WIDTH-1:0] core_rgb_texel_matrix[0:2][0:3][0:3];
always_comb
  for (int x = 0; x < 4; x++)
    for (int y = 0; y < 4; y++) begin
      core_rgb_texel_matrix[0][x][y] = outer_product_out_texel_matrix[x][y][7:0];   // R
      core_rgb_texel_matrix[1][x][y] = outer_product_out_texel_matrix[x][y][15:8];  // G
      core_rgb_texel_matrix[2][x][y] = outer_product_out_texel_matrix[x][y][23:16]; // B
    end

wire[COLOR_WIDTH-1:0] core_rgb_pixel_data[0:2];

generate
  for (i = 0; i < 3; i++) begin : gb_channel_cores
    wire tmp_in_ready, tmp_out_valid;

    dc_ipu_filter_core #(
      .WEIGHT_WIDTH(WEIGHT_WIDTH),
      .WEIGHT_FRACT_WIDTH(WEIGHT_FRACT_WIDTH),
      .COLOR_WIDTH(COLOR_WIDTH)
    )
    u_core(
      .clk(clk),
      .nreset(nreset),
      .clr(clr),
      
      .in_valid(core_in_valid),
      .in_ready(tmp_in_ready),
      .weights_matrix(outer_product_out_weights_matrix),
      .texel_matrix(core_rgb_texel_matrix[i]),

      .out_valid(tmp_out_valid),
      .out_ready(core_out_ready),
      .pixel_data(core_rgb_pixel_data[i])
    );

    // Only use valid/ready from the first core
    if (i == 0) begin
      assign core_in_ready = tmp_in_ready;
      assign core_out_valid = tmp_out_valid;
    end
  end
endgenerate

// ------------------------------------- Pixel output

// Join channels
assign out_pixel = {core_rgb_pixel_data[2], core_rgb_pixel_data[1], core_rgb_pixel_data[0]};

assign out_valid = core_out_valid;
assign core_out_ready = out_ready;

endmodule
