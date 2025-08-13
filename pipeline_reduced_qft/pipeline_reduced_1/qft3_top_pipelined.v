// qft3_top_pipelined.v
`include "fixed_point_params.vh"

//======================================================================
// 3-Qubit QFT Top Level (Pipelined)
//======================================================================
module qft3_top_pipelined(
    input clk,
    input rst_n,

    // Initial 3-qubit state vector [α000, ..., α111]
    input  signed [`TOTAL_WIDTH-1:0] i000_r, i000_i, i001_r, i001_i, i010_r, i010_i, i011_r, i011_i,
    input  signed [`TOTAL_WIDTH-1:0] i100_r, i100_i, i101_r, i101_i, i110_r, i110_i, i111_r, i111_i,

    // Final state vector after the QFT
    output signed [`TOTAL_WIDTH-1:0] f000_r, f000_i, f001_r, f001_i, f010_r, f010_i, f011_r, f011_i,
    output signed [`TOTAL_WIDTH-1:0] f100_r, f100_i, f101_r, f101_i, f110_r, f110_i, f111_r, f111_i
);

    // --- Pre-calculated Rotation Constants (untuk S3.4: TOTAL_WIDTH=8, FRAC_WIDTH=4) ---
    // Untuk theta = pi/2: cos=0, sin=1.0 (1.0 * 2^4 = 16)
    localparam signed [`TOTAL_WIDTH-1:0] C_PI_2_R = 0;
    localparam signed [`TOTAL_WIDTH-1:0] C_PI_2_I = 16;
    // Untuk theta = pi/4: cos=0.707, sin=0.707 (0.707 * 2^4 = 11.312, dibulatkan ke 11)
    localparam signed [`TOTAL_WIDTH-1:0] C_PI_4_R = 11;
    localparam signed [`TOTAL_WIDTH-1:0] C_PI_4_I = 11;

    // --- Latency Definition ---
    // // FIX: Increased latency per stage to 4 cycles.
    localparam STAGE_LATENCY = 4; // Latency per Hadamard/CROT stage

    // --- Intermediate Wires for Pipeline Stages ---
    wire signed [`TOTAL_WIDTH-1:0] s1_r[0:7], s1_i[0:7];
    wire signed [`TOTAL_WIDTH-1:0] s2_r[0:7], s2_i[0:7];
    wire signed [`TOTAL_WIDTH-1:0] s3_r[0:7], s3_i[0:7];
    wire signed [`TOTAL_WIDTH-1:0] s4_r[0:7], s4_i[0:7];
    wire signed [`TOTAL_WIDTH-1:0] s5_r[0:7], s5_i[0:7];
    wire signed [`TOTAL_WIDTH-1:0] s6_r[0:7], s6_i[0:7];

    integer i, j;

    // // FIX: Input Stage Registers to mitigate hold violations at the module boundary.
    // // This ensures that all inputs are registered before feeding into the first stage of the QFT pipeline.
    reg signed [`TOTAL_WIDTH-1:0] r_i000_r, r_i000_i, r_i001_r, r_i001_i, r_i010_r, r_i010_i, r_i011_r, r_i011_i;
    reg signed [`TOTAL_WIDTH-1:0] r_i100_r, r_i100_i, r_i101_r, r_i101_i, r_i110_r, r_i110_i, r_i111_r, r_i111_i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            r_i000_r <= 0; r_i000_i <= 0; r_i001_r <= 0; r_i001_i <= 0;
            r_i010_r <= 0; r_i010_i <= 0; r_i011_r <= 0; r_i011_i <= 0;
            r_i100_r <= 0; r_i100_i <= 0; r_i101_r <= 0; r_i101_i <= 0;
            r_i110_r <= 0; r_i110_i <= 0; r_i111_r <= 0; r_i111_i <= 0;
        end else begin
            r_i000_r <= i000_r; r_i000_i <= i000_i; r_i001_r <= i001_r; r_i001_i <= i001_i;
            r_i010_r <= i010_r; r_i010_i <= i010_i; r_i011_r <= i011_r; r_i011_i <= i011_i;
            r_i100_r <= i100_r; r_i100_i <= i100_i; r_i101_r <= i101_r; r_i101_i <= i101_i;
            r_i110_r <= i110_r; r_i110_i <= i110_i; r_i111_r <= i111_r; r_i111_i <= i111_i;
        end
    end

    // --- STAGE 1: H on q2 (bit 2) --- Latency: 4 ---
    // // FIX: Connect to the newly added input stage registers (r_iXXX_r/i).
    h_gate_simplified h_q2_p0 (.clk(clk), .rst_n(rst_n), .alpha_r(r_i000_r), .alpha_i(r_i000_i), .beta_r(r_i100_r), .beta_i(r_i100_i), .new_alpha_r(s1_r[0]), .new_alpha_i(s1_i[0]), .new_beta_r(s1_r[4]), .new_beta_i(s1_i[4]));
    h_gate_simplified h_q2_p1 (.clk(clk), .rst_n(rst_n), .alpha_r(r_i001_r), .alpha_i(r_i001_i), .beta_r(r_i101_r), .beta_i(r_i101_i), .new_alpha_r(s1_r[1]), .new_alpha_i(s1_i[1]), .new_beta_r(s1_r[5]), .new_beta_i(s1_i[5]));
    h_gate_simplified h_q2_p2 (.clk(clk), .rst_n(rst_n), .alpha_r(r_i010_r), .alpha_i(r_i010_i), .beta_r(r_i110_r), .beta_i(r_i110_i), .new_alpha_r(s1_r[2]), .new_alpha_i(s1_i[2]), .new_beta_r(s1_r[6]), .new_beta_i(s1_i[6]));
    h_gate_simplified h_q2_p3 (.clk(clk), .rst_n(rst_n), .alpha_r(r_i011_r), .alpha_i(r_i011_i), .beta_r(r_i111_r), .beta_i(r_i111_i), .new_alpha_r(s1_r[3]), .new_alpha_i(s1_i[3]), .new_beta_r(s1_r[7]), .new_beta_i(s1_i[7]));

    // --- STAGE 2: CROT(π/2) from q1 to q2 --- Latency: 4 ---
    ccmult_pipelined c21_p0 (.clk(clk), .rst_n(rst_n), .ar(s1_r[6]), .ai(s1_i[6]), .br(C_PI_2_R), .bi(C_PI_2_I), .pr(s2_r[6]), .pi(s2_i[6]));
    ccmult_pipelined c21_p1 (.clk(clk), .rst_n(rst_n), .ar(s1_r[7]), .ai(s1_i[7]), .br(C_PI_2_R), .bi(C_PI_2_I), .pr(s2_r[7]), .pi(s2_i[7]));

    // // FIX: Renamed pass-through registers to avoid potential iverilog confusion and ensure clean compilation.
    // Pass-through with 4-cycle delay
    reg signed [`TOTAL_WIDTH-1:0] delayed_s1_s2_r [0:5][STAGE_LATENCY-1:0];
    reg signed [`TOTAL_WIDTH-1:0] delayed_s1_s2_i [0:5][STAGE_LATENCY-1:0];
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            for(j=0;j<6;j=j+1) for(i=0;i<STAGE_LATENCY;i=i+1) begin
                delayed_s1_s2_r[j][i] <= 0;
                delayed_s1_s2_i[j][i] <= 0;
            end
        end else begin
            delayed_s1_s2_r[0][0] <= s1_r[0]; delayed_s1_s2_i[0][0] <= s1_i[0]; 
            delayed_s1_s2_r[1][0] <= s1_r[1]; delayed_s1_s2_i[1][0] <= s1_i[1];
            delayed_s1_s2_r[2][0] <= s1_r[2]; delayed_s1_s2_i[2][0] <= s1_i[2]; 
            delayed_s1_s2_r[3][0] <= s1_r[3]; delayed_s1_s2_i[3][0] <= s1_i[3];
            delayed_s1_s2_r[4][0] <= s1_r[4]; delayed_s1_s2_i[4][0] <= s1_i[4]; 
            delayed_s1_s2_r[5][0] <= s1_r[5]; delayed_s1_s2_i[5][0] <= s1_i[5];
            for(j=0;j<6;j=j+1) begin
                for(i=1;i<STAGE_LATENCY;i=i+1) begin
                    delayed_s1_s2_r[j][i] <= delayed_s1_s2_r[j][i-1];
                    delayed_s1_s2_i[j][i] <= delayed_s1_s2_i[j][i-1];
                end
            end
        end
    end
    // // FIX: Updated assignments to use the new renamed pass-through registers.
    assign s2_r[0] = delayed_s1_s2_r[0][STAGE_LATENCY-1]; assign s2_i[0] = delayed_s1_s2_i[0][STAGE_LATENCY-1];
    assign s2_r[1] = delayed_s1_s2_r[1][STAGE_LATENCY-1]; assign s2_i[1] = delayed_s1_s2_i[1][STAGE_LATENCY-1];
    assign s2_r[2] = delayed_s1_s2_r[2][STAGE_LATENCY-1]; assign s2_i[2] = delayed_s1_s2_i[2][STAGE_LATENCY-1];
    assign s2_r[3] = delayed_s1_s2_r[3][STAGE_LATENCY-1]; assign s2_i[3] = delayed_s1_s2_i[3][STAGE_LATENCY-1];
    assign s2_r[4] = delayed_s1_s2_r[4][STAGE_LATENCY-1]; assign s2_i[4] = delayed_s1_s2_i[4][STAGE_LATENCY-1];
    assign s2_r[5] = delayed_s1_s2_r[5][STAGE_LATENCY-1]; assign s2_i[5] = delayed_s1_s2_i[5][STAGE_LATENCY-1];

    // --- STAGE 3: CROT(π/4) from q0 to q2 --- Latency: 4 ---
    ccmult_pipelined c20_p0 (.clk(clk), .rst_n(rst_n), .ar(s2_r[5]), .ai(s2_i[5]), .br(C_PI_4_R), .bi(C_PI_4_I), .pr(s3_r[5]), .pi(s3_i[5]));
    ccmult_pipelined c20_p1 (.clk(clk), .rst_n(rst_n), .ar(s2_r[7]), .ai(s2_i[7]), .br(C_PI_4_R), .bi(C_PI_4_I), .pr(s3_r[7]), .pi(s3_i[7]));

    // // FIX: Renamed pass-through registers to avoid potential iverilog confusion and ensure clean compilation.
    // Pass-through with 4-cycle delay
    reg signed [`TOTAL_WIDTH-1:0] delayed_s2_s3_r [0:5][STAGE_LATENCY-1:0];
    reg signed [`TOTAL_WIDTH-1:0] delayed_s2_s3_i [0:5][STAGE_LATENCY-1:0];
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            for(j=0;j<6;j=j+1) for(i=0;i<STAGE_LATENCY;i=i+1) begin
                delayed_s2_s3_r[j][i] <= 0;
                delayed_s2_s3_i[j][i] <= 0;
            end
        end else begin
            delayed_s2_s3_r[0][0] <= s2_r[0]; delayed_s2_s3_i[0][0] <= s2_i[0]; 
            delayed_s2_s3_r[1][0] <= s2_r[1]; delayed_s2_s3_i[1][0] <= s2_i[1];
            delayed_s2_s3_r[2][0] <= s2_r[2]; delayed_s2_s3_i[2][0] <= s2_i[2]; 
            delayed_s2_s3_r[3][0] <= s2_r[3]; delayed_s2_s3_i[3][0] <= s2_i[3];
            delayed_s2_s3_r[4][0] <= s2_r[4]; delayed_s2_s3_i[4][0] <= s2_i[4]; 
            delayed_s2_s3_r[5][0] <= s2_r[6]; delayed_s2_s3_i[5][0] <= s2_i[6]; // This one is deliberately s2_r[6] to index 5.
            for(j=0;j<6;j=j+1) begin
                for(i=1;i<STAGE_LATENCY;i=i+1) begin
                    delayed_s2_s3_r[j][i] <= delayed_s2_s3_r[j][i-1];
                    delayed_s2_s3_i[j][i] <= delayed_s2_s3_i[j][i-1];
                end
            end
        end
    end
    // // FIX: Updated assignments to use the new renamed pass-through registers.
    assign s3_r[0] = delayed_s2_s3_r[0][STAGE_LATENCY-1]; assign s3_i[0] = delayed_s2_s3_i[0][STAGE_LATENCY-1];
    assign s3_r[1] = delayed_s2_s3_r[1][STAGE_LATENCY-1]; assign s3_i[1] = delayed_s2_s3_i[1][STAGE_LATENCY-1];
    assign s3_r[2] = delayed_s2_s3_r[2][STAGE_LATENCY-1]; assign s3_i[2] = delayed_s2_s3_i[2][STAGE_LATENCY-1];
    assign s3_r[3] = delayed_s2_s3_r[3][STAGE_LATENCY-1]; assign s3_i[3] = delayed_s2_s3_i[3][STAGE_LATENCY-1];
    assign s3_r[4] = delayed_s2_s3_r[4][STAGE_LATENCY-1]; assign s3_i[4] = delayed_s2_s3_i[4][STAGE_LATENCY-1];
    assign s3_r[6] = delayed_s2_s3_r[5][STAGE_LATENCY-1]; assign s3_i[6] = delayed_s2_s3_i[5][STAGE_LATENCY-1]; // This is where s3_r[6] receives from delayed_s2_s3_r[5].

    // --- STAGE 4: H on q1 (bit 1) --- Latency: 4 ---
    h_gate_simplified h_q1_p0 (.clk(clk), .rst_n(rst_n), .alpha_r(s3_r[0]), .alpha_i(s3_i[0]), .beta_r(s3_r[2]), .beta_i(s3_i[2]), .new_alpha_r(s4_r[0]), .new_alpha_i(s4_i[0]), .new_beta_r(s4_r[2]), .new_beta_i(s4_i[2]));
    h_gate_simplified h_q1_p1 (.clk(clk), .rst_n(rst_n), .alpha_r(s3_r[1]), .alpha_i(s3_i[1]), .beta_r(s3_r[3]), .beta_i(s3_i[3]), .new_alpha_r(s4_r[1]), .new_alpha_i(s4_i[1]), .new_beta_r(s4_r[3]), .new_beta_i(s4_i[3]));
    h_gate_simplified h_q1_p2 (.clk(clk), .rst_n(rst_n), .alpha_r(s3_r[4]), .alpha_i(s3_i[4]), .beta_r(s3_r[6]), .beta_i(s3_i[6]), .new_alpha_r(s4_r[4]), .new_alpha_i(s4_i[4]), .new_beta_r(s4_r[6]), .new_beta_i(s4_i[6]));
    h_gate_simplified h_q1_p3 (.clk(clk), .rst_n(rst_n), .alpha_r(s3_r[5]), .alpha_i(s3_i[5]), .beta_r(s3_r[7]), .beta_i(s3_i[7]), .new_alpha_r(s4_r[5]), .new_alpha_i(s4_i[5]), .new_beta_r(s4_r[7]), .new_beta_i(s4_i[7]));

    // --- STAGE 5: CROT(π/2) from q0 to q1 --- Latency: 4 ---
    ccmult_pipelined c10_p0 (.clk(clk), .rst_n(rst_n), .ar(s4_r[3]), .ai(s4_i[3]), .br(C_PI_2_R), .bi(C_PI_2_I), .pr(s5_r[3]), .pi(s5_i[3]));
    ccmult_pipelined c10_p1 (.clk(clk), .rst_n(rst_n), .ar(s4_r[7]), .ai(s4_i[7]), .br(C_PI_2_R), .bi(C_PI_2_I), .pr(s5_r[7]), .pi(s5_i[7]));

    // // FIX: Renamed pass-through registers to avoid potential iverilog confusion and ensure clean compilation.
    // Pass-through with 4-cycle delay
    reg signed [`TOTAL_WIDTH-1:0] delayed_s4_s5_r [0:5][STAGE_LATENCY-1:0];
    reg signed [`TOTAL_WIDTH-1:0] delayed_s4_s5_i [0:5][STAGE_LATENCY-1:0];
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            for(j=0;j<6;j=j+1) for(i=0;i<STAGE_LATENCY;i=i+1) begin
                delayed_s4_s5_r[j][i] <= 0;
                delayed_s4_s5_i[j][i] <= 0;
            end
        end else begin
            delayed_s4_s5_r[0][0] <= s4_r[0]; delayed_s4_s5_i[0][0] <= s4_i[0]; 
            delayed_s4_s5_r[1][0] <= s4_r[1]; delayed_s4_s5_i[1][0] <= s4_i[1];
            delayed_s4_s5_r[2][0] <= s4_r[2]; delayed_s4_s5_i[2][0] <= s4_i[2]; 
            delayed_s4_s5_r[3][0] <= s4_r[4]; delayed_s4_s5_i[3][0] <= s4_i[4]; // s4_r[4] to index 3
            delayed_s4_s5_r[4][0] <= s4_r[5]; delayed_s4_s5_i[4][0] <= s4_i[5]; 
            delayed_s4_s5_r[5][0] <= s4_r[6]; delayed_s4_s5_i[5][0] <= s4_i[6];
            for(j=0;j<6;j=j+1) begin
                for(i=1;i<STAGE_LATENCY;i=i+1) begin
                    delayed_s4_s5_r[j][i] <= delayed_s4_s5_r[j][i-1];
                    delayed_s4_s5_i[j][i] <= delayed_s4_s5_i[j][i-1];
                end
            end
        end
    end
    // // FIX: Updated assignments to use the new renamed pass-through registers.
    assign s5_r[0] = delayed_s4_s5_r[0][STAGE_LATENCY-1]; assign s5_i[0] = delayed_s4_s5_i[0][STAGE_LATENCY-1];
    assign s5_r[1] = delayed_s4_s5_r[1][STAGE_LATENCY-1]; assign s5_i[1] = delayed_s4_s5_i[1][STAGE_LATENCY-1];
    assign s5_r[2] = delayed_s4_s5_r[2][STAGE_LATENCY-1]; assign s5_i[2] = delayed_s4_s5_i[2][STAGE_LATENCY-1];
    assign s5_r[4] = delayed_s4_s5_r[3][STAGE_LATENCY-1]; assign s5_i[4] = delayed_s4_s5_i[3][STAGE_LATENCY-1]; // s5_r[4] receives from delayed_s4_s5_r[3]
    assign s5_r[5] = delayed_s4_s5_r[4][STAGE_LATENCY-1]; assign s5_i[5] = delayed_s4_s5_i[4][STAGE_LATENCY-1];
    assign s5_r[6] = delayed_s4_s5_r[5][STAGE_LATENCY-1]; assign s5_i[6] = delayed_s4_s5_i[5][STAGE_LATENCY-1];

    // --- STAGE 6: H on q0 (bit 0) --- Latency: 4 ---
    h_gate_simplified h_q0_p0 (.clk(clk), .rst_n(rst_n), .alpha_r(s5_r[0]), .alpha_i(s5_i[0]), .beta_r(s5_r[1]), .beta_i(s5_i[1]), .new_alpha_r(s6_r[0]), .new_alpha_i(s6_i[0]), .new_beta_r(s6_r[1]), .new_beta_i(s6_i[1]));
    h_gate_simplified h_q0_p1 (.clk(clk), .rst_n(rst_n), .alpha_r(s5_r[2]), .alpha_i(s5_i[2]), .beta_r(s5_r[3]), .beta_i(s5_i[3]), .new_alpha_r(s6_r[2]), .new_alpha_i(s6_i[2]), .new_beta_r(s6_r[3]), .new_beta_i(s6_i[3]));
    h_gate_simplified h_q0_p2 (.clk(clk), .rst_n(rst_n), .alpha_r(s5_r[4]), .alpha_i(s5_i[4]), .beta_r(s5_r[5]), .beta_i(s5_i[5]), .new_alpha_r(s6_r[4]), .new_alpha_i(s6_i[4]), .new_beta_r(s6_r[5]), .new_beta_i(s6_i[5]));
    h_gate_simplified h_q0_p3 (.clk(clk), .rst_n(rst_n), .alpha_r(s5_r[6]), .alpha_i(s5_i[6]), .beta_r(s5_r[7]), .beta_i(s5_i[7]), .new_alpha_r(s6_r[6]), .new_alpha_i(s6_i[6]), .new_beta_r(s6_r[7]), .new_beta_i(s6_i[7]));

    // --- STAGE 7: SWAP q0 and q2 (Bit Reversal) --- Latency: 1 ---
    swap_gate_pipelined final_swap (
        .clk(clk), .rst_n(rst_n),
        .in_001_r(s6_r[1]), .in_001_i(s6_i[1]), .in_100_r(s6_r[4]), .in_100_i(s6_i[4]),
        .in_011_r(s6_r[3]), .in_011_i(s6_i[3]), .in_110_r(s6_r[6]), .in_110_i(s6_i[6]),
        .out_001_r(f001_r), .out_001_i(f001_i),
        .out_100_r(f100_r), .out_100_i(f100_i),
        .out_011_r(f011_r), .out_011_i(f011_i),
        .out_110_r(f110_r), .out_110_i(f110_i)
    );
    // Pass-through the amplitudes not affected by swap, with a 1-cycle delay to match SWAP latency.
    reg signed [`TOTAL_WIDTH-1:0] f000_r_reg, f000_i_reg;
    reg signed [`TOTAL_WIDTH-1:0] f010_r_reg, f010_i_reg;
    reg signed [`TOTAL_WIDTH-1:0] f101_r_reg, f101_i_reg;
    reg signed [`TOTAL_WIDTH-1:0] f111_r_reg, f111_i_reg;

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            f000_r_reg <= 0; f000_i_reg <= 0;
            f010_r_reg <= 0; f010_i_reg <= 0;
            f101_r_reg <= 0; f101_i_reg <= 0;
            f111_r_reg <= 0; f111_i_reg <= 0;
        end else begin
            f000_r_reg <= s6_r[0]; f000_i_reg <= s6_i[0];
            f010_r_reg <= s6_r[2]; f010_i_reg <= s6_i[2];
            f101_r_reg <= s6_r[5]; f101_i_reg <= s6_i[5];
            f111_r_reg <= s6_r[7]; f111_i_reg <= s6_i[7];
        end
    end

    assign f000_r = f000_r_reg; assign f000_i = f000_i_reg;
    assign f010_r = f010_r_reg; assign f010_i = f010_i_reg;
    assign f101_r = f101_r_reg; assign f101_i = f101_i_reg;
    assign f111_r = f111_r_reg; assign f111_i = f111_i_reg;

endmodule
