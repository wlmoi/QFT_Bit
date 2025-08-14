`include "fixed_point_params.vh"

//======================================================================
// Simplified Hadamard Gate (Deeper Pipelining)
// Latency: 7 cycles (increased for finer-grain pipelining of operations)
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

    // --- Pipeline Stage 2: Addition/Subtraction (combinational logic) ---
    reg signed [`ADD_WIDTH-1:0] add_r_s2_comb, add_i_s2_comb;
    reg signed [`ADD_WIDTH-1:0] sub_r_s2_comb, sub_i_s2_comb;
    always @(posedge clk) begin
        if (!rst_s_n) begin
            add_r_s2_comb <= 0; add_i_s2_comb <= 0;
            sub_r_s2_comb <= 0; sub_i_s2_comb <= 0;
        end else begin
            add_r_s2_comb <= alpha_r_s1 + beta_r_s1;
            add_i_s2_comb <= alpha_i_s1 + beta_i_s1;
            sub_r_s2_comb <= alpha_r_s1 - beta_r_s1;
            sub_i_s2_comb <= alpha_i_s1 - beta_i_s1;
        end
    end

    // --- Pipeline Stage 3: Register add/sub results (NEW STAGE) ---
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

    // --- Pipeline Stage 4: Multiplication by 1/sqrt(2) (combinational logic) ---
    reg signed [H_MULT_WIDTH-1:0] mult_add_r_s4_comb, mult_add_i_s4_comb;
    reg signed [H_MULT_WIDTH-1:0] mult_sub_r_s4_comb, mult_sub_i_s4_comb;
    always @(posedge clk) begin
        if (!rst_s_n) begin
            mult_add_r_s4_comb <= 0; mult_add_i_s4_comb <= 0;
            mult_sub_r_s4_comb <= 0; mult_sub_i_s4_comb <= 0;
        end else begin
            mult_add_r_s4_comb <= add_r_s3 * ONE_OVER_SQRT2;
            mult_add_i_s4_comb <= add_i_s3 * ONE_OVER_SQRT2;
            mult_sub_r_s4_comb <= sub_r_s3 * ONE_OVER_SQRT2;
            mult_sub_i_s4_comb <= sub_i_s3 * ONE_OVER_SQRT2;
        end
    end

    // Pipeline Stage 5: Register multiplication results (NEW STAGE to break path)
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

    // Pipeline Stage 6: Register multiplication results again (NEW STAGE for more pipelining)
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

    // --- Pipeline Stage 7: Scaling (output register) ---
    reg signed [`TOTAL_WIDTH-1:0] new_alpha_r_s7, new_alpha_i_s7;
    reg signed [`TOTAL_WIDTH-1:0] new_beta_r_s7,  new_beta_i_s7;
    always @(posedge clk) begin
        if (!rst_s_n) begin
            new_alpha_r_s7 <= 0; new_alpha_i_s7 <= 0;
            new_beta_r_s7  <= 0; new_beta_i_s7  <= 0;
        end else begin
            new_alpha_r_s7 <= mult_add_r_s6 >>> `FRAC_WIDTH;
            new_alpha_i_s7 <= mult_add_i_s6 >>> `FRAC_WIDTH;
            new_beta_r_s7  <= mult_sub_r_s6 >>> `FRAC_WIDTH;
            new_beta_i_s7  <= mult_sub_i_s6 >>> `FRAC_WIDTH;
        end
    end
    
    assign new_alpha_r = new_alpha_r_s7;
    assign new_alpha_i = new_alpha_i_s7;
    assign new_beta_r  = new_beta_r_s7;
    assign new_beta_i  = new_beta_i_s7;
    
endmodule
