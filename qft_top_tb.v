// qft_top_tb.v
`ifndef QFT_TOP_TB_V
`define QFT_TOP_TB_V

// Include common fixed-point parameters and complex utils.
// This will define `TOTAL_BITS`, `FX_BITS`, `INT_BITS` and all utility modules.
`include "fixed_complex_utils.v"

// Include all other modules used directly or indirectly by the testbench
// Using include guards will prevent re-declarations.
`include "cos_sin_lut.v"
`include "exp_lut_8_segment.v" // Now a full LUT
`include "x_gate.v"
`include "qft_2_qubit.v"
`include "quantum_state_magnitudes.v"


module qft_top_tb;

    // --- No local parameters here for TOTAL_BITS, FX_BITS etc.
    //     They are taken directly from the global `define`s in fixed_complex_utils.v
    //     This avoids potential conflicts/ambiguities.

    // Derived parameters using global macros
    parameter COMP_BITS = `TOTAL_BITS * 2; // Bits for a complex number (16 bits)
    parameter QSTATE_BITS = COMP_BITS * 4; // Bits for a 2-qubit state vector (64 bits)

    reg clk;
    reg rst_n;

    // --- Testbench Wires and Regs for module interfaces ---

    // 1. exp_lut_8_segment
    reg signed [`TOTAL_BITS-1:0] tb_exp_x_in;
    wire signed [`TOTAL_BITS-1:0] tb_exp_x_out;

    // 2. x_gate
    reg tb_x_gate_in;
    wire tb_x_gate_out;

    // 3. qft_2_qubit
    reg signed [QSTATE_BITS-1:0] tb_qft_q_state_in;
    wire signed [QSTATE_BITS-1:0] tb_qft_q_state_out;

    // 4. quantum_state_magnitudes (Sampler equivalent)
    reg signed [QSTATE_BITS-1:0] tb_sampler_q_state_in; // Connect from QFT output
    wire signed [`TOTAL_BITS*4-1:0] tb_sampler_mag_sq_out; // 4 magnitude-squared values

    // --- Instantiate Design Under Test (DUT) Modules ---

    exp_lut_8_segment u_exp_lut (
        .x_in(tb_exp_x_in),
        .exp_x_out(tb_exp_x_out)
    );

    x_gate u_x_gate (
        .q_in(tb_x_gate_in),
        .q_out(tb_x_gate_out)
    );

    qft_2_qubit u_qft_2_qubit (
        .q_state_in(tb_qft_q_state_in),
        .q_state_out(tb_qft_q_state_out)
    );

    quantum_state_magnitudes u_sampler (
        .q_state_in(tb_sampler_q_state_in),
        .mag_sq_out(tb_sampler_mag_sq_out)
    );

    // --- Helper Functions for Conversions (Verilog-2001 compatible) ---
    // Function return type must be explicitly stated.

    function signed [`TOTAL_BITS-1:0] float_to_fixed_tb_func;
        input real float_val;
        begin
            float_to_fixed_tb_func = $rtoi(float_val * (1 << `FX_BITS)); // Use global `FX_BITS`
            // Apply saturation for testbench clarity
            if (float_val * (1 << `FX_BITS) > ((1 << (`TOTAL_BITS-1)) - 1))
                float_to_fixed_tb_func = (1 << (`TOTAL_BITS-1)) - 1;
            else if (float_val * (1 << `FX_BITS) < -(1 << (`TOTAL_BITS-1)))
                float_to_fixed_tb_func = -(1 << (`TOTAL_BITS-1));
        end
    endfunction

    function real fixed_to_float_tb_func;
        input signed [`TOTAL_BITS-1:0] fixed_val;
        begin
            fixed_to_float_tb_func = $itor(fixed_val) / (1 << `FX_BITS); // Use global `FX_BITS`
        end
    endfunction

    // --- Helper Tasks for Printing (Verilog-2001 compatible, NO string input, NO return value) ---
    // Tasks do not return values, making them suitable for display operations.

    // Task to print a single complex fixed-point value
    task print_complex_fp_task; 
        input signed [COMP_BITS-1:0] complex_val; // Use local derived parameter COMP_BITS
        begin
            $display("  (%.4f, %.4f)",
                fixed_to_float_tb_func(complex_val[COMP_BITS-1:`TOTAL_BITS]), // Use global `TOTAL_BITS`
                fixed_to_float_tb_func(complex_val[`TOTAL_BITS-1:0])); // Use global `TOTAL_BITS`
        end
    endtask

    // Task to print a 2-qubit state vector
    task print_qstate_vector_task; 
        input signed [QSTATE_BITS-1:0] q_state; // Use local derived parameter QSTATE_BITS
        begin
            // Headers are printed manually in the initial block
            $display("    |00> Amp:"); print_complex_fp_task(q_state[QSTATE_BITS-1 : COMP_BITS*3]);
            $display("    |01> Amp:"); print_complex_fp_task(q_state[COMP_BITS*3-1 : COMP_BITS*2]);
            $display("    |10> Amp:"); print_complex_fp_task(q_state[COMP_BITS*2-1 : COMP_BITS]);
            $display("    |11> Amp:"); print_complex_fp_task(q_state[COMP_BITS-1 : 0]);
            $display("-----------------------");
        end
    endtask

    // Task to print magnitude squared outputs
    task print_mag_sq_task; 
        input signed [`TOTAL_BITS*4-1:0] mag_sq_val; // Use macro from fixed_complex_utils.v
        begin
            // Headers are printed manually in the initial block
            $display("  MagSq for |00>: %.4f", fixed_to_float_tb_func(mag_sq_val[`TOTAL_BITS*4-1:`TOTAL_BITS*3]));
            $display("  MagSq for |01>: %.4f", fixed_to_float_tb_func(mag_sq_val[`TOTAL_BITS*3-1:`TOTAL_BITS*2]));
            $display("  MagSq for |10>: %.4f", fixed_to_float_tb_func(mag_sq_val[`TOTAL_BITS*2-1:`TOTAL_BITS]));
            $display("  MagSq for |11>: %.4f", fixed_to_float_tb_func(mag_sq_val[`TOTAL_BITS-1:0]));
            $display("----------------------------");
        end
    endtask


    // --- Initial Block for Stimulus ---
    initial begin
        // --- Tambahkan dua baris ini untuk menghasilkan waveform VCD ---
        $dumpfile("qft_simulation.vcd");
        $dumpvars(0, qft_top_tb);
        // -----------------------------------------------------------

        clk = 0;
        rst_n = 0;
        #10 rst_n = 1; // De-assert reset

        $display("Starting Simulation with S_%0d.%0d fixed-point format (Total %0d bits)", `INT_BITS, `FX_BITS, `TOTAL_BITS); // Using global macros directly

        // --- Test 1: exp_lut_8_segment (now a full 256-entry LUT) ---
        $display("\n*** Testing exp_lut_8_segment (Full LUT) ***");
        tb_exp_x_in = float_to_fixed_tb_func(0.0);
        #10 $display("Input x = %.4f (Fixed: %d), Output e^x = %.4f (Fixed: %d)",
                      fixed_to_float_tb_func(tb_exp_x_in), tb_exp_x_in, fixed_to_float_tb_func(tb_exp_x_out), tb_exp_x_out);
        
        tb_exp_x_in = float_to_fixed_tb_func(0.74); 
        #10 $display("Input x = %.4f (Fixed: %d), Output e^x = %.4f (Fixed: %d)",
                      fixed_to_float_tb_func(tb_exp_x_in), tb_exp_x_in, fixed_to_float_tb_func(tb_exp_x_out), tb_exp_x_out);

        tb_exp_x_in = float_to_fixed_tb_func(1.0); 
        #10 $display("Input x = %.4f (Fixed: %d), Output e^x = %.4f (Fixed: %d)",
                      fixed_to_float_tb_func(tb_exp_x_in), tb_exp_x_in, fixed_to_float_tb_func(tb_exp_x_out), tb_exp_x_out);
        
        tb_exp_x_in = float_to_fixed_tb_func(2.0); 
        #10 $display("Input x = %.4f (Fixed: %d), Output e^x = %.4f (Fixed: %d)",
                      fixed_to_float_tb_func(tb_exp_x_in), tb_exp_x_in, fixed_to_float_tb_func(tb_exp_x_out), tb_exp_x_out);

        tb_exp_x_in = float_to_fixed_tb_func(3.0); 
        #10 $display("Input x = %.4f (Fixed: %d), Output e^x = %.4f (Fixed: %d)",
                      fixed_to_float_tb_func(tb_exp_x_in), tb_exp_x_in, fixed_to_float_tb_func(tb_exp_x_out), tb_exp_x_out);

        tb_exp_x_in = float_to_fixed_tb_func(4.0); 
        #10 $display("Input x = %.4f (Fixed: %d), Output e^x = %.4f (Fixed: %d)",
                      fixed_to_float_tb_func(tb_exp_x_in), tb_exp_x_in, fixed_to_float_tb_func(tb_exp_x_out), tb_exp_x_out);

        tb_exp_x_in = float_to_fixed_tb_func(5.0); 
        #10 $display("Input x = %.4f (Fixed: %d), Output e^x = %.4f (Fixed: %d)",
                      fixed_to_float_tb_func(tb_exp_x_in), tb_exp_x_in, fixed_to_float_tb_func(tb_exp_x_out), tb_exp_x_out);

        tb_exp_x_in = float_to_fixed_tb_func(-1.0); 
        #10 $display("Input x = %.4f (Fixed: %d), Output e^x = %.4f (Fixed: %d)",
                      fixed_to_float_tb_func(tb_exp_x_in), tb_exp_x_in, fixed_to_float_tb_func(tb_exp_x_out), tb_exp_x_out);

        tb_exp_x_in = float_to_fixed_tb_func(-0.5); 
        #10 $display("Input x = %.4f (Fixed: %d), Output e^x = %.4f (Fixed: %d)",
                      fixed_to_float_tb_func(tb_exp_x_in), tb_exp_x_in, fixed_to_float_tb_func(tb_exp_x_out), tb_exp_x_out);


        // --- Test 2: x_gate ---
        $display("\n*** Testing x_gate (Classical NOT) ***");
        tb_x_gate_in = 0;
        #10 $display("X-gate input: %b, Output: %b", tb_x_gate_in, tb_x_gate_out);
        tb_x_gate_in = 1;
        #10 $display("X-gate input: %b, Output: %b", tb_x_gate_in, tb_x_gate_out);


        // --- Test 3: qft_2_qubit ---
        $display("\n*** Testing qft_2_qubit ***");
        // Initial state |00> (alpha_00 = 1.0, others 0.0)
        tb_qft_q_state_in = {
            {float_to_fixed_tb_func(1.0), float_to_fixed_tb_func(0.0)}, // |00> amplitude
            {float_to_fixed_tb_func(0.0), float_to_fixed_tb_func(0.0)}, // |01> amplitude
            {float_to_fixed_tb_func(0.0), float_to_fixed_tb_func(0.0)}, // |10> amplitude
            {float_to_fixed_tb_func(0.0), float_to_fixed_tb_func(0.0)}  // |11> amplitude
        };
        $display("--- Initial QFT Input |00> State Vector ---"); // Print header manually
        #10 print_qstate_vector_task(tb_qft_q_state_in); 

        $display("--- QFT Output for |00> State Vector ---"); // Print header manually
        #10 print_qstate_vector_task(tb_qft_q_state_out);   

        // Initial state |01>
        tb_qft_q_state_in = {
            {float_to_fixed_tb_func(0.0), float_to_fixed_tb_func(0.0)}, // |00> amplitude
            {float_to_fixed_tb_func(1.0), float_to_fixed_tb_func(0.0)}, // |01> amplitude
            {float_to_fixed_tb_func(0.0), float_to_fixed_tb_func(0.0)}, // |10> amplitude
            {float_to_fixed_tb_func(0.0), float_to_fixed_tb_func(0.0)}  // |11> amplitude
        };
        $display("--- Initial QFT Input |01> State Vector ---"); // Print header manually
        #10 print_qstate_vector_task(tb_qft_q_state_in); 
        $display("--- QFT Output for |01> State Vector ---");   // Print header manually
        #10 print_qstate_vector_task(tb_qft_q_state_out);   


        // --- Test 4: quantum_state_magnitudes (Sampler) ---
        $display("\n*** Testing quantum_state_magnitudes (Sampler) ***");
        tb_sampler_q_state_in = tb_qft_q_state_out; 
        $display("--- Sampler Output (for |01> QFT result) Magnitudes Squared ---"); // Print header manually
        #10 print_mag_sq_task(tb_sampler_mag_sq_out); 

        // Additional test for Sampler: a simple superposition state like |+0>
        tb_sampler_q_state_in = {
            {float_to_fixed_tb_func(0.707), float_to_fixed_tb_func(0.0)}, // |00> amplitude
            {float_to_fixed_tb_func(0.0),   float_to_fixed_tb_func(0.0)}, // |01> amplitude
            {float_to_fixed_tb_func(0.707), float_to_fixed_tb_func(0.0)}, // |10> amplitude
            {float_to_fixed_tb_func(0.0),   float_to_fixed_tb_func(0.0)}  // |11> amplitude
        };
        $display("--- Sampler Input (e.g. |+0> = 0.707|00> + 0.707|10>) State Vector ---"); // Print header manually
        #10 print_qstate_vector_task(tb_sampler_q_state_in); 
        $display("--- Sampler Output (expected 0.5 for |00> & |10>, others 0) Magnitudes Squared ---"); // Print header manually
        #10 print_mag_sq_task(tb_sampler_mag_sq_out); 


        $finish; // End simulation
    end

    // Clock generation (not strictly needed for purely combinational logic, but good practice)
    always #5 clk = ~clk;

endmodule
`endif // QFT_TOP_TB_V
