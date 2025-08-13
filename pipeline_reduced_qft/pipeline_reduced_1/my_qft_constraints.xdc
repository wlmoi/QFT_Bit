# my_qft_constraints.xdc
# File Batasan Vivado untuk Desain QFT 3-Qubit Anda

# ==============================================================================
# CATATAN PENTING:
# - Ukuran Chip (0.795mm x 0.815mm) dan Peringatan Antena (Rule 9)
#   adalah metrik untuk desain ASIC, BUKAN FPGA.
#   Vivado (untuk FPGA) tidak menggunakan batasan ukuran milimeter ini.
#   Peringatan antena juga tidak relevan untuk alur desain FPGA.
#   Anda akan memilih PART NUMBER FPGA yang sesuai yang memiliki sumber daya
#   (LUTs, FFs, DSPs, Block RAMs) yang cukup untuk desain Anda.
# ==============================================================================

# 1. Definisi Clock Utama (PENTING!)
# ==================================
# Ini adalah batasan PALING PENTING untuk membuat WNS dapat dihitung.
# Definisikan clock 'clk' pada port 'clk' dengan periode 1000 ns (1 MHz).
# Vivado akan menggunakan ini sebagai target timing Anda.
create_clock -period 1000.000 -name clk_core -waveform {0.000 500.000} [get_ports clk]

# 2. Clock Uncertainty (PENTING untuk STA yang Realistis!)
# ====================================
# Ini mewakili 'ketidaksempurnaan' clock seperti jitter dan skew yang tidak diketahui.
# Selalu tambahkan ini agar analisis timing realistis.
# Nilai umum adalah 5-10% dari periode clock. Untuk 1000ns, 50ns adalah titik awal yang baik.
set_clock_uncertainty -setup 50.000 [get_clocks clk_core]
set_clock_uncertainty -hold 50.000 [get_clocks clk_core]

# 3. Input/Output Delay Constraints (PENTING untuk Port I/O!)
# ====================================================
# Ini memodelkan penundaan sinyal saat masuk/keluar dari FPGA Anda,
# yang disebabkan oleh sirkuit eksternal di papan Anda.
# Tanpa ini, jalur I/O akan 'unconstrained' atau dianggap terlalu cepat/lambat.
# Sesuaikan nilai ini berdasarkan timing dari komponen eksternal Anda.
# Misalnya, 10-20% dari periode clock untuk awal.
set_input_delay -clock clk_core -min 100.000 [all_inputs]
set_input_delay -clock clk_core -max 200.000 [all_inputs]
set_output_delay -clock clk_core -min 100.000 [all_outputs]
set_output_delay -clock clk_core -max 200.000 [all_outputs]

# 4. Batasan Fisik Pin (SANGAT PENTING untuk FPGA agar bisa dirute!)
# ==========================================================
# Ini memberitahu Vivado pin fisik mana di chip FPGA Anda yang harus dihubungkan
# dengan port RTL Anda. TANPA INI, Vivado TIDAK BISA menyelesaikan perutean dan implementasi.
# Anda HARUS mengganti 'YOUR_FPGA_PIN_NAME' dan 'YOUR_IO_STANDARD'
# dengan nilai yang benar dari buku panduan papan pengembangan FPGA Anda.
#
# Contoh untuk port 'clk' dan 'rst_n':
# set_property PACKAGE_PIN <YOUR_FPGA_PIN_NAME_FOR_CLK> [get_ports clk]
# set_property IOSTANDARD <YOUR_IO_STANDARD> [get_ports clk]
# set_property PACKAGE_PIN <YOUR_FPGA_PIN_NAME_FOR_RSTN> [get_ports rst_n]
# set_property IOSTANDARD <YOUR_IO_STANDARD> [get_ports rst_n]
#
# Dan seterusnya untuk SEMUA port input (i000_r, i000_i, ..., i111_i)
# dan SEMUA port output (f000_r, f000_i, ..., f111_i).
# Ini akan menjadi daftar panjang. Misalnya:
# set_property PACKAGE_PIN A1 [get_ports {i000_r[0]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {i000_r[0]}]
# set_property PACKAGE_PIN A2 [get_ports {i000_r[1]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {i000_r[1]}]
# ... dan seterusnya untuk setiap bit dari setiap bus ...
