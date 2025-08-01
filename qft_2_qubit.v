// qft_2_qubit.v
`ifndef QFT_2_QUBIT_V
`define QFT_2_QUBIT_V

`include "fixed_complex_utils.v"
`include "cos_sin_lut.v" // For phase rotation values

module qft_2_qubit(
    // Input is the 2-qubit state vector (4 complex amplitudes)
    // Each complex amplitude is (`TOTAL_BITS*2`) bits (e.g., 16 bits for S_3.4 real/imaginary parts)
    // q_state_in[`TOTAL_BITS*8-1`:`TOTAL_BITS*6`] represents the complex amplitude for state |00>
    // q_state_in[`TOTAL_BITS*6-1`:`TOTAL_BITS*4`] represents the complex amplitude for state |01>
    // q_state_in[`TOTAL_BITS*4-1`:`TOTAL_BITS*2`] represents the complex amplitude for state |10>
    // q_state_in[`TOTAL_BITS*2-1` : 0]  represents the complex amplitude for state |11>
    input signed [`TOTAL_BITS*8-1:0] q_state_in,
    output signed [`TOTAL_BITS*8-1:0] q_state_out
);
    // Extract individual complex amplitudes for states |00>, |01>, |10>, |11>
    wire signed [`TOTAL_BITS*2-1:0] amp_00_in = q_state_in[`TOTAL_BITS*8-1:`TOTAL_BITS*6];
    wire signed [`TOTAL_BITS*2-1:0] amp_01_in = q_state_in[`TOTAL_BITS*6-1:`TOTAL_BITS*4];
    wire signed [`TOTAL_BITS*2-1:0] amp_10_in = q_state_in[`TOTAL_BITS*4-1:`TOTAL_BITS*2];
    wire signed [`TOTAL_BITS*2-1:0] amp_11_in = q_state_in[`TOTAL_BITS*2-1:0];

    // Constant for 1/sqrt(2) in fixed-point (0.707 * 2^FX_BITS = 11.312, rounded to 11)
    // Use `TOTAL_BITS`'d syntax for type compatibility with parameters
    parameter signed [`TOTAL_BITS-1:0] ONE_OVER_SQRT2 = `TOTAL_BITS'd11; 
    
    // Constant for pi/2 in fixed-point (1.5708 * 2^FX_BITS = 25.1328, rounded to 25)
    parameter signed [`TOTAL_BITS-1:0] PI_OVER_2_FX = `TOTAL_BITS'd25; 

    // Intermediate states/amplitudes
    wire signed [`TOTAL_BITS*2-1:0] temp_sum_00_10, temp_sum_01_11, temp_diff_00_10, temp_diff_01_11;
    wire signed [`TOTAL_BITS*2-1:0] amp_00_h0, amp_01_h0, amp_10_h0, amp_11_h0;

    // --- Stage 1: Hadamard on Qubit 0 (MSB) ---
    // H_0 transforms state amplitudes:
    // New |00> = (amp_00 + amp_10) / sqrt(2)
    // New |01> = (amp_01 + amp_11) / sqrt(2)
    // New |10> = (amp_00 - amp_10) / sqrt(2)
    // New |11> = (amp_01 - amp_11) / sqrt(2)

    complex_add add_00_10_inst (.q1_in(amp_00_in), .q2_in(amp_10_in), .q_out(temp_sum_00_10));
    complex_add add_01_11_inst (.q1_in(amp_01_in), .q2_in(amp_11_in), .q_out(temp_sum_01_11));
    complex_sub sub_00_10_inst (.q1_in(amp_00_in), .q2_in(amp_10_in), .q_out(temp_diff_00_10));
    complex_sub sub_01_11_inst (.q1_in(amp_01_in), .q2_in(amp_11_in), .q_out(temp_diff_01_11));

    complex_mult_scalar scale_00_h0_inst (.q_in(temp_sum_00_10),  .scalar(ONE_OVER_SQRT2), .q_out(amp_00_h0));
    complex_mult_scalar scale_01_h0_inst (.q_in(temp_sum_01_11),  .scalar(ONE_OVER_SQRT2), .q_out(amp_01_h0));
    complex_mult_scalar scale_10_h0_inst (.q_in(temp_diff_00_10), .scalar(ONE_OVER_SQRT2), .q_out(amp_10_h0));
    complex_mult_scalar scale_11_h0_inst (.q_in(temp_diff_01_11), .scalar(ONE_OVER_SQRT2), .q_out(amp_11_h0));

    // --- Stage 2: Controlled Phase Gate (Control Q0, Target Q1) with angle PI/2 ---
    // CPHASE (q0, q1) affects only the |11> state amplitude (i.e., when Q0 is 1 and Q1 is 1).
    // The matrix for CPHASE(theta) is diagonal for states |00>, |01>, |10>, |11>
    // only applying e^(i*theta) to the |11> element.

    wire signed [`TOTAL_BITS-1:0] cos_val_cphase, sin_val_cphase;
    cos_sin_lut cphase_pi2_lut (.angle_in(PI_OVER_2_FX), .cos_out(cos_val_cphase), .sin_out(sin_val_cphase));
    wire signed [`TOTAL_BITS*2-1:0] phase_factor_cphase = {cos_val_cphase, sin_val_cphase}; // e^(i*PI/2)

    wire signed [`TOTAL_BITS*2-1:0] amp_11_cphase_res;
    complex_mult mult_11_phase_inst (.q1_in(amp_11_h0), .q2_in(phase_factor_cphase), .q_out(amp_11_cphase_res));

    // Amplitudes after CPHASE
    wire signed [`TOTAL_BITS*2-1:0] amp_00_cphase = amp_00_h0;
    wire signed [`TOTAL_BITS*2-1:0] amp_01_cphase = amp_01_h0;
    wire signed [`TOTAL_BITS*2-1:0] amp_10_cphase = amp_10_h0;

    // --- Stage 3: Swap Qubits (Q0 and Q1) ---
    // QFT output typically has qubits in reverse order. If input is |q1 q0>, output is |q0 q1>.
    // This means original |00> stays |00>, |01> becomes |10>, |10> becomes |01>, |11> stays |11>.
    // So, we map the amplitudes based on their state labels:
    // Final amplitude for |00> is from old |00>
    // Final amplitude for |01> is from old |10>
    // Final amplitude for |10> is from old |01>
    // Final amplitude for |11> is from old |11>

    assign q_state_out = {amp_00_cphase, amp_10_cphase, amp_01_cphase, amp_11_cphase_res}; 

endmodule
`endif // QFT_2_QUBIT_V
