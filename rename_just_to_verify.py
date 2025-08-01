import math

# --- PARAMETER KONFIGURASI FIXED-POINT (Akan diubah dalam loop) ---
# Ini akan didefinisikan ulang di dalam loop untuk setiap kombinasi bit.
TOTAL_BITS = 8
FX_BITS = 0 # Placeholder, akan diatur dalam loop
INT_BITS = 0 # Placeholder, akan diatur dalam loop


# Format: S_INT_BITS.FX_BITS (misalnya, S_3.4 berarti 1 sign bit, 3 integer bits, 4 fractional bits)


def float_to_fixed(value_float, current_fx_bits, current_total_bits):
    """
    Mengkonversi bilangan floating-point ke representasi integer fixed-point bertanda.
    Menangani saturasi untuk nilai di luar rentang yang dapat direpresentasikan.
    """
    # Menghitung nilai representable maksimum dan minimum untuk format fixed-point
    max_fixed_int = (1 << (current_total_bits - 1)) - 1
    min_fixed_int = -(1 << (current_total_bits - 1))

    # Skalakan nilai float dengan 2^FX_BITS dan bulatkan ke integer terdekat
    scaled_value = round(value_float * (1 << current_fx_bits))
    
    # Saturasi jika nilai yang diskalakan melebihi rentang integer fixed-point
    if scaled_value > max_fixed_int:
        return max_fixed_int
    elif scaled_value < min_fixed_int:
        return min_fixed_int
    
    return scaled_value

def fixed_to_float(value_fixed, current_fx_bits):
    """
    Mengkonversi representasi integer fixed-point bertanda ke bilangan floating-point.
    Mengasumsikan value_fixed sudah merupakan integer bertanda Python yang mewakili nilai 2's complement.
    """
    return value_fixed / (1 << current_fx_bits)

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

def exp_lut_8_segment_python(x_float, current_fx_bits, current_total_bits):
    """
    Model Python yang mereplikasi perilaku modul Verilog `exp_lut_8_segment`.
    Memperkirakan e^x menggunakan tabel lookup dan aritmatika fixed-point.
    """
    x_in_fixed = float_to_fixed(x_float, current_fx_bits, current_total_bits)
    
    # Mereplikasi penanganan input negatif Verilog:
    # Mengembalikan 0.0 (fixed-point 0) untuk input negatif, sesuai interpretasi logis.
    if x_in_fixed < 0: 
        return fixed_to_float(0, current_fx_bits)

    lut_data = get_exp_lut_8_segment_verilog_values()

    # Mendapatkan indeks LUT dari bagian integer nilai fixed-point input.
    # Ingat, pergeseran >> FX_BITS berarti kita "membuang" bit pecahan untuk mendapatkan bagian integer.
    lut_index = (x_in_fixed >> current_fx_bits) 
    
    # Pastikan indeks tidak melebihi batas array LUT.
    if lut_index >= len(lut_data):
        lut_index = len(lut_data) - 1 # Saturasi indeks ke maksimum yang tersedia.

    exp_x_out_fixed = lut_data[lut_index]
    
    return fixed_to_float(exp_x_out_fixed, current_fx_bits)

if __name__ == "__main__":
    GLOBAL_TOTAL_BITS = 8 # Menjaga total bit konstan untuk demonstrasi ini

    print(f"Demonstrasi Konversi Fixed-Point untuk TOTAL_BITS = {GLOBAL_TOTAL_BITS}\n")

    # Nilai tetap yang ingin kita uji bagaimana konversinya berubah dengan FX_BITS
    test_fixed_val = 43 
    
    # Nilai float yang akan kita konversi ke fixed-point
    test_float_values = [0.0, 0.5, 1.0, 2.0, 3.14, 7.9, -0.5, -4.0, -8.0]

    # Iterasi melalui semua kemungkinan kombinasi FX_BITS
    # FX_BITS dapat berkisar dari 0 (semua integer, kecuali sign) hingga TOTAL_BITS - 1 (semua pecahan, kecuali sign)
    for current_fx_bits in range(GLOBAL_TOTAL_BITS):
        current_int_bits = GLOBAL_TOTAL_BITS - current_fx_bits - 1
        
        # Hanya melanjutkan jika ada setidaknya 1 bit untuk integer atau pecahan (selain sign)
        # Atau jika FX_BITS = 0, INT_BITS bisa menjadi TOTAL_BITS - 1
        # Atau jika INT_BITS = 0, FX_BITS bisa menjadi TOTAL_BITS - 1
        if current_int_bits < 0: # Ini tidak boleh terjadi dengan range(GLOBAL_TOTAL_BITS)
            continue 

        print(f"\n--- FORMAT: S_{current_int_bits}.{current_fx_bits} (Total {GLOBAL_TOTAL_BITS} bits) ---")
        
        # Hitung dan cetak rentang representable untuk format saat ini
        max_fixed_representable_int_val = (1 << (GLOBAL_TOTAL_BITS - 1)) - 1
        min_fixed_representable_int_val = -(1 << (GLOBAL_TOTAL_BITS - 1))
        
        max_float_representable = fixed_to_float(max_fixed_representable_int_val, current_fx_bits)
        min_float_representable = fixed_to_float(min_fixed_representable_int_val, current_fx_bits)
        
        print(f"  Max positif representable: {max_float_representable:.4f}")
        print(f"  Min negatif representable: {min_float_representable:.4f}")
        
        # Cetak nilai kuantisasi terkecil (presisi)
        quantization_step = 1 / (1 << current_fx_bits)
        print(f"  Langkah kuantisasi (presisi): {quantization_step:.4f}")


        print(f"  Konversi nilai fixed-point {test_fixed_val} ke float:")
        converted_float_from_fixed = fixed_to_float(test_fixed_val, current_fx_bits)
        print(f"    Fixed {test_fixed_val} (0b{bin(test_fixed_val & ((1 << GLOBAL_TOTAL_BITS) - 1))[2:].zfill(GLOBAL_TOTAL_BITS)}) -> Float: {converted_float_from_fixed:.4f}")
        
        if current_fx_bits == 4 and test_fixed_val == 43:
            print(f"    (Ini adalah contoh yang Anda sebutkan: 43 / (2^4) = 43 / 16 = 2.6875)")

        print("\n  Menguji konversi float_to_fixed dan fixed_to_float untuk berbagai nilai float:")
        for val in test_float_values:
            fixed_val_converted = float_to_fixed(val, current_fx_bits, GLOBAL_TOTAL_BITS)
            float_val_reconverted = fixed_to_float(fixed_val_converted, current_fx_bits)
            
            # Untuk mendapatkan string biner 2's complement:
            if fixed_val_converted < 0:
                bin_rep = bin((1 << GLOBAL_TOTAL_BITS) + fixed_val_converted)[2:].zfill(GLOBAL_TOTAL_BITS)
            else:
                bin_rep = bin(fixed_val_converted)[2:].zfill(GLOBAL_TOTAL_BITS)
                
            print(f"    Float: {val: 7.4f} -> Fixed: {fixed_val_converted: 5d} (0b{bin_rep}) -> Re-converted Float: {float_val_reconverted: 7.4f}")

        print("\n  Pengaruh pada exp_lut_8_segment_python:")
        lut_data_fixed = get_exp_lut_8_segment_verilog_values()
        print(f"    Nilai integer fixed-point dari LUT Verilog: {lut_data_fixed}")
        print(f"    Interpretasi float dari LUT Verilog dalam format ini: {[fixed_to_float(val, current_fx_bits) for val in lut_data_fixed]}")
        
        # Contoh satu atau dua pengujian dengan exp_lut_8_segment_python untuk format ini
        # Ini hanya untuk menunjukkan perubahan interpretasi, bukan menjalankan seluruh suite pengujian lagi.
        sample_x_vals = [0.0, 0.5, 1.0, 3.0]
        print("    Contoh keluaran `exp_lut_8_segment_python` dengan format ini:")
        for x_val in sample_x_vals:
            lut_output_float = exp_lut_8_segment_python(x_val, current_fx_bits, GLOBAL_TOTAL_BITS)
            expected_math_exp = math.exp(x_val)
            print(f"      e^{x_val:<5.2f} (Float Input) -> LUT Output: {lut_output_float: 8.4f} (Actual e^x: {expected_math_exp: 8.4f})")
    
    print("\n--- Ringkasan ---")
    print("Seperti yang dapat Anda lihat, dengan mengubah jumlah bit pecahan (FX_BITS), nilai integer fixed-point yang sama akan memiliki interpretasi float yang berbeda. Semakin banyak bit pecahan, semakin kecil rentang nilai yang dapat direpresentasikan, tetapi semakin tinggi presisinya (langkah kuantisasi lebih kecil). Sebaliknya, semakin sedikit bit pecahan, semakin besar rentang nilai yang dapat direpresentasikan, tetapi semakin rendah presisinya.")
    print("Nilai LUT Verilog (misalnya, [16, 20, ...]) adalah konstanta integer, tetapi nilai float yang mereka representasikan berubah secara dramatis tergantung pada konfigurasi FX_BITS saat ini.")
    print("Contoh fixed-point 43 menjadi 2.6875 hanya berlaku ketika FX_BITS disetel ke 4, seperti yang terlihat dalam output di atas.")

