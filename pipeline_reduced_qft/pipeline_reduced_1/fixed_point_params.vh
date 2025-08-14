//======================================================================
// fixed_point_params.vh
// Defines the fixed-point data type for the QFT project.
//======================================================================

// Total bits for our signed fixed-point number
`define TOTAL_WIDTH 4

// Number of fractional bits (S1.2 format: 1 sign, 1 integer, 2 fractional)
`define FRAC_WIDTH 2

// Width for intermediate multiplication results (before scaling)
// For TOTAL_WIDTH = 4, MULT_WIDTH = 4 * 2 = 8
`define MULT_WIDTH (`TOTAL_WIDTH * 2)

// Width for intermediate addition results
// For TOTAL_WIDTH = 4, ADD_WIDTH = 4 + 1 = 5
`define ADD_WIDTH (`TOTAL_WIDTH + 1)
