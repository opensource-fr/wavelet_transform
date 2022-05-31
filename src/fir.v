`default_nettype none
`define M_T 6.2831853071

// TODO: Assume SUM_TRUNCATION of 8 for now, but make this a parameter later
module fir #(
    parameter BITS_PER_ELEM = 8,
    parameter NUM_ELEM = 7,
    parameter CENTER_FREQ = 1,
    parameter SUM_TRUNCATION = 8
) (
    // Clock
    input wire clk,

    // signal to clock in data from inputs
    input wire i_start_calc,

    // TAPS
    input wire [NUM_ELEM * BITS_PER_ELEM - 1:0] taps,

    // Outputs
    //TODO: refactor output from int32 to only allocate number of bits that will be used
    /* output wire [$clog2({BITS_PER_ELEM{1'b1}}*NUM_ELEM):0] output_sum */
    output wire signed [SUM_TRUNCATION - 1:0] o_wavelet

);

  reg [NUM_ELEM * BITS_PER_ELEM - 1:0] filter;
  //TODO: refactor output from int32 to only allocate number of bits that will be used

  // Find number of bits for full range
  /* reg [$clog2({BITS_PER_ELEM{1'b1}}*NUM_ELEM):0] ; */
  /* reg signed [$clog2({BITS_PER_ELEM{1'b1}}*NUM_ELEM):0] sum; */
  // register for number of bits to right shift
  // max possible product + max possible product ... for every element (i.e.
  // NUM_ELEM times)
  // TODO: calculate max bits from actual fir values instead of max, this may not be possible without using sv, or python and hardcoding it.
  localparam MAX_BITS = $clog2({BITS_PER_ELEM{1'b1}}*{BITS_PER_ELEM{1'b1}}*NUM_ELEM);

  reg signed [MAX_BITS - 1:0] sum;
  reg signed [MAX_BITS - 1:0] working_sum;
  /* reg signed [31:0] sum; */
  /* reg signed [31:0] working_sum; */

  function [7:0] trunc_32_to_8(input [31:0] int_32);
    trunc_32_to_8 = int_32[7:0];
  endfunction

  // While Verilog 2005 doesn't support inline var
  reg [$clog2(NUM_ELEM) + 1:0] j;
  reg [$clog2(NUM_ELEM) + 1:0] i;
  initial begin
    filter[BITS_PER_ELEM*(NUM_ELEM/2)+:BITS_PER_ELEM] =
        trunc_32_to_8($rtoi({BITS_PER_ELEM{1'b1}} / 2));
    // This section calculates wavelet coefficients for the filter bank
    // Ricker Equation: r(τ)=(1−1/2 * ω^2 * τ^2)exp(−1/4* ω^2 * τ^2),
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
    end
    sum = 0;
    working_sum = 0;
  end

  assign o_wavelet = sum[(MAX_BITS - 1): (MAX_BITS) - SUM_TRUNCATION]; // top 8 bits, (e.g. 31: 24 (32 - 8 = 24) )

  // we don't always want to have the sum be calculated for power reasons
  // (purpose of i_start_calc is to only perform calc when signalled) as
  // a result we keep the working_sum (register for making the sum) separate
  // from the register linked directly to the output (in this case this is
  // called "sum", and will maintian its value, only being updated if
  // i_start_calc is raised)
  always @(posedge clk) begin
    if (i_start_calc) begin
      working_sum = 0;
      for (i = 0; i < NUM_ELEM; i = i + 1) begin
        working_sum = working_sum + $signed(filter[BITS_PER_ELEM*i+:BITS_PER_ELEM]) * $signed(taps[BITS_PER_ELEM*i+:BITS_PER_ELEM]);
      end
      sum <= working_sum;
    end
    else begin
      sum <= sum;
    end
  end

endmodule
