`include "fixed_point_params.vh"

//======================================================================
// Complex-Complex Multiplier (Extreme Pipelining - Deeper Pipelining)
// Latency: 9 cycles (Added 2 extra stages for multiplication results)
//======================================================================
module ccmult_pipelined(
    input                         clk,
    input                         rst_s_n,
    input  signed [`TOTAL_WIDTH-1:0] ar, ai,
    input  signed [`TOTAL_WIDTH-1:0] br, bi,
    output signed [`TOTAL_WIDTH-1:0] pr, pi
);

    // Pipeline Stage 1: Register inputs
    reg signed [`TOTAL_WIDTH-1:0] ar_s1, ai_s1, br_s1, bi_s1;
    always @(posedge clk) begin
        if (!rst_s_n) begin
            ar_s1 <= 0; ai_s1 <= 0;
            br_s1 <= 0; bi_s1 <= 0;
        end else begin
            ar_s1 <= ar;
            ai_s1 <= ai;
            br_s1 <= br;
            bi_s1 <= bi;
        end
    end

    // Pipeline Stage 2: Perform multiplications (combinational part)
    wire signed [`MULT_WIDTH-1:0] p_ar_br_s2_comb, p_ai_bi_s2_comb, p_ar_bi_s2_comb, p_ai_br_s2_comb;
    assign p_ar_br_s2_comb = ar_s1 * br_s1;
    assign p_ai_bi_s2_comb = ai_s1 * bi_s1;
    assign p_ar_bi_s2_comb = ar_s1 * bi_s1;
    assign p_ai_br_s2_comb = ai_s1 * br_s1;
    
    // Pipeline Stage 3: Register multiplication results (first stage of multiplier result registers)
    reg signed [`MULT_WIDTH-1:0] p_ar_br_s3, p_ai_bi_s3, p_ar_bi_s3, p_ai_br_s3;
    always @(posedge clk) begin
        if (!rst_s_n) begin
            p_ar_br_s3 <= 0;
            p_ai_bi_s3 <= 0;
            p_ar_bi_s3 <= 0;
            p_ai_br_s3 <= 0;
        end else begin
            p_ar_br_s3 <= p_ar_br_s2_comb;
            p_ai_bi_s3 <= p_ai_bi_s2_comb;
            p_ar_bi_s3 <= p_ar_bi_s2_comb;
            p_ai_br_s3 <= p_ai_br_s2_comb;
        end
    end

    // Pipeline Stage 4: Register multiplication results (second stage of multiplier result registers, for deeper pipelining)
    reg signed [`MULT_WIDTH-1:0] p_ar_br_s4, p_ai_bi_s4, p_ar_bi_s4, p_ai_br_s4;
    always @(posedge clk) begin
        if (!rst_s_n) begin
            p_ar_br_s4 <= 0;
            p_ai_bi_s4 <= 0;
            p_ar_bi_s4 <= 0;
            p_ai_br_s4 <= 0;
        end else begin
            p_ar_br_s4 <= p_ar_br_s3;
            p_ai_bi_s4 <= p_ai_bi_s3;
            p_ar_bi_s4 <= p_ar_bi_s3;
            p_ai_br_s4 <= p_ai_br_s3;
        end
    end

    // Pipeline Stage 5: Perform addition/subtraction (combinational part) - uses results from Stage 4
    wire signed [`MULT_WIDTH:0] real_sum_s5_comb, imag_sum_s5_comb;
    assign real_sum_s5_comb = p_ar_br_s4 - p_ai_bi_s4;
    assign imag_sum_s5_comb = p_ar_bi_s4 + p_ai_br_s4;

    // Pipeline Stage 6: Register addition/subtraction results
    reg signed [`MULT_WIDTH:0] real_sum_s6, imag_sum_s6;
    always @(posedge clk) begin
        if (!rst_s_n) begin
            real_sum_s6 <= 0;
            imag_sum_s6 <= 0;
        end else begin
            real_sum_s6 <= real_sum_s5_comb;
            imag_sum_s6 <= imag_sum_s5_comb;
        end
    end

    // Pipeline Stage 7: Perform fixed-point right shift (combinational part)
    wire signed [`TOTAL_WIDTH-1:0] pr_s7_comb, pi_s7_comb;
    assign pr_s7_comb = real_sum_s6 >>> `FRAC_WIDTH;
    assign pi_s7_comb = imag_sum_s6 >>> `FRAC_WIDTH;

    // Pipeline Stage 8: Register shifted results
    reg signed [`TOTAL_WIDTH-1:0] pr_s8, pi_s8;
    always @(posedge clk) begin
        if (!rst_s_n) begin
            pr_s8 <= 0;
            pi_s8 <= 0;
        end else begin
            pr_s8 <= pr_s7_comb;
            pi_s8 <= pi_s7_comb;
        end
    end

    // Pipeline Stage 9: Final output register (additional stage to break critical path if needed, or simply for latency matching)
    reg signed [`TOTAL_WIDTH-1:0] pr_s9, pi_s9;
    always @(posedge clk) begin
        if (!rst_s_n) begin
            pr_s9 <= 0;
            pi_s9 <= 0;
        end else begin
            pr_s9 <= pr_s8;
            pi_s9 <= pi_s8;
        end
    end
    
    assign pr = pr_s9;
    assign pi = pi_s9;
    
endmodule
