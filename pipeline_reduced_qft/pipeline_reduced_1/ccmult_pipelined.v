`include "fixed_point_params.vh"

//======================================================================
// Complex-Complex Multiplier (Deeper Pipelining)
// Latency: 6 cycles (increased for finer-grain pipelining of operations)
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

    // Pipeline Stage 2: Perform multiplications (combinational logic)
    reg signed [`MULT_WIDTH-1:0] p_ar_br_s2_comb, p_ai_bi_s2_comb, p_ar_bi_s2_comb, p_ai_br_s2_comb;
    always @(posedge clk) begin
        if (!rst_s_n) begin
            p_ar_br_s2_comb <= 0;
            p_ai_bi_s2_comb <= 0;
            p_ar_bi_s2_comb <= 0;
            p_ai_br_s2_comb <= 0;
        end else begin
            p_ar_br_s2_comb <= ar_s1 * br_s1;
            p_ai_bi_s2_comb <= ai_s1 * bi_s1;
            p_ar_bi_s2_comb <= ar_s1 * bi_s1;
            p_ai_br_s2_comb <= ai_s1 * br_s1;
        end
    end

    // Pipeline Stage 3: Register multiplication results (NEW STAGE to break path)
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

    // Pipeline Stage 4: Addition/subtraction (combinational logic)
    reg signed [`MULT_WIDTH:0] real_sum_s4_comb, imag_sum_s4_comb;
    always @(posedge clk) begin
        if (!rst_s_n) begin
            real_sum_s4_comb <= 0;
            imag_sum_s4_comb <= 0;
        end else begin
            real_sum_s4_comb <= p_ar_br_s3 - p_ai_bi_s3;
            imag_sum_s4_comb <= p_ar_bi_s3 + p_ai_br_s3;
        end
    end

    // Pipeline Stage 5: Register addition/subtraction results (NEW STAGE to break path)
    reg signed [`MULT_WIDTH:0] real_sum_s5, imag_sum_s5;
    always @(posedge clk) begin
        if (!rst_s_n) begin
            real_sum_s5 <= 0;
            imag_sum_s5 <= 0;
        end else begin
            real_sum_s5 <= real_sum_s4_comb;
            imag_sum_s5 <= imag_sum_s4_comb;
        end
    end

    // Pipeline Stage 6: Scaling (output register)
    reg signed [`TOTAL_WIDTH-1:0] pr_s6, pi_s6;
    always @(posedge clk) begin
        if (!rst_s_n) begin
            pr_s6 <= 0;
            pi_s6 <= 0;
        end else begin
            pr_s6 <= real_sum_s5 >>> `FRAC_WIDTH;
            pi_s6 <= imag_sum_s5 >>> `FRAC_WIDTH;
        end
    end
    
    assign pr = pr_s6;
    assign pi = pi_s6;
    
endmodule
