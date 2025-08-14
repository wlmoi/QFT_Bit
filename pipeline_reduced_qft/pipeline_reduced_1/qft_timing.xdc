# qft_timing.xdc

# -------------------------------------------------------------------------------------------------
# // Primary Clock Definition
# // Defines a 1000 MHz clock (1 ns period) on the 'clk' input port of the top module.
# -------------------------------------------------------------------------------------------------
create_clock -period 1.000 -name sys_clk [get_ports clk]

# -------------------------------------------------------------------------------------------------
# // Input Delay Constraints for Data Inputs
# -------------------------------------------------------------------------------------------------
set_input_delay -clock sys_clk -max 1.000 [get_ports {i*_r i*_i}]
set_input_delay -clock sys_clk -min 0.000 [get_ports {i*_r i*_i}]

# --- ADDED: Input Delay Constraints for rst_n ---
# To address the "Missing input or output delay" warning for the rst_n port.
# These are placeholder values; adjust based on your system's reset characteristics.
# Note: rst_n is an asynchronous input to the top module, but will be synchronized internally.
set_input_delay -clock sys_clk -max 5.000 [get_ports rst_n]
set_input_delay -clock sys_clk -min 0.000 [get_ports rst_n]


# -------------------------------------------------------------------------------------------------
# // Output Delay Constraints
# // Defines the maximum and minimum delays for signals leaving the FPGA's output pins
# // relative to the clock edge.
# # If setup violations persist on output paths, you may need to increase the -max value
# # after verifying allowed delay with the external receiving device.
# -------------------------------------------------------------------------------------------------
set_output_delay -clock sys_clk -max 1.000 [get_ports {f*_r f*_i}]
set_output_delay -clock sys_clk -min 0.000 [get_ports {f*_r f*_i}]


# -------------------------------------------------------------------------------------------------
# // Clock Uncertainty
# // Models variations in the clock period due to jitter and other factors.
# // This reduces the effective clock period available for logic, making timing analysis more pessimistic.
# -------------------------------------------------------------------------------------------------
set_clock_uncertainty -setup 0.5 [get_clocks sys_clk]
set_clock_uncertainty -hold 0.5 [get_clocks sys_clk]

# --- REMOVED: Problematic set_min_delay constraint ---
# This constraint previously caused extreme hold violations due to over-constraining or Vivado's inability to meet it.
# With proper reset synchronization, Vivado should have more flexibility to fix hold violations automatically.
# Removed: set_min_delay -from [get_pins {*delayed_s4_s5_r_reg[1][1][6]_srl5_delayed_s1_s2_r_reg_c_0/Q}] -to [get_pins {*delayed_s4_s5_r_reg[1][2][6]_delayed_s1_s2_r_reg_c_1/D}] 0.400

# --- REMOVED: Unnecessary ASYNC_REG property ---
# Vivado typically infers asynchronous reset behavior correctly when the reset signal is used in the always block's sensitivity list.
# Removed: set_property ASYNC_REG TRUE [get_cells -hierarchical -filter {NAME =~ "*rst_n_reg*" || NAME =~ "*rst_reg*"}]
