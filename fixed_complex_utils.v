// fixed_complex_utils.v
`ifndef FIXED_COMPLEX_UTILS_V
`define FIXED_COMPLEX_UTILS_V

// Global Parameters for fixed-point representation S_3.4 (Signed, 3 Integer bits, 4 Fractional bits)
`define TOTAL_BITS 8  // Total width of the fixed-point number
`define FX_BITS 4     // Number of fractional bits
`define INT_BITS 3    // Number of integer value bits (excluding sign bit)

// Fixed-point number representation:
// Bit [`TOTAL_BITS-1`] is the sign bit.
// Bits [`TOTAL_BITS-2` : `FX_BITS`] are integer value bits.
// Bits [`FX_BITS-1` : 0] are fractional value bits.

// Complex number "irman" is `2 * `TOTAL_BITS` bits:
// [`2*`TOTAL_BITS-1` : `TOTAL_BITS`] for the real part
// [`TOTAL_BITS-1` : 0] for the imaginary part

// Module for fixed-point addition
module fixed_add(
    input signed [`TOTAL_BITS-1:0] a,
    input signed [`TOTAL_BITS-1:0] b,
    output signed [`TOTAL_BITS-1:0] sum
);
    assign sum = a + b;
endmodule

// Module for fixed-point subtraction
module fixed_sub(
    input signed [`TOTAL_BITS-1:0] a,
    input signed [`TOTAL_BITS-1:0] b,
    output signed [`TOTAL_BITS-1:0] diff
);
    assign diff = a - b;
endmodule

// Module for fixed-point multiplication
module fixed_mult(
    input signed [`TOTAL_BITS-1:0] a,
    input signed [`TOTAL_BITS-1:0] b,
    output signed [`TOTAL_BITS-1:0] product
);
    wire signed [(`TOTAL_BITS*2)-1:0] temp_product;
    assign temp_product = a * b;
    assign product = temp_product >>> `FX_BITS; // Right shift to get back to FX_BITS
endmodule

// Module for complex addition
module complex_add(
    input signed [`TOTAL_BITS*2-1:0] q1_in,
    input signed [`TOTAL_BITS*2-1:0] q2_in,
    output signed [`TOTAL_BITS*2-1:0] q_out
);
    wire signed [`TOTAL_BITS-1:0] q1_real = q1_in[`TOTAL_BITS*2-1:`TOTAL_BITS];
    wire signed [`TOTAL_BITS-1:0] q1_imag = q1_in[`TOTAL_BITS-1:0];
    wire signed [`TOTAL_BITS-1:0] q2_real = q2_in[`TOTAL_BITS*2-1:`TOTAL_BITS];
    wire signed [`TOTAL_BITS-1:0] q2_imag = q2_in[`TOTAL_BITS-1:0];

    wire signed [`TOTAL_BITS-1:0] out_real;
    wire signed [`TOTAL_BITS-1:0] out_imag;

    fixed_add add_real_inst (.a(q1_real), .b(q2_real), .sum(out_real));
    fixed_add add_imag_inst (.a(q1_imag), .b(q2_imag), .sum(out_imag));

    assign q_out = {out_real, out_imag};
endmodule

// Module for complex subtraction
module complex_sub(
    input signed [`TOTAL_BITS*2-1:0] q1_in,
    input signed [`TOTAL_BITS*2-1:0] q2_in,
    output signed [`TOTAL_BITS*2-1:0] q_out
);
    wire signed [`TOTAL_BITS-1:0] q1_real = q1_in[`TOTAL_BITS*2-1:`TOTAL_BITS];
    wire signed [`TOTAL_BITS-1:0] q1_imag = q1_in[`TOTAL_BITS-1:0];
    wire signed [`TOTAL_BITS-1:0] q2_real = q2_in[`TOTAL_BITS*2-1:`TOTAL_BITS];
    wire signed [`TOTAL_BITS-1:0] q2_imag = q2_in[`TOTAL_BITS-1:0];

    wire signed [`TOTAL_BITS-1:0] out_real;
    wire signed [`TOTAL_BITS-1:0] out_imag;

    fixed_sub sub_real_inst (.a(q1_real), .b(q2_real), .diff(out_real));
    fixed_sub sub_imag_inst (.a(q1_imag), .b(q2_imag), .diff(out_imag));

    assign q_out = {out_real, out_imag};
endmodule

// Module for complex multiplication
module complex_mult(
    input signed [`TOTAL_BITS*2-1:0] q1_in,
    input signed [`TOTAL_BITS*2-1:0] q2_in,
    output signed [`TOTAL_BITS*2-1:0] q_out
);
    wire signed [`TOTAL_BITS-1:0] a_real = q1_in[`TOTAL_BITS*2-1:`TOTAL_BITS];
    wire signed [`TOTAL_BITS-1:0] a_imag = q1_in[`TOTAL_BITS-1:0];
    wire signed [`TOTAL_BITS-1:0] b_real = q2_in[`TOTAL_BITS*2-1:`TOTAL_BITS];
    wire signed [`TOTAL_BITS-1:0] b_imag = q2_in[`TOTAL_BITS-1:0];

    wire signed [`TOTAL_BITS-1:0] ac, bd, ad, bc;

    fixed_mult mult_ac_inst (.a(a_real), .b(b_real), .product(ac));
    fixed_mult mult_bd_inst (.a(a_imag), .b(b_imag), .product(bd));
    fixed_mult mult_ad_inst (.a(a_real), .b(b_imag), .product(ad));
    fixed_mult mult_bc_inst (.a(a_imag), .b(b_real), .product(bc));

    wire signed [`TOTAL_BITS-1:0] out_real;
    wire signed [`TOTAL_BITS-1:0] out_imag;

    fixed_sub sub_real_part_inst (.a(ac), .b(bd), .diff(out_real));
    fixed_add add_imag_part_inst (.a(ad), .b(bc), .sum(out_imag));

    assign q_out = {out_real, out_imag};
endmodule

// Module for complex multiplication by a scalar (real number)
module complex_mult_scalar(
    input signed [`TOTAL_BITS*2-1:0] q_in,
    input signed [`TOTAL_BITS-1:0] scalar,
    output signed [`TOTAL_BITS*2-1:0] q_out
);
    wire signed [`TOTAL_BITS-1:0] a_real = q_in[`TOTAL_BITS*2-1:`TOTAL_BITS];
    wire signed [`TOTAL_BITS-1:0] a_imag = q_in[`TOTAL_BITS-1:0];

    wire signed [`TOTAL_BITS-1:0] out_real;
    wire signed [`TOTAL_BITS-1:0] out_imag;

    fixed_mult mult_real_part_inst (.a(a_real), .b(scalar), .product(out_real));
    fixed_mult mult_imag_part_inst (.a(a_imag), .b(scalar), .product(out_imag));

    assign q_out = {out_real, out_imag};
endmodule

`endif // FIXED_COMPLEX_UTILS_V
