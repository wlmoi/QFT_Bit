// x_gate.v

// Note: This X-gate is implemented as a classical NOT for a single bit,
// representing a conceptual flip of a qubit's classical measurement outcome.
// For operations on complex quantum amplitudes, Pauli-X would be a matrix multiplication
// on a state vector (alpha, beta), resulting in (beta, alpha), which isn't modeled here
// for a single complex input/output.
`ifndef X_GATE_V
`define X_GATE_V

module x_gate(
    input wire q_in, // Single classical bit representing qubit state (0 or 1)
    output wire q_out // Flipped classical bit
);
    assign q_out = ~q_in;
endmodule
`endif // X_GATE_V
