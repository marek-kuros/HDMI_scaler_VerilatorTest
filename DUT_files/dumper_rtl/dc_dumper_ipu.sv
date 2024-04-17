//dc_dumper_ipu module is not synthesizable rtl component use to fetch all values of pixels sent from image processing unit to vga driver and saved them in .ppm image file



module dc_dumper_ipu #(
   parameter  IMG_WIDTH =              8, //width of image
              IMG_HEIGHT =             8 //height of image
) (
  clk,
  nrst,
  pixel_valid,
  pixel_ready,
  pixel_data
);
import scaler_tb_pkg::*;
localparam pixel_data_lenght = 24; //width of pixel data bus

input wire clk;
input wire nrst;

//ipu handshaking signals
input wire pixel_valid;
input wire pixel_ready;
input wire [pixel_data_lenght -1 :0] pixel_data;


Dumper_img d1; //create object of Dumper_img class

localparam color_length = 8 ; //8 pixels for each color
int unsigned counter_img_nr = 1; //counter which image is saving

string filename = "dumper_ipu_img_" ;
string counter_img_nr_str ; //counter to enumerate each frame

int unsigned counter;
bit [color_length -1:0] pixel_arr [IMG_HEIGHT][IMG_WIDTH][3]; //fixed array with pixels values



bit [7:0] d_array [][][]; //dynamic array

initial begin //constructor of Dumper_img class
d1 = new();
end

always_ff @( posedge clk or negedge nrst ) begin : dump_pixel
  if(!nrst) begin
    counter = 0;    
  end
  else begin
    if(pixel_valid & pixel_ready) begin
      if(counter < (IMG_HEIGHT * IMG_WIDTH)) begin
        pixel_arr[counter / IMG_WIDTH][counter - IMG_WIDTH*(counter / IMG_WIDTH)][0] = pixel_data[color_length - 1:0]; //r
        pixel_arr[counter / IMG_WIDTH][counter - IMG_WIDTH*(counter / IMG_WIDTH)][1] = pixel_data[ (2*color_length) -1:color_length]; //g
        pixel_arr[counter / IMG_WIDTH][counter - IMG_WIDTH*(counter / IMG_WIDTH)][2] = pixel_data[(3*color_length)-1:(2*color_length)]; //b
        counter = counter + 1; //incr counter
        if (counter == (IMG_WIDTH*IMG_HEIGHT) ) begin //save image to file
          counter = 0;
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
end



endmodule