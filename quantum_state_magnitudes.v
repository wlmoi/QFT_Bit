// quantum_state_magnitudes.v
`ifndef QUANTUM_STATE_MAGNITUDES_V
`define QUANTUM_STATE_MAGNITUDES_V

`include "fixed_complex_utils.v" // Contains global `define for TOTAL_BITS, FX_BITS

module quantum_state_magnitudes(
    // Input is the 2-qubit state vector (4 complex amplitudes)
    input signed [`TOTAL_BITS*8-1:0] q_state_in,
    // Output are the magnitude squared values for each state.
    // Each magnitude squared is a real fixed-point number, `TOTAL_BITS` bits wide.
    // Magnitude squared = real_part^2 + imag_part^2
    output signed [`TOTAL_BITS*4-1:0] mag_sq_out // {mag_sq_00, mag_sq_01, mag_sq_10, mag_sq_11}
);
    // Use localparam to ensure consistent bit width inside this module,
    // explicitly referencing the global macros.
    localparam LOCAL_TOTAL_BITS = `TOTAL_BITS;
    localparam LOCAL_FX_BITS = `FX_BITS;

    // Extract individual complex amplitudes for states |00>, |01>, |10>, |11>
    wire signed [LOCAL_TOTAL_BITS*2-1:0] amp_00 = q_state_in[LOCAL_TOTAL_BITS*8-1:LOCAL_TOTAL_BITS*6];
    wire signed [LOCAL_TOTAL_BITS*2-1:0] amp_01 = q_state_in[LOCAL_TOTAL_BITS*6-1:LOCAL_TOTAL_BITS*4];
    wire signed [LOCAL_TOTAL_BITS*2-1:0] amp_10 = q_state_in[LOCAL_TOTAL_BITS*4-1:LOCAL_TOTAL_BITS*2];
    wire signed [LOCAL_TOTAL_BITS*2-1:0] amp_11 = q_state_in[LOCAL_TOTAL_BITS*2-1:0];

    // Internal wires for real and imaginary parts
    wire signed [LOCAL_TOTAL_BITS-1:0] r_00, i_00;
    wire signed [LOCAL_TOTAL_BITS-1:0] r_01, i_01;
    wire signed [LOCAL_TOTAL_BITS-1:0] r_10, i_10;
    wire signed [LOCAL_TOTAL_BITS-1:0] r_11, i_11;

    assign r_00 = amp_00[LOCAL_TOTAL_BITS*2-1:LOCAL_TOTAL_BITS];
    assign i_00 = amp_00[LOCAL_TOTAL_BITS-1:0];
    assign r_01 = amp_01[LOCAL_TOTAL_BITS*2-1:LOCAL_TOTAL_BITS];
    assign i_01 = amp_01[LOCAL_TOTAL_BITS-1:0];
    assign r_10 = amp_10[LOCAL_TOTAL_BITS*2-1:LOCAL_TOTAL_BITS];
    assign i_10 = amp_10[LOCAL_TOTAL_BITS-1:0];
    assign r_11 = amp_11[LOCAL_TOTAL_BITS*2-1:LOCAL_TOTAL_BITS];
    assign i_11 = amp_11[LOCAL_TOTAL_BITS-1:0];

    // Wires for squared real and imaginary parts
    // These outputs come from fixed_mult, which produces LOCAL_TOTAL_BITS wide output.
    wire signed [LOCAL_TOTAL_BITS-1:0] r_sq_00, i_sq_00;
    wire signed [LOCAL_TOTAL_BITS-1:0] r_sq_01, i_sq_01;
    wire signed [LOCAL_TOTAL_BITS-1:0] r_sq_10, i_sq_10;
    wire signed [LOCAL_TOTAL_BITS-1:0] r_sq_11, i_sq_11;

    // Wires for final magnitude squared sums
    // fixed_add also expects LOCAL_TOTAL_BITS inputs.
    wire signed [LOCAL_TOTAL_BITS-1:0] mag_sq_00_w;
    wire signed [LOCAL_TOTAL_BITS-1:0] mag_sq_01_w;
    wire signed [LOCAL_TOTAL_BITS-1:0] mag_sq_10_w;
    wire signed [LOCAL_TOTAL_BITS-1:0] mag_sq_11_w;


    // Calculate magnitude squared for |00>
    fixed_mult r_00_sq_inst (.a(r_00), .b(r_00), .product(r_sq_00));
    fixed_mult i_00_sq_inst (.a(i_00), .b(i_00), .product(i_sq_00));
    fixed_add sum_00_sq_inst (.a(r_sq_00), .b(i_sq_00), .sum(mag_sq_00_w));

    // Calculate magnitude squared for |01>
    fixed_mult r_01_sq_inst (.a(r_01), .b(r_01), .product(r_sq_01));
    fixed_mult i_01_sq_inst (.a(i_01), .b(i_01), .product(i_sq_01));
    fixed_add sum_01_sq_inst (.a(r_sq_01), .b(i_sq_01), .sum(mag_sq_01_w));

    // Calculate magnitude squared for |10>
    fixed_mult r_10_sq_inst (.a(r_10), .b(r_10), .product(r_sq_10));
    fixed_mult i_10_sq_inst (.a(i_10), .b(i_10), .product(i_sq_10));
    fixed_add sum_10_sq_inst (.a(r_10_sq), .b(i_10_sq), .sum(mag_sq_10_w));

    // Calculate magnitude squared for |11>
    fixed_mult r_11_sq_inst (.a(r_11), .b(r_11), .product(r_sq_11));
    fixed_mult i_11_sq_inst (.a(i_11), .b(i_11), .product(i_sq_11));
    fixed_add sum_11_sq_inst (.a(r_11_sq), .b(i_11_sq), .sum(mag_sq_11_w));

    // Concatenate all magnitude squared outputs
    assign mag_sq_out = {mag_sq_00_w, mag_sq_01_w, mag_sq_10_w, mag_sq_11_w};

endmodule
`endif // QUANTUM_STATE_MAGNITUDES_V
