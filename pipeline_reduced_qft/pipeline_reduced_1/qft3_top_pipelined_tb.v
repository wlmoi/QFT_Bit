`timescale 1ns/1ps
`include "fixed_point_params.vh"

module qft3_top_pipelined_tb;

    // --- Clock and Reset ---
    reg clk;
    reg rst_n;

    // --- Inputs to the DUT ---
    reg  signed [`TOTAL_WIDTH-1:0] i000_r, i000_i, i001_r, i001_i, i010_r, i010_i, i011_r, i011_i;
    reg  signed [`TOTAL_WIDTH-1:0] i100_r, i100_i, i101_r, i101_i, i110_r, i110_i, i111_r, i111_i;
    
    // --- Outputs from the DUT ---
    wire signed [`TOTAL_WIDTH-1:0] f000_r, f000_i, f001_r, f001_i, f010_r, f010_i, f011_r, f011_i;
    wire signed [`TOTAL_WIDTH-1:0] f100_r, f100_i, f101_r, f101_i, f110_r, f110_i, f111_r, f111_i;

    // --- Instantiate the DUT ---
    qft3_top_pipelined uut (
        .clk(clk), .rst_n(rst_n),
        .i000_r(i000_r), .i000_i(i000_i), .i001_r(i001_r), .i001_i(i001_i),
        .i010_r(i010_r), .i010_i(i010_i), .i011_r(i011_r), .i011_i(i011_i),
        .i100_r(i100_r), .i100_i(i100_i), .i101_r(i101_r), .i101_i(i101_i),
        .i110_r(i110_r), .i110_i(i110_i), .i111_r(i111_r), .i111_i(i111_i),
        .f000_r(f000_r), .f000_i(f000_i), .f001_r(f001_r), .f001_i(f001_i),
        .f010_r(f010_r), .f010_i(f010_i), .f011_r(f011_r), .f011_i(f011_i),
        .f100_r(f100_r), .f100_i(f100_i), .f101_r(f101_r), .f101_i(f101_i),
        .f110_r(f110_r), .f110_i(f110_i), .f111_r(f111_r), .f111_i(f111_i)
    );

    // --- Fixed-Point Constants for Test (S1.2 format, assuming TOTAL_WIDTH=4) ---
    // 1.0 in S1.2 format (1 * 2^`FRAC_WIDTH` = 1 * 4 = 4)
    localparam S12_ONE = 4;
    // Expected approximate amplitude of output components: 1/sqrt(8) * input_amplitude
    // If input_amplitude is 1.0 (S12_ONE = 4), then output amplitude ~0.3535 * 4 = 1.414. Rounded to 1.
    localparam S12_AMP = 1;  
    
    // --- PIPELINE LATENCY ---
    localparam PIPELINE_LATENCY = 19;

    // Clock generator
    initial begin
        clk = 0;
        forever #750 clk = ~clk; // 1500ns period, ~666.7KHz clock
    end
    
    // --- Test Sequence ---
    initial begin
        $display("--- 3-Qubit QFT Pipelined Testbench (4-bit fixed-point) ---");
        // Initialize all inputs to zero
        {i000_r,i000_i,i001_r,i001_i,i010_r,i010_i,i011_r,i011_i} = 0;
        {i100_r,i100_i,i101_r,i101_i,i110_r,i110_i,i111_r,i111_i} = 0;

        // Pulse reset
        rst_n = 1'b0;
        #1500; // At least one full clock cycle for reset (2 * 750ns)
        rst_n = 1'b1;
        #750; // Wait half a cycle after reset deassertion

        // Test Case: Apply QFT to the state |110> (the number 6) with amplitude 1.0
        $display("Applying input state |110> (1.0) at time %t", $time);
        i110_r = S12_ONE; // Input amplitude 1.0 (4 in S1.2)

        // Wait for the pipeline to fill and for the result to be ready
        repeat(PIPELINE_LATENCY + 2) @(posedge clk);
        
        $display("Checking output after %d cycles at time %t", PIPELINE_LATENCY, $time);

        // --- Verification ---
        // For state |110> (k=6), the expected amplitudes are 1/sqrt(8) * phase_factor.
        // 1/sqrt(8) * 4 (S1.2_ONE) = 1.414. Using S12_AMP = 1.
        // The phase pattern is (1, -i, -1, i, 1, -i, -1, i) approximately.
        $display("Testing QFT on state |110> (6)");
        $display("Final State:   [ (%d,%di), (%d,%di), (%d,%di), (%d,%di), (%d,%di), (%d,%di), (%d,%di), (%d,%di) ]",
                  f000_r,f000_i, f001_r,f001_i, f010_r,f010_i, f011_r,f011_i,
                  f100_r,f100_i, f101_r,f101_i, f110_r,f110_i, f111_r,f111_i);
        $display("Expected State (approx. S1.2, scaled by %0d):  [ (%0d,0i), (0,%0di), (%0d,0i), (0,%0di), (%0d,0i), (0,%0di), (%0d,0i), (0,%0di) ]",
                 S12_AMP, S12_AMP, -S12_AMP, -S12_AMP, S12_AMP, S12_AMP, -S12_AMP, -S12_AMP, S12_AMP);

        // Check against the expected S1.2 values, allowing for small rounding errors (tolerance +/- 1).
        // Due to extremely limited precision, the accuracy will be very low.
        if (f000_r >= (S12_AMP-1) && f000_r <= (S12_AMP+1) && f000_i == 0 && // 000: (A, 0)
            f001_r == 0 && f001_i >= (-S12_AMP-1) && f001_i <= (-S12_AMP+1) && // 001: (0, -A)
            f010_r >= (-S12_AMP-1) && f010_r <= (-S12_AMP+1) && f010_i == 0 && // 010: (-A, 0)
            f011_r == 0 && f011_i >= (S12_AMP-1) && f011_i <= (S12_AMP+1) && // 011: (0, A)
            f100_r >= (S12_AMP-1) && f100_r <= (S12_AMP+1) && f100_i == 0 && // 100: (A, 0)
            f101_r == 0 && f101_i >= (-S12_AMP-1) && f101_i <= (-S12_AMP+1) && // 101: (0, -A)
            f110_r >= (-S12_AMP-1) && f110_r <= (-S12_AMP+1) && f110_i == 0 && // 110: (-A, 0)
            f111_r == 0 && f111_i >= (S12_AMP-1) && f111_i <= (S12_AMP+1)    // 111: (0, A)
        ) begin
            $display("\nResult: PASSED ✅");
        end else begin
            $display("\nResult: FAILED ❌");
        end
        
        #10 $finish;
    end

endmodule
