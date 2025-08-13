# qft_timing.xdc

# -------------------------------------------------------------------------------------------------
# // Primary Clock Definition
# // Defines a 100 MHz clock (10 ns period) on the 'clk' input port of the top module.
# // This is crucial for all subsequent timing analysis.
# // // FIX: Changed clock period from 1000.000 ns to 10.000 ns.
# -------------------------------------------------------------------------------------------------
create_clock -period 10.000 -name sys_clk [get_ports clk]

# -------------------------------------------------------------------------------------------------
# // Input Delay Constraints
# // Defines the maximum and minimum delays for signals arriving at the FPGA's input pins
# // relative to the clock edge. These are "external" constraints.
# // Assumes that data arrives no later than 1ns before the clock edge, and no earlier than 0ns.
# // Adjust these values based on your actual source synchronous interface or board timing.
# // // The glob pattern {i*_r i*_i} will match all real and imaginary input ports like i000_r, i001_i, etc.
# -------------------------------------------------------------------------------------------------
set_input_delay -clock sys_clk -max 1.000 [get_ports {i*_r i*_i}]
set_input_delay -clock sys_clk -min 0.000 [get_ports {i*_r i*_i}]

# -------------------------------------------------------------------------------------------------
# // Output Delay Constraints
# // Defines the maximum and minimum delays for signals leaving the FPGA's output pins
# // relative to the clock edge. These are also "external" constraints.
# // Assumes that the external device needs the data stable at least 1ns before its next clock.
# // Adjust these values based on your actual destination synchronous interface or board timing.
# // // The glob pattern {f*_r f*_i} will match all real and imaginary output ports like f000_r, f001_i, etc.
# -------------------------------------------------------------------------------------------------
set_output_delay -clock sys_clk -max 1.000 [get_ports {f*_r f*_i}]
set_output_delay -clock sys_clk -min 0.000 [get_ports {f*_r f*_i}]

# -------------------------------------------------------------------------------------------------
# // Clock Uncertainty
# // Models variations in the clock period due to jitter and other factors.
# // This reduces the effective clock period available for logic, making timing analysis more pessimistic.
# // A typical value is 5-10% of the clock period. For a 10ns period, 0.5ns is 5%.
# // // FIX: Ensure this value is correct and that the command syntax is not causing "too many positional options".
# -------------------------------------------------------------------------------------------------
set_clock_uncertainty -setup 0.5 [get_clocks sys_clk]
set_clock_uncertainty -hold 0.5 [get_clocks sys_clk]

# -------------------------------------------------------------------------------------------------
# // Asynchronous Reset Property
# // Informs the tools that 'rst_n' is an asynchronous reset. This is important for correct
# // reset path timing analysis and optimization.
# // // The filter matches any cell hierarchically that might contain 'rst_n_reg' or 'rst_reg' in its name.
# // // This is a common way to infer and apply this property to flip-flops using an asynchronous reset.
# -------------------------------------------------------------------------------------------------
set_property ASYNC_REG TRUE [get_cells -hierarchical -filter {NAME =~ "*rst_n_reg*" || NAME =~ "*rst_reg*"}]
