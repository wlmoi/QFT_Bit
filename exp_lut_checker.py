import math

# --- PARAMETER KONFIGURASI FIXED-POINT ---
# Ubah nilai-nilai ini untuk melihat bagaimana format fixed-point memengaruhi hasilnya.
# Pastikan (FX_BITS + INT_BITS + 1) == TOTAL_BITS (misalnya 8)
TOTAL_BITS = 8
FX_BITS = 4  # Jumlah bit pecahan (misalnya 4 untuk S_3.4, 2 untuk S_5.2, 0 untuk S_7.0)
INT_BITS = TOTAL_BITS - FX_BITS - 1 # Jumlah bit integer (akan dihitung otomatis)


# Format: S_INT_BITS.FX_BITS (misalnya, S_3.4 berarti 1 sign bit, 3 integer bits, 4 fractional bits)


def float_to_fixed(value_float):
    """
    Mengkonversi bilangan floating-point ke representasi integer fixed-point bertanda.
    Menangani saturasi untuk nilai di luar rentang yang dapat direpresentasikan.
    """
    # Menghitung nilai representable maksimum dan minimum untuk format fixed-point
    max_fixed_int = (1 << (TOTAL_BITS - 1)) - 1
    min_fixed_int = -(1 << (TOTAL_BITS - 1))

    # Skalakan nilai float dengan 2^FX_BITS dan bulatkan ke integer terdekat
    scaled_value = round(value_float * (1 << FX_BITS))
    
    # Saturasi jika nilai yang diskalakan melebihi rentang integer fixed-point
    if scaled_value > max_fixed_int:
        return max_fixed_int
    elif scaled_value < min_fixed_int:
        return min_fixed_int
    
    return scaled_value

def fixed_to_float(value_fixed):
    """
    Mengkonversi representasi integer fixed-point bertanda ke bilangan floating-point.
    Mengasumsikan value_fixed sudah merupakan integer bertanda Python yang mewakili nilai 2's complement.
    """
    return value_fixed / (1 << FX_BITS)

def get_exp_lut_8_segment_verilog_values():
    """
    Mengembalikan data LUT seperti yang didefinisikan dalam modul Verilog `exp_lut_8_segment.v`.
    Nilai dalam representasi integer fixed-point (diskalakan dengan 2^FX_BITS).
    """
    # Ini adalah *nilai integer fixed-point* langsung dari modul Verilog Anda
    # Nilai-nilai ini adalah konstanta, tidak berubah dengan FX_BITS.
    # Interpretasi float-nya yang akan berubah.
    return [
        16,   # Nilai integer fixed-point untuk e^0.0
        20,   # Nilai integer fixed-point untuk e^0.25 (approx)
        26,   # Nilai integer fixed-point untuk e^0.5 (approx)
        34,   # Nilai integer fixed-point untuk e^0.75 (approx)
        44,   # Nilai integer fixed-point untuk e^1.0 (approx)
        56,   # Nilai integer fixed-point untuk e^1.25 (approx)
        63,   # Saturasi ke nilai maks positive fixed-point
        63    # Saturasi ke nilai maks positive fixed-point
    ]

def exp_lut_8_segment_python(x_float):
    """
    Model Python yang mereplikasi perilaku modul Verilog `exp_lut_8_segment`.
    Memperkirakan e^x menggunakan tabel lookup dan aritmatika fixed-point.
    """
    x_in_fixed = float_to_fixed(x_float)
    
    # Mereplikasi penanganan input negatif Verilog:
    # Mengembalikan 0.0 (fixed-point 0) untuk input negatif, sesuai interpretasi logis.
    # Jika perlu mereplikasi `TOTAL_BITS'h080` (-8.0) secara ketat, ubah fixed_to_float(0)
    # menjadi fixed_to_float(-(1 << (TOTAL_BITS-1))) jika TOTAL_BITS'h080 berarti min_fixed_int.
    # Atau jika TOTAL_BITS'h080 adalah literal numerik, bisa fixed_to_float(int('0x80', 16) - (1<<TOTAL_BITS)) jika 8 bit.
    if x_in_fixed < 0: 
        return fixed_to_float(0)

    lut_data = get_exp_lut_8_segment_verilog_values()

    # Mendapatkan indeks LUT dari bagian integer nilai fixed-point input.
    lut_index = (x_in_fixed >> FX_BITS) 
    
    # Pastikan indeks tidak melebihi batas array LUT.
    if lut_index >= len(lut_data):
        lut_index = len(lut_data) - 1 # Saturasi indeks ke maksimum yang tersedia.

    exp_x_out_fixed = lut_data[lut_index]
    
    return fixed_to_float(exp_x_out_fixed)

if __name__ == "__main__":
    print(f"Fixed-point format: S_{INT_BITS}.{FX_BITS} (Total {TOTAL_BITS} bits)")
    # Cetak rentang representable
    max_fixed_val = (1 << (TOTAL_BITS - 1)) - 1
    min_fixed_val = -(1 << (TOTAL_BITS - 1))
    
    print(f"Max positive representable: {fixed_to_float(max_fixed_val):.4f}")
    print(f"Min negative representable: {fixed_to_float(min_fixed_val):.4f}")

    print("\n--- Menguji konversi float_to_fixed dan fixed_to_float ---")
    test_values = [0.0, 0.5, 0.9375, 1.0, 1.25, 1.9375, 2.0, 3.14, 3.9375, 4.0, -0.5, -1.0, -3.9375, -4.0, -5.0, 7.9375, 8.0, -8.0, -8.1]
    for val in test_values:
        fixed_val = float_to_fixed(val)
        float_val_converted = fixed_to_float(fixed_val)
        # Untuk mendapatkan string biner 2's complement:
        if fixed_val < 0:
            bin_rep = bin((1 << TOTAL_BITS) + fixed_val)[2:].zfill(TOTAL_BITS)
        else:
            bin_rep = bin(fixed_val)[2:].zfill(TOTAL_BITS)
            
        print(f"Float: {val: 7.4f} -> Fixed: {fixed_val: 5d} (0b{bin_rep}) -> Re-converted Float: {float_val_converted: 7.4f}")

    print("\n--- Menguji exp_lut_8_segment_python (meniru perilaku Verilog) ---")
    
    # Cetak data LUT Verilog dalam representasi fixed-point dan float
    lut_data_fixed = get_exp_lut_8_segment_verilog_values()
    print("\nData LUT Verilog (nilai integer fixed-point):", lut_data_fixed)
    print("Data LUT Verilog (nilai float):", [fixed_to_float(val) for val in lut_data_fixed])

    # Nilai uji untuk x_float, mencakup rentang positif dan negatif
    exp_test_values = [
        -5.0, -4.0, -3.0, -2.0, -1.0, -0.5, -0.01, # Nilai negatif
        0.0, 0.1, 0.25, 0.49, 0.5, 0.74, 0.75, 0.99, # Segmen pertama
        1.0, 1.25, 1.49, 1.5, 1.74, 1.75, 1.99, # Segmen lainnya
        2.0, 2.5, 3.0, 3.5, 3.9375, 4.0, 5.0, 7.0, 7.9375, 8.0 # Saturasi
    ]

    print("\nInput (x) | x_fixed | Index | Output LUT (float) | Math.exp(x) | Perbedaan")
    print("----------|---------|-------|--------------------|-------------|-----------")
    for x_val in exp_test_values:
        x_in_fixed = float_to_fixed(x_val)
        lut_output_float = exp_lut_8_segment_python(x_val)
        
        # Tentukan indeks efektif yang akan digunakan Verilog untuk x_in_fixed positif
        effective_index = "N/A (Neg)"
        if x_in_fixed >= 0:
            raw_index = (x_in_fixed >> FX_BITS)
            if raw_index >= len(lut_data_fixed):
                effective_index = len(lut_data_fixed) - 1
            else:
                effective_index = raw_index
        
        expected_math_exp = math.exp(x_val)
        difference = lut_output_float - expected_math_exp
        
        print(f"{x_val: 9.4f} | {x_in_fixed: 7d} | {effective_index!s:<5} | {lut_output_float: 17.4f} | {expected_math_exp: 11.4f} | {difference: 10.4f}")
        
    print("\nCatatan pada perilaku `exp_lut_8_segment_python`:")
    print("- Input negatif dipetakan ke 0.0 (fixed-point 0) dalam model Python ini, berdasarkan interpretasi logis dari maksud kode Verilog untuk perilaku e^x. Jika literal Verilog `TOTAL_BITS'h080` (fixed-point -8.0) secara ketat dimaksudkan untuk input negatif, perbedaannya akan lebih besar lagi.")
    print("- Input positif akan menggunakan indeks yang berasal dari bagian integernya (misalnya, x.XXX -> bagian integer X untuk pengindeksan). Ini menyebabkan semua nilai dalam rentang bagian integer yang sama dipetakan ke entri LUT yang sama.")
    print("- Input yang mengarah ke bagian integer (indeks) 6 atau lebih tinggi akan saturasi ke nilai fixed-point positif maksimum (3.9375) berdasarkan nilai LUT Verilog.")
    print("- LUT ini adalah perkiraan yang sangat kasar (hanya 8 output diskrit untuk input positif) dan karenanya menunjukkan perbedaan yang signifikan dari `math.exp()` untuk sebagian besar input, terutama di luar rentang awal yang sangat sempit.")
    print("- Untuk meningkatkan akurasi untuk rentang {-5, 5}, lebar bit yang jauh lebih luas (misalnya, 16-bit atau 32-bit float/fixed), lebih banyak segmen LUT, interpolasi, dan penanganan eksplisit eksponen negatif (misalnya, e^(-x) = 1/e^x) akan diperlukan.")

