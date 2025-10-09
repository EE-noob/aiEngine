// case216_define.vh  –  Auto-gen by ics_testgen.py

`define ICS_INPUT_DATA       "../../data/ics_input_data8.txt"
`define ICS_INTLV_OUT_DATA   "../../data/ics_intlv_out_data8.txt"
`define ICS_OUTPUT_DATA      "../../data/ics_output_data8.txt"
`define ICS_SCRAMBLE_CODE    "../../data/ics_scram_code8.txt"

`define GROUP_WIDTH_ARRAY_0 \
  '{ 38, 37, 37, 37, 37, 37, 37, 37, 37, 36, 35, 34, 33, 32, 31, 30, 29, 28, 27, 26, 25, 24, 23, 22, 21, 20, 19, 18, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1 }
`define GROUP_WIDTH_ARRAY_1 \
  '{ 75, 75, 75, 74, 73, 72, 71, 70, 69, 68, 67, 66, 65, 64, 63, 62, 61, 60, 59, 58, 57, 56, 55, 54, 53, 52, 51, 50, 49, 48, 47, 46, 45, 44, 43, 42, 41, 40, 39, 38, 37, 36, 35, 34, 33, 32, 31, 30, 29, 28, 27, 26, 25, 24, 23, 22, 21, 20, 19, 18, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1 }
`define GROUP_WIDTH_ARRAY_2 \
  '{ 18, 17, 17, 17, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1 }
`define GOLDEN_LINES_PER_PART '{7, 16, 2}
`define ICS_SCRAMBLE_OUTPUT_NUM 33

`define ICS_C_INIT             31'h40040001
`define ICS_Q_SIZE             4'd8
`define ICS_PART0_EN           1'b1
`define ICS_PART0_N_SIZE       11'd256
`define ICS_PART0_E_SIZE       14'd1000
`define ICS_PART0_L_SIZE       14'd888
`define ICS_PART0_ST_IDX       14'd111
`define ICS_PART1_EN           1'b1
`define ICS_PART1_N_SIZE       11'd512
`define ICS_PART1_E_SIZE       14'd3000
`define ICS_PART1_L_SIZE       14'd2000
`define ICS_PART1_ST_IDX       14'd512
`define ICS_PART2_EN           1'b1
`define ICS_PART2_N_SIZE       11'd64
`define ICS_PART2_E_SIZE       14'd222
`define ICS_PART2_L_SIZE       14'd200
`define ICS_PART2_ST_IDX       14'd10
