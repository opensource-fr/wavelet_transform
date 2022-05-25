`default_nettype none
`define M_T 6.2831853071

module fir #(
    parameter BITS_PER_ELEM = 8,
    parameter NUM_ELEM = 7,
    parameter CENTER_FREQ = 1
) (
    // Clock
    input wire i_clk,

    // TAPS
    input wire [NUM_ELEM * BITS_PER_ELEM - 1:0] taps

);
//TODO: -1: -8 out of range

  reg [NUM_ELEM * BITS_PER_ELEM - 1:0] filter;
  reg [$clog2({BITS_PER_ELEM{1'b1}}*NUM_ELEM):0] sum;

  // verilator lint_off UNUSED
  function [7:0] trunc_32_to_8(input [31:0] int_32);
    trunc_32_to_8 = int_32[7:0];
  endfunction
  // verilator lint_on UNUSED

  // While Verilog 2005 doesn't support inline var
  reg [$clog2(NUM_ELEM) + 1:0] j;
  reg [$clog2(NUM_ELEM) + 1:0] i;
  initial begin
    filter[BITS_PER_ELEM*(NUM_ELEM/2)+:BITS_PER_ELEM] =
        trunc_32_to_8($rtoi({BITS_PER_ELEM{1'b1}} / 2));
    // This section calculates wavelet coefficients for the filter bank
    // Ricker Equation: r(τ)=(1−1/2 * ω^2 * τ^2)exp(−1/4* ω^2 * τ^2),
    // verilator lint_off WIDTH
    //
    //if odd, set the center value to be one times scaling factor, then
    //truncated to 8 bits
    if (NUM_ELEM % 2 == 1) begin
      filter[NUM_ELEM/2] = trunc_32_to_8({BITS_PER_ELEM{1'b1}} / 2);
    end

    for (j = 1; j < (NUM_ELEM / 2 + 1); j = j + 1) begin
      filter[BITS_PER_ELEM*((NUM_ELEM/2)+j)+:BITS_PER_ELEM] = trunc_32_to_8(
          $rtoi(
              {BITS_PER_ELEM{1'b1}} / 2 * (1.0 - 0.5 * $pow(
                  `M_T * CENTER_FREQ, 2
              ) * $pow(
                  j * (1.0 / CENTER_FREQ) / (NUM_ELEM / 2 + 1.0), 2
              )) * $exp(
                  -0.25 * $pow(`M_T * CENTER_FREQ, 2) * $pow(j * (1.0/CENTER_FREQ) / (NUM_ELEM / 2 + 1.0), 2)
              )
          )
      );
      filter[BITS_PER_ELEM*((NUM_ELEM/2)-j)+:BITS_PER_ELEM] = filter[BITS_PER_ELEM*((NUM_ELEM/2)+j)+:BITS_PER_ELEM];
    // verilator lint_on WIDTH
    end
    sum = 0;
  end

  always @(posedge i_clk) begin
    // verilator lint_off BLKSEQ
    // verilator lint_off WIDTH
    sum = 0;
    for (i = 0; i < NUM_ELEM; i = i + 1) begin
      sum = sum + filter[BITS_PER_ELEM*i+:BITS_PER_ELEM] * taps[BITS_PER_ELEM*i+:BITS_PER_ELEM];
    end
    // verilator lint_on BLKSEQ
    // verilator lint_on WIDTH
  end

endmodule
