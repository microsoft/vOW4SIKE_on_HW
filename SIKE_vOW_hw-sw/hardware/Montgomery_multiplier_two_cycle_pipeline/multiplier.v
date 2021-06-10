
(* use_dsp = "yes" *) module multiplier
#(
    parameter WIDTH_IN = 64 
  )
 (
  input  wire                   clk,
  input  wire  [WIDTH_IN-1:0]   a,
  input  wire  [WIDTH_IN-1:0]   b,
  output wire  [2*WIDTH_IN-1:0] p
  );
 

 assign p = a*b;
 

endmodule // multiplier