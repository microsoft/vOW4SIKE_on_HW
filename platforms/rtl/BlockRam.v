
module BlockRam
#(
  parameter DATA_WIDTH = 10,
  parameter ADDR_WIDTH = 8
)
(
  input  wire                  clk,
  input  wire [DATA_WIDTH-1:0] din,
  input  wire [ADDR_WIDTH-1:0] addr,
  input  wire                  we,
  output reg  [DATA_WIDTH-1:0] dout
);

  localparam SIZE = 2**ADDR_WIDTH;

  reg [DATA_WIDTH-1:0] mem [0:SIZE-1];

  always @ (posedge clk)
  begin
    if (we)
      mem[addr] <= din;
  end

  always @ (posedge clk)
  begin
    dout <= mem[addr];
  end

endmodule

