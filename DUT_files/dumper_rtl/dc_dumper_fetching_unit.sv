//RTL version of dumper. Use only in simulation.
//This dumper listens fetching unit ports (fetching unit <-> control logic and fetching unit <-> buffering unit) and store each pixel in array respectively
//When  store all pixels  then array is save to file (by Dumper_img class)


module dc_dumper_fetching_unit #(
  parameter IMG_WIDTH =              8, //width of image
            IMG_HEIGHT =             8, //height of image
            LINE_NUMBER_WIDTH  =     8 //length of line number bus
) (
  clk,
  nrst,
  line_number,
  line_data_valid,
  line_data_ready,
  pixel_data,
  pixel_fifo_en
);

import scaler_tb_pkg::*; //to use Dumper_img class
localparam pixel_data_lenght = 24;

//global control and clock signals
  input wire                                    clk;
  input wire                                    nrst;
  //
//fetching unit control signals
  input wire[(LINE_NUMBER_WIDTH-1):0]           line_number; //signal inform which line of image will be fetching 
  input wire                                    line_data_valid; //handshaking
  input wire                                    line_data_ready; //handshaking
//fetching unit output pixel
  input wire [pixel_data_lenght -1:0]           pixel_data; // r,g,b - each 8 bit color 3*8 == 24
  input wire                                    pixel_fifo_en;  //if assert -> start send pixel value from handshaked line_number


Dumper_img d1; //create object of Dumper_img class

int unsigned line_number_int; //currently line of image stored
int unsigned counter; //counter of pixel in row
int unsigned counter_img_nr = 1; //counter which image is saving

string filename = "dumper_fetching_unit_img_" ;
string counter_img_nr_str ;
localparam color_length = 8 ; // number of bits in each color
bit [color_length -1:0] pixel_arr [IMG_HEIGHT][IMG_WIDTH][3]; //fixed array with pixels values

bit fetching_pixel_en ; //data are stored to array

bit [7:0] d_array [][][]; //dynamic array witch is need to Dumper_img class

initial begin //create object class --> constructor
  d1 = new();
end


always_ff @( posedge clk or negedge nrst ) begin : fetching_unit
  if(!nrst) begin
    line_number_int = 0;
    counter = 0;
    fetching_pixel_en = 1'b0;
  end
  else
    if(line_data_ready & line_data_valid) //handshaking
      line_number_int = line_number;

    if (pixel_fifo_en) begin
      pixel_arr[line_number_int][counter][0] = pixel_data[color_length - 1:0];
      pixel_arr[line_number_int][counter][1] = pixel_data[ (2*color_length) -1:color_length];
      pixel_arr[line_number_int][counter][2] = pixel_data[(3*color_length)-1:(2*color_length)];

      counter = counter + 1; //incr counter
      

      if (counter == IMG_WIDTH) begin //end of pixel in row
        counter = 0;
        if(line_number_int == IMG_HEIGHT -1 ) begin
          //changing static array to dynamic
          d_array = new[IMG_HEIGHT];  //  <x> - type number of rows
        
          foreach(d_array[i]) begin 
            d_array[i] = new[IMG_WIDTH];  // <y> - type number of columns
            foreach(d_array[i,j]) begin 
              d_array[i][j] = new[3]; //fixed 3 colors not change
            end 
          end 


          foreach(d_array[i,j,k]) begin
            d_array[i][j][k] = pixel_arr[i][j][k]; 
          end
          counter_img_nr_str.itoa(counter_img_nr);
          d1.save_image_to_file(IMG_WIDTH,IMG_HEIGHT,color_length,d_array , {filename,counter_img_nr_str});
          counter_img_nr = counter_img_nr +1;
        end
      end


    end 
    
end




  
endmodule