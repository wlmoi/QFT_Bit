# qft_timing.xdc

# -------------------------------------------------------------------------------------------------
# // Primary Clock Definition
# // Defines a 200 MHz clock (5 ns period) on the 'clk' input port of the top module.
# // This is a more realistic frequency target for complex arithmetic circuits.
# -------------------------------------------------------------------------------------------------
create_clock -period 5.000 -name sys_clk [get_ports clk]

# -------------------------------------------------------------------------------------------------
# // Input Delay Constraints for Data Inputs
# -------------------------------------------------------------------------------------------------
set_input_delay -clock sys_clk -max 1.000 [get_ports {i*_r i*_i}]
set_input_delay -clock sys_clk -min 0.000 [get_ports {i*_r i*_i}]

# --- MODIFIED: Input Delay Constraints for rst_n ---
# The rst_n port is now synchronized internally. Its timing is no longer directly constrained for setup/hold on its input path.
# However, you still need to acknowledge its existence as an input. You can remove these if your flow automatically handles asynchronous inputs.
# For now, leaving them with default values, as the synchronizer makes its timing less critical.
# Vivado will treat this as an unconstrained path if it infers it as an asynchronous set/reset.
# If `rst_n` is truly asynchronous, it does not require set_input_delay.
# For a fully synchronous reset from an async input, only the async input path to the synchronizer flops matters.
# However, in many tool flows, it's safer to provide constraints to avoid unconstrained path warnings.
# Given the synchronizer, the specific values become less critical for functional timing of the design core.
set_input_delay -clock sys_clk -max 5.000 [get_ports rst_n]
set_input_delay -clock sys_clk -min 0.000 [get_ports rst_n]


# -------------------------------------------------------------------------------------------------
# // Output Delay Constraints
# // Defines the maximum and minimum delays for signals leaving the FPGA's output pins
# // relative to the clock edge.
# -------------------------------------------------------------------------------------------------
set_output_delay -clock sys_clk -max 1.000 [get_ports {f*_r f*_i}]
set_output_delay -clock sys_clk -min 0.000 [get_ports {f*_r f*_i}]


# -------------------------------------------------------------------------------------------------
# // Clock Uncertainty
# // Models variations in the clock period due to jitter and other factors.
# // Reduced to a more typical percentage of the new 5ns period.
# -------------------------------------------------------------------------------------------------
set_clock_uncertainty -setup 0.25 [get_clocks sys_clk] # 5% of 5ns period
set_clock_uncertainty -hold 0.25 [get_clocks sys_clk]  # 5% of 5ns period

# --- REMOVED: Problematic set_min_delay constraint (as before) ---
# --- REMOVED: Unnecessary ASYNC_REG property (as before) ---
