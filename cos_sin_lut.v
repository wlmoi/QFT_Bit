// cos_sin_lut.v
`ifndef COS_SIN_LUT_V
`define COS_SIN_LUT_V

`include "fixed_complex_utils.v"

module cos_sin_lut(
    input signed [`TOTAL_BITS-1:0] angle_in, 
    output signed [`TOTAL_BITS-1:0] cos_out,
    output signed [`TOTAL_BITS-1:0] sin_out
);
    // Function to calculate ceil(log2(value)) for LUT size.
    // Placed inside the module.
    function integer clogb2;
      input integer value;
      begin
        clogb2 = 0;
        while (value > 1) begin
          clogb2 = clogb2 + 1;
          value = value >> 1;
        end
      end
    endfunction

    parameter NUM_SEGMENTS = 8; // Number of segments in the LUT
    wire [clogb2(NUM_SEGMENTS)-1:0] lut_index; // 3 bits for 8 segments (e.g., [2:0])

    // Indexing the LUT: Use the most significant integer bits of the angle.
    // For S_3.4 (`TOTAL_BITS`=8, `FX_BITS`=4), the integer part is `angle_in[6:4]`.
    // clogb2(NUM_SEGMENTS) = clogb2(8) = 3. So, it takes 3 bits from index `TOTAL_BITS-2` down.
    assign lut_index = angle_in[`TOTAL_BITS-2 -: clogb2(NUM_SEGMENTS)]; 

    reg signed [`TOTAL_BITS-1:0] cos_table [0:NUM_SEGMENTS-1];
    reg signed [`TOTAL_BITS-1:0] sin_table [0:NUM_SEGMENTS-1];

    initial begin
        // Initialize LUT with precomputed values.
        // Values are (actual float value * 2^FX_BITS), then rounded.
        // Using FX_BITS = 4, so scaling factor is 16.
        cos_table[0] = `TOTAL_BITS'd16;   // cos(0) = 1.0   -> 1.0 * 16 = 16
        cos_table[1] = `TOTAL_BITS'd11;   // cos(pi/4) = 0.707 -> 0.707 * 16 = 11.312 -> 11
        cos_table[2] = `TOTAL_BITS'd0;    // cos(pi/2) = 0.0   -> 0.0 * 16 = 0
        cos_table[3] = -`TOTAL_BITS'd11;  // cos(3pi/4) = -0.707 -> -0.707 * 16 = -11
        cos_table[4] = -`TOTAL_BITS'd16;  // cos(pi) = -1.0   -> -1.0 * 16 = -16
        cos_table[5] = -`TOTAL_BITS'd11;  // cos(5pi/4) = -0.707 -> -0.707 * 16 = -11
        cos_table[6] = `TOTAL_BITS'd0;    // cos(3pi/2) = 0.0   -> 0.0 * 16 = 0
        cos_table[7] = `TOTAL_BITS'd11;   // cos(7pi/4) = 0.707 -> 0.707 * 16 = 11

        sin_table[0] = `TOTAL_BITS'd0;    // sin(0) = 0.0   -> 0.0 * 16 = 0
        sin_table[1] = `TOTAL_BITS'd11;   // sin(pi/4) = 0.707 -> 0.707 * 16 = 11
        sin_table[2] = `TOTAL_BITS'd16;   // sin(pi/2) = 1.0   -> 1.0 * 16 = 16
        sin_table[3] = `TOTAL_BITS'd11;   // sin(3pi/4) = 0.707 -> 0.707 * 16 = 11
        sin_table[4] = `TOTAL_BITS'd0;    // sin(pi) = 0.0   -> 0.0 * 16 = 0
        sin_table[5] = -`TOTAL_BITS'd11;  // sin(5pi/4) = -0.707 -> -0.707 * 16 = -11
        sin_table[6] = -`TOTAL_BITS'd16;  // sin(3pi/2) = -1.0   -> -1.0 * 16 = -16
        sin_table[7] = -`TOTAL_BITS'd11;  // sin(7pi/4) = -0.707 -> -0.707 * 16 = -11
    end

    assign cos_out = cos_table[lut_index];
    assign sin_out = sin_table[lut_index];

endmodule
`endif // COS_SIN_LUT_V
