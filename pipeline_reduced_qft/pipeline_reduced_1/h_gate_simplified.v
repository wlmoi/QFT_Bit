`include "fixed_point_params.vh"

//======================================================================
// Simplified Hadamard Gate (Extreme Pipelining - Deeper Pipelining)
// Latency: 10 cycles (Added 2 extra stages for multiplication results)
//======================================================================
module h_gate_simplified(
    input                         clk,
    input                         rst_s_n,
    input  signed [`TOTAL_WIDTH-1:0] alpha_r, alpha_i,
    input  signed [`TOTAL_WIDTH-1:0] beta_r,  beta_i,
    output signed [`TOTAL_WIDTH-1:0] new_alpha_r, new_alpha_i,
    output signed [`TOTAL_WIDTH-1:0] new_beta_r,  new_beta_i
);

    // S3.4 constant for 1/sqrt(2)
    localparam signed [`TOTAL_WIDTH-1:0] ONE_OVER_SQRT2 = 11;

    // Define a wider intermediate product width to prevent overflow
    localparam H_MULT_WIDTH = `ADD_WIDTH + `TOTAL_WIDTH;

    // --- Pipeline Stage 1: Register inputs ---
    reg signed [`TOTAL_WIDTH-1:0] alpha_r_s1, alpha_i_s1;
    reg signed [`TOTAL_WIDTH-1:0] beta_r_s1,  beta_i_s1;
    always @(posedge clk) begin
        if (!rst_s_n) begin
            alpha_r_s1 <= 0; alpha_i_s1 <= 0;
            beta_r_s1  <= 0; beta_i_s1  <= 0;
        end else begin
            alpha_r_s1 <= alpha_r;
            alpha_i_s1 <= alpha_i;
            beta_r_s1  <= beta_r;
            beta_i_s1  <= beta_i;
        end
    end

    // --- Pipeline Stage 2: Addition/Subtraction (combinational part) ---
    wire signed [`ADD_WIDTH-1:0] add_r_s2_comb, add_i_s2_comb;
    wire signed [`ADD_WIDTH-1:0] sub_r_s2_comb, sub_i_s2_comb;
    assign add_r_s2_comb = alpha_r_s1 + beta_r_s1;
    assign add_i_s2_comb = alpha_i_s1 + beta_i_s1;
    assign sub_r_s2_comb = alpha_r_s1 - beta_r_s1;
    assign sub_i_s2_comb = alpha_i_s1 - beta_i_s1;
    
    // --- Pipeline Stage 3: Register add/sub results ---
    reg signed [`ADD_WIDTH-1:0] add_r_s3, add_i_s3;
    reg signed [`ADD_WIDTH-1:0] sub_r_s3, sub_i_s3;
    always @(posedge clk) begin
        if (!rst_s_n) begin
            add_r_s3 <= 0; add_i_s3 <= 0;
            sub_r_s3 <= 0; sub_i_s3 <= 0;
        end else begin
            add_r_s3 <= add_r_s2_comb;
            add_i_s3 <= add_i_s2_comb;
            sub_r_s3 <= sub_r_s2_comb;
            sub_i_s3 <= sub_i_s2_comb;
        end
    end

    // --- Pipeline Stage 4: Multiplication by 1/sqrt(2) (combinational part) ---
    wire signed [H_MULT_WIDTH-1:0] mult_add_r_s4_comb, mult_add_i_s4_comb;
    wire signed [H_MULT_WIDTH-1:0] mult_sub_r_s4_comb, mult_sub_i_s4_comb;
    assign mult_add_r_s4_comb = add_r_s3 * ONE_OVER_SQRT2;
    assign mult_add_i_s4_comb = add_i_s3 * ONE_OVER_SQRT2;
    assign mult_sub_r_s4_comb = sub_r_s3 * ONE_OVER_SQRT2;
    assign mult_sub_i_s4_comb = sub_i_s3 * ONE_OVER_SQRT2;

    // Pipeline Stage 5: Register multiplication results (first stage of multiplier result registers)
    reg signed [H_MULT_WIDTH-1:0] mult_add_r_s5, mult_add_i_s5;
    reg signed [H_MULT_WIDTH-1:0] mult_sub_r_s5, mult_sub_i_s5;
    always @(posedge clk) begin
        if (!rst_s_n) begin
            mult_add_r_s5 <= 0; mult_add_i_s5 <= 0;
            mult_sub_r_s5 <= 0; mult_sub_i_s5 <= 0;
        end else begin
            mult_add_r_s5 <= mult_add_r_s4_comb;
            mult_add_i_s5 <= mult_add_i_s4_comb;
            mult_sub_r_s5 <= mult_sub_r_s4_comb;
            mult_sub_i_s5 <= mult_sub_i_s4_comb;
        end
    end

    // Pipeline Stage 6: Register multiplication results (second stage of multiplier result registers, for deeper pipelining)
    reg signed [H_MULT_WIDTH-1:0] mult_add_r_s6, mult_add_i_s6;
    reg signed [H_MULT_WIDTH-1:0] mult_sub_r_s6, mult_sub_i_s6;
    always @(posedge clk) begin
        if (!rst_s_n) begin
            mult_add_r_s6 <= 0; mult_add_i_s6 <= 0;
            mult_sub_r_s6 <= 0; mult_sub_i_s6 <= 0;
        end else begin
            mult_add_r_s6 <= mult_add_r_s5;
            mult_add_i_s6 <= mult_add_i_s5;
            mult_sub_r_s6 <= mult_sub_r_s5;
            mult_sub_i_s6 <= mult_sub_i_s5;
        end
    end

    // Pipeline Stage 7: Perform fixed-point right shift (combinational part)
    wire signed [`TOTAL_WIDTH-1:0] new_alpha_r_s7_comb, new_alpha_i_s7_comb;
    wire signed [`TOTAL_WIDTH-1:0] new_beta_r_s7_comb,  new_beta_i_s7_comb;
    assign new_alpha_r_s7_comb = mult_add_r_s6 >>> `FRAC_WIDTH;
    assign new_alpha_i_s7_comb = mult_add_i_s6 >>> `FRAC_WIDTH;
    assign new_beta_r_s7_comb  = mult_sub_r_s6 >>> `FRAC_WIDTH;
    assign new_beta_i_s7_comb  = mult_sub_i_s6 >>> `FRAC_WIDTH;

    // Pipeline Stage 8: Register shifted results
    reg signed [`TOTAL_WIDTH-1:0] new_alpha_r_s8, new_alpha_i_s8;
    reg signed [`TOTAL_WIDTH-1:0] new_beta_r_s8,  new_beta_i_s8;
    always @(posedge clk) begin
        if (!rst_s_n) begin
            new_alpha_r_s8 <= 0; new_alpha_i_s8 <= 0;
            new_beta_r_s8  <= 0; new_beta_i_s8  <= 0;
        end else begin
            new_alpha_r_s8 <= new_alpha_r_s7_comb;
            new_alpha_i_s8 <= new_alpha_i_s7_comb;
            new_beta_r_s8  <= new_beta_r_s7_comb;
            new_beta_i_s8  <= new_beta_i_s7_comb;
        end
    end

    // Pipeline Stage 9: Register shifted results (additional stage for improved timing)
    reg signed [`TOTAL_WIDTH-1:0] new_alpha_r_s9, new_alpha_i_s9;
    reg signed [`TOTAL_WIDTH-1:0] new_beta_r_s9,  new_beta_i_s9;
    always @(posedge clk) begin
        if (!rst_s_n) begin
            new_alpha_r_s9 <= 0; new_alpha_i_s9 <= 0;
            new_beta_r_s9  <= 0; new_beta_i_s9  <= 0;
        end else begin
            new_alpha_r_s9 <= new_alpha_r_s8;
            new_alpha_i_s9 <= new_alpha_i_s8;
            new_beta_r_s9  <= new_beta_r_s8;
            new_beta_i_s9  <= new_beta_i_s8;
        end
    end
    
    // --- Pipeline Stage 10: Output (final register for output interface) ---
    reg signed [`TOTAL_WIDTH-1:0] new_alpha_r_s10, new_alpha_i_s10;
    reg signed [`TOTAL_WIDTH-1:0] new_beta_r_s10,  new_beta_i_s10;
    always @(posedge clk) begin
        if (!rst_s_n) begin
            new_alpha_r_s10 <= 0; new_alpha_i_s10 <= 0;
            new_beta_r_s10  <= 0; new_beta_i_s10  <= 0;
        end else begin
            new_alpha_r_s10 <= new_alpha_r_s9;
            new_alpha_i_s10 <= new_alpha_i_s9;
            new_beta_r_s10  <= new_beta_r_s9;
            new_beta_i_s10  <= new_beta_i_s9;
        end
    end
    
    assign new_alpha_r = new_alpha_r_s10;
    assign new_alpha_i = new_alpha_i_s10;
    assign new_beta_r  = new_beta_r_s10;
    assign new_beta_i  = new_beta_i_s10;
    
endmodule
