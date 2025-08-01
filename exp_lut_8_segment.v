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

    // Function to convert real number to fixed-point integer representation
    function signed [`TOTAL_BITS-1:0] float_to_fixed_local;
        input real float_val;
        begin
            float_to_fixed_local = $rtoi(float_val * (1 << `FX_BITS));
            // Apply saturation if the result exceeds the fixed-point range
            if (float_val * (1 << `FX_BITS) > ((1 << (`TOTAL_BITS-1)) - 1))
                float_to_fixed_local = (1 << (`TOTAL_BITS-1)) - 1;
            else if (float_val * (1 << `FX_BITS) < -(1 << (`TOTAL_BITS-1))) 
                float_to_fixed_local = -(1 << (`TOTAL_BITS-1));
        end
    endfunction

    // Fungsi baru: Mengubah pola bit dari nilai signed menjadi indeks unsigned
    function [`TOTAL_BITS-1:0] signed_to_unsigned_index;
        input signed [`TOTAL_BITS-1:0] signed_input;
        begin
            // Cukup menginterpretasikan ulang pola bit sebagai unsigned
            signed_to_unsigned_index = signed_input; 
        end
    endfunction

    initial begin
        integer i; 

        for (i = 0; i < LUT_SIZE; i = i + 1) begin
            real x_real;
            real exp_x_real;
            
            // Ketika 'i' diteruskan ke fixed_to_float_local, yang mengharapkan signed [`TOTAL_BITS-1:0`],
            // Verilog dengan benar menginterpretasikan pola bit dari 'i' sebagai angka fixed-point signed.
            // Misalnya, jika i=240 (8'hF0), itu diinterpretasikan sebagai -1.0.
            x_real = fixed_to_float_local(i); 

            exp_x_real = $exp(x_real); // Hitung e^x

            // Simpan hasilnya pada indeks unsigned 'i'
            lut_data[i] = float_to_fixed_local(exp_x_real);
        end
    end

    // Gunakan fungsi konversi eksplisit untuk pengindeksan array
    assign exp_x_out = lut_data[signed_to_unsigned_index(x_in)];

endmodule
`endif // EXP_LUT_8_SEGMENT_V
