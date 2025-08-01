// exp_lut_8_segment.v
`ifndef EXP_LUT_8_SEGMENT_V
`define EXP_LUT_8_SEGMENT_V

`include "fixed_complex_utils.v"

module exp_lut_8_segment(
    input signed [`TOTAL_BITS-1:0] x_in, // Fixed-point input for x
    output signed [`TOTAL_BITS-1:0] exp_x_out // Fixed-point output for e^x
);

    reg signed [`TOTAL_BITS-1:0] lut_data [0:7]; // 8 segments

    initial begin
        // Values are precomputed e^x * 2^FX_BITS. For S_3.4 (FX_BITS=4), scaling factor is 16.
        // `TOTAL_BITS'h3F` (63 in decimal) is the maximum positive value in S_3.4 fixed-point (3.9375).
        lut_data[0] = `TOTAL_BITS'd16;   // e^0.0 = 1.0   -> 1.0 * 16 = 16
        lut_data[1] = `TOTAL_BITS'd20;   // e^0.25 is ~1.284 -> 1.284 * 16 = 20.544 -> 20
        lut_data[2] = `TOTAL_BITS'd26;   // e^0.5 is ~1.648 -> 1.648 * 16 = 26
        lut_data[3] = `TOTAL_BITS'd34;   // e^0.75 is ~2.117 -> 2.117 * 16 = 34
        lut_data[4] = `TOTAL_BITS'd44;   // e^1.0 is ~2.718 -> 2.718 * 16 = 44
        lut_data[5] = `TOTAL_BITS'd56;   // e^1.25 is ~3.490 -> 3.490 * 16 = 56
        lut_data[6] = `TOTAL_BITS'h3F;   // e^1.5 is ~4.48, which saturates to 3.9375 (max positive)
        lut_data[7] = `TOTAL_BITS'h3F;   // e^1.75 is ~5.75, which saturates to 3.9375 (max positive)
    end

    wire [2:0] lut_index; // 3 bits for 8 segments (derived from integer part of x_in)
    // For S_3.4, this is x_in[6:4].
    assign lut_index = x_in[`TOTAL_BITS-2 -: 3]; 

    // Handle negative x_in (sign bit is `TOTAL_BITS-1`).
    // Based on previous discussion, `0.0` (represented as `TOTAL_BITS'h00`) is used for negative inputs.
    assign exp_x_out = (x_in[`TOTAL_BITS-1] == 1) ? `TOTAL_BITS'h00 : lut_data[lut_index];

endmodule
`endif // EXP_LUT_8_SEGMENT_V
