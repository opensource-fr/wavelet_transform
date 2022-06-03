`default_nettype none
`define M_T 6.2831853071

// TODO: Hardcode for 8 bit input
// TODO: calculate max bits from actual fir values instead of max, this may not be possible without using sv, or python and hardcoding it. */
module fir #(
    parameter BITS_PER_ELEM = 8,
    parameter SUM_TRUNCATION = 8,
    parameter NUM_ELEM = 7,
    parameter FILTER_VAL = 0,
    parameter MAX_BITS = $clog2({BITS_PER_ELEM{1'b1}}*{BITS_PER_ELEM{1'b1}}*NUM_ELEM)
) (
    // Clock
    input wire clk,

    // Reset
    input wire rst,

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
  reg signed [MAX_BITS - 1:0] sum;
  reg signed [MAX_BITS - 1:0] working_sum;

  initial begin
    // Ricker Equation: r(τ)=(1−1/2 * ω^2 * τ^2)exp(−1/4* ω^2 * τ^2),
    // see python code for calculations
    filter = FILTER_VAL;
    sum = 0;
    working_sum = 0;
  end

  assign o_wavelet = sum[(MAX_BITS - 1): (MAX_BITS) - SUM_TRUNCATION]; // top 8 bits, (e.g. 31: 24 (32 - 8 = 24) )

  // While verilog 2005 doesn't support inline var
  reg [$clog2(NUM_ELEM) + 1:0] i;


  // we don't always want to have the sum be calculated for power reasons
  // (purpose of i_start_calc is to only perform calc when signalled) as
  // a result we keep the working_sum (register for making the sum) separate
  // from the register linked directly to the output (in this case this is
  // called "sum", and will maintian its value, only being updated if
  // i_start_calc is raised)
  always @(posedge clk) begin
    if (rst) begin
      // NOTE: parametric setting appears to require sv, so hardcoding with FILTER_VAL
      filter <= FILTER_VAL;
      sum <= 0;
      working_sum <= 0;
    end else begin
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
  end

endmodule
