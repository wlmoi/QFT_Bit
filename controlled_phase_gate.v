// controlled_phase_gate.v

// Parameters for fixed-point representation
`include "fixed_complex_utils.v"
`include "cos_sin_lut.v" // Include for cos/sin values

module controlled_phase_gate(
    input signed [`TOTAL_BITS*2-1:0] control_q_in, // Control qubit (complex amplitude)
    input signed [`TOTAL_BITS*2-1:0] target_q_in,  // Target qubit (complex amplitude)
    input signed [`TOTAL_BITS-1:0] theta_angle,   // Phase angle (fixed-point radians)
    output signed [`TOTAL_BITS*2-1:0] control_q_out,
    output signed [`TOTAL_BITS*2-1:0] target_q_out
);
    // A controlled-phase gate applies a phase shift e^(i*theta) to the target qubit
    // if the control qubit is in the |1> state.
    // If the control qubit is |0>, the target qubit is unchanged.
    // This implies we need to check the state of the control qubit.

    // In a general quantum circuit, qubits are in superposition.
    // The control qubit's state needs to be extracted.
    // For this, we conceptually look at the probability of the control qubit being |1>.
    // This is usually handled at a higher level (e.g., in a simulation framework that evolves states).

    // For a synthesizable gate level:
    // The CPHASE gate applies a rotation matrix [[1,0,0,0],[0,1,0,0],[0,0,1,0],[0,0,0,e^(i*theta)]]
    // to the joint state of two qubits |q_control q_target>.
    // So, input must be the joint state {alpha_00, alpha_01, alpha_10, alpha_11}
    // where each is a complex number.

    // Given `control_q_in` and `target_q_in` are individual complex amplitudes (16-bit `irman` each),
    // we cannot directly apply the 4x4 matrix for joint state.
    // This implies a conceptual application: if control is 'logically 1', apply phase to target.
    // The "control" here needs to be a classical signal derived from the control qubit's classical state (e.g., measurement result).

    // Let's assume a simplified interpretation: the gate is 'controlled' by a classical signal `control_signal`.
    // If `control_signal` is 1, apply phase. If 0, pass target_q_in directly.

    logic control_signal;
    // How do we get control_signal from `control_q_in` (a complex number)?
    // Usually, control is |1> state.
    // This is where quantum mechanics meets classical control.
    // For a true controlled operation, you'd need the probability of control_q_in being |1>.
    // Simplified: a threshold on the magnitude of the control_q_in if it represents |1> amplitude.
    // Or, more commonly in pedagogical circuits, control is a *classical wire* or another qubit's definite state.

    // Let's assume `control_q_in` is actually just a single bit to enable the control.
    // **Revised Input**: `control_bit` instead of `control_q_in` complex.
    input logic control_bit; // Classical control signal (0 or 1)
    input signed [`TOTAL_BITS*2-1:0] target_q_amplitude_in; // Target qubit's complex amplitude
    output signed [`TOTAL_BITS*2-1:0] target_q_amplitude_out;

    wire signed [`TOTAL_BITS-1:0] cos_val, sin_val;
    cos_sin_lut phase_lut (.angle_in(theta_angle), .cos_out(cos_val), .sin_out(sin_val));

    wire signed [`TOTAL_BITS*2-1:0] phase_factor; // e^(i*theta) = cos(theta) + i*sin(theta)
    assign phase_factor = {cos_val, sin_val};

    wire signed [`TOTAL_BITS*2-1:0] multiplied_target;
    complex_mult mult_target_phase (.q1_in(target_q_amplitude_in), .q2_in(phase_factor), .q_out(multiplied_target));

    // If control_bit is high, apply phase; else, pass through original target amplitude
    assign target_q_amplitude_out = control_bit ? multiplied_target : target_q_amplitude_in;
    assign control_q_out = control_q_in; // Control qubit is unchanged in CPHASE

endmodule
