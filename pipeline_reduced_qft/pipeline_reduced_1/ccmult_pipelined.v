// ccmult_pipelined.v
`include "fixed_point_params.vh"

//======================================================================
// Complex-Complex Multiplier (Pipelined)
//======================================================================
// Latency: 4 cycles
module ccmult_pipelined(
    input                         clk,
    input                         rst_n,
    input  signed [`TOTAL_WIDTH-1:0] ar, ai,
    input  signed [`TOTAL_WIDTH-1:0] br, bi,
    output signed [`TOTAL_WIDTH-1:0] pr, pi
);

    // Pipeline Stage 1: multiplication
    reg signed [`MULT_WIDTH-1:0] p_ar_br_s1, p_ai_bi_s1, p_ar_bi_s1, p_ai_br_s1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            p_ar_br_s1 <= 0;
            p_ai_bi_s1 <= 0;
            p_ar_bi_s1 <= 0;
            p_ai_br_s1 <= 0;
        end else begin
            p_ar_br_s1 <= ar * br;
            p_ai_bi_s1 <= ai * bi;
            p_ar_bi_s1 <= ar * bi;
            p_ai_br_s1 <= ai * br;
        end
    end

    // Pipeline Stage 2: addition/subtraction
    reg signed [`MULT_WIDTH:0] real_sum_s2, imag_sum_s2; // Increased width for addition result
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            real_sum_s2 <= 0;
            imag_sum_s2 <= 0;
        end else begin
            real_sum_s2 <= p_ar_br_s1 - p_ai_bi_s1;
            imag_sum_s2 <= p_ar_bi_s1 + p_ai_br_s1;
        end
    end

    // Pipeline Stage 3: scaling
    // // FIX: Renamed output registers of Stage 3 and added Stage 4
    reg signed [`TOTAL_WIDTH-1:0] scaled_pr_s3, scaled_pi_s3;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            scaled_pr_s3 <= 0;
            scaled_pi_s3 <= 0;
        end else begin
            scaled_pr_s3 <= real_sum_s2 >>> `FRAC_WIDTH;
            scaled_pi_s3 <= imag_sum_s2 >>> `FRAC_WIDTH;
        end
    end

    // // FIX: Pipeline Stage 4: Output registers
    reg signed [`TOTAL_WIDTH-1:0] pr_s4, pi_s4;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pr_s4 <= 0;
            pi_s4 <= 0;
        end else begin
            pr_s4 <= scaled_pr_s3;
            pi_s4 <= scaled_pi_s3;
        end
    end
    
    assign pr = pr_s4;
    assign pi = pi_s4;
    
endmodule
