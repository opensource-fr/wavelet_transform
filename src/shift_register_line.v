`default_nettype none

module shift_register_line #(
    parameter TOTAL_TAPS = 9,
    parameter BITS_PER_TAP = 8,
    parameter TOTAL_BITS = 9 * 8
) (
    // Clock
    input wire clk,

    // Inputs Streaming
    input wire signed [BITS_PER_TAP - 1:0] i_value,

    // clock in the data
    input wire i_data_clk,

    // signal to fir's, data is ready to start calculation
    output wire o_start_calc,

    // TAPS
    output reg [TOTAL_BITS - 1:0] o_taps
);

  reg stb;
  reg start_calc;
  reg data_clk_previous;

  initial begin
    o_taps = 0;
    stb = 0;
    start_calc = 0;
  data_clk_previous = 0;
  end

  always @(posedge clk) begin
    o_taps <= o_taps;
    start_calc <= 0;
    if (i_data_clk & ~data_clk_previous) begin //rising edge of i_data_clk
        o_taps <= {o_taps[((TOTAL_BITS-1)-BITS_PER_TAP):0], i_value};
        start_calc <= 1;
    end

  end

  assign o_start_calc = start_calc;

endmodule
