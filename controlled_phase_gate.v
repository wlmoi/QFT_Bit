// controlled_phase_gate.v

// Parameters for fixed-point representation
`include "fixed_complex_utils.v"
`include "cos_sin_lut.v" // Include for cos/sin values

// --- Perbaikan Utama: Semua port dideklarasikan dalam daftar formal modul ---
module controlled_phase_gate(
    input signed [`TOTAL_BITS*2-1:0] control_q_in,        // Control qubit (complex amplitude)
    input signed [`TOTAL_BITS*2-1:0] target_q_in,         // Target qubit (complex amplitude)
    input signed [`TOTAL_BITS-1:0] theta_angle,           // Phase angle (fixed-point radians)
    output signed [`TOTAL_BITS*2-1:0] control_q_out,
    output signed [`TOTAL_BITS*2-1:0] target_q_out,
    
    // --- Port-port tambahan yang sebelumnya di dalam badan modul, sekarang dipindahkan ke sini ---
    input wire control_bit,                               // Classical control signal (0 or 1)
    input signed [`TOTAL_BITS*2-1:0] target_q_amplitude_in, // Target qubit's complex amplitude
    output signed [`TOTAL_BITS*2-1:0] target_q_amplitude_out // Output phase-shifted target
);

    wire signed [`TOTAL_BITS-1:0] cos_val, sin_val;
    cos_sin_lut phase_lut (.angle_in(theta_angle), .cos_out(cos_val), .sin_out(sin_val));

    wire signed [`TOTAL_BITS*2-1:0] phase_factor; // e^(i*theta) = cos(theta) + i*sin(theta)
    assign phase_factor = {cos_val, sin_val};

    wire signed [`TOTAL_BITS*2-1:0] multiplied_target;
    complex_mult mult_target_phase (.q1_in(target_q_amplitude_in), .q2_in(phase_factor), .q_out(multiplied_target));

    // If control_bit is high, apply phase; else, pass through original target amplitude
    assign target_q_amplitude_out = control_bit ? multiplied_target : target_q_amplitude_in;
    
    // Control qubit is unchanged in CPHASE
    assign control_q_out = control_q_in; 
    
    // Catatan: Port 'target_q_in' dan 'target_q_out' yang ada di daftar port modul tidak digunakan dalam logika modul ini.
    // Ini bukan error sintaks, tetapi mungkin indikasi desain yang tidak efisien atau tidak lengkap.

endmodule
