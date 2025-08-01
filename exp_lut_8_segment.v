// exp_lut_8_segment.v
`ifndef EXP_LUT_8_SEGMENT_V
`define EXP_LUT_8_SEGMENT_V

`include "fixed_complex_utils.v" // Contains `define TOTAL_BITS, `define FX_BITS, `define INT_BITS

module exp_lut_8_segment(
    input signed [`TOTAL_BITS-1:0] x_in, // Fixed-point input for x
    output signed [`TOTAL_BITS-1:0] exp_x_out // Fixed-point output for e^x
);

    // Number of entries in the LUT will be 2^TOTAL_BITS
    localparam LUT_SIZE = 1 << `TOTAL_BITS; 

    // The LUT will hold fixed-point results for e^x
    reg signed [`TOTAL_BITS-1:0] lut_data [0 : LUT_SIZE - 1];

    // Function to convert fixed-point integer representation to real number
    function real fixed_to_float_local;
        // Input is explicitly signed and bit-width specified
        input signed [`TOTAL_BITS-1:0] fixed_val; 
        begin
            fixed_to_float_local = $itor(fixed_val) / (1 << `FX_BITS);
        end
    endfunction

    // Function to convert real number to fixed-point integer representation (TERNYATA INI BISA DIVERILOG LOL)
    function signed [`TOTAL_BITS-1:0] float_to_fixed_local;
        input real float_val;
        begin
            float_to_fixed_local = $rtoi(float_val * (1 << `FX_BITS));
            // Apply saturation if the result exceeds the fixed-point range
            if (float_val * (1 << `FX_BITS) > ((1 << (`TOTAL_BITS-1)) - 1))
                float_to_fixed_local = (1 << (`TOTAL_BITS-1)) - 1;
            else if (float_val * (1 << (`TOTAL_BITS-1)) < -(1 << (`TOTAL_BITS-1))) // Corrected potential typo here if it was for `FX_BITS` before
                float_to_fixed_local = -(1 << (`TOTAL_BITS-1));
        end
    endfunction

    initial begin
        // Declare loop variable 'i' as integer directly inside the initial block.
        // Karena 'integer' secara default sudah signed, kita bisa langsung menggunakannya.
        integer i; 

        for (i = 0; i < LUT_SIZE; i = i + 1) begin
            real x_real;
            real exp_x_real;
            
            // Langsung meneruskan 'i' ke fungsi.
            // Verilog akan secara implisit mentransmisikan bit pattern dari 'i'
            // ke tipe signed dengan lebar bit yang diharapkan oleh 'fixed_to_float_local'.
            x_real = fixed_to_float_local(i); 

            exp_x_real = $exp(x_real); // Calculate e^x

            // Convert the real result back to fixed-point and store in LUT
            lut_data[i] = float_to_fixed_local(exp_x_real);
        end
    end

    // The input `x_in` directly serves as the index for the LUT.
    // Verilog secara otomatis menangani pengindeksan.
    assign exp_x_out = lut_data[x_in];

endmodule
`endif // EXP_LUT_8_SEGMENT_V
