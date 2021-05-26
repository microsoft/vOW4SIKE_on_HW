/* Released to the public domain */

/* 
 * Author:        Ruben Niederhagen <ruben@polycephaly.org>  
 * Abstract:      module for adding delay
 * 
*/

module delay
#(
  parameter WIDTH = 1,
  parameter DELAY = 1
)
(
  input  wire clk,
  input  wire rst,
  input  wire [WIDTH-1:0] din,
  output wire [WIDTH-1:0] dout
);


reg [WIDTH-1:0] level_buf [1:DELAY+1];

wire [WIDTH-1:0] level [0:DELAY];

assign level[0] = din;
 
genvar i;
generate
  for (i=0; i < DELAY; i=i+1)
    begin : gen_delay
      always @(posedge clk)
      begin
        if (rst) begin
          level_buf[i+1] <= {WIDTH{1'b0}};
        end
        else begin
          level_buf[i+1] <= level[i];
        end
      end

      assign level[i+1] = level_buf[i+1];
    end
endgenerate

assign dout = level[DELAY];

endmodule

