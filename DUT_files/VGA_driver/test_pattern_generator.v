
module test_pattern_generator( clk,
										resetn,
										pixel_valid,
										pixel_ready,
										key,
										pixel_data);

input wire clk;
input wire resetn;							
output wire pixel_valid;
input wire  pixel_ready;
input wire key;
output reg [23:0]  pixel_data;
localparam VIDEO_W	= 640;
assign pixel_valid = key;
reg [11:0] counter_width;
always@(posedge clk, negedge resetn) begin
	if(!resetn) begin
		pixel_data <= 0;
		//pixel_valid <= 1'b0;
		counter_width <= 0;
	end else begin
			//pixel_valid <= 1'b1;
			if(pixel_ready) begin
				if ( counter_width <= VIDEO_W/3)
					pixel_data <= {8'hf0, 8'ha0, 8'h0f}; // blue
				else if (counter_width > VIDEO_W/3 && counter_width <= VIDEO_W*2/3)
					pixel_data <= {8'h00,8'hff, 8'ha0};  // green
				else if(counter_width > VIDEO_W*2/3 && counter_width <=VIDEO_W)
					pixel_data <= {8'hff, 8'hff, 8'hff}; // red
				else pixel_data <= 24'h0000; 
				
				if(counter_width <  VIDEO_W -1) begin
					counter_width <= counter_width + 1;
				end else begin
						counter_width <= 0;
					end
				
			 end
	 end
	
end




endmodule						
