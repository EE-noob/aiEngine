// case1_define.vh
`define ICS_INPUT_DATA "../../data/ics_input_data1.txt"
`define ICS_INTLV_OUT_DATA "../../data/ics_intlv_out_data1.txt"
`define ICS_OUTPUT_DATA "../../data/ics_output_data1.txt"
`define ICS_SCRAMBLE_CODE "../../data/ics_scram_code1.txt"
// for intlv
`define GROUP_WIDTH_ARRAY_0 '{9, 9, 9, 9, 8, 8, 7, 6, 5, 4, 3, 2, 1}
`define GROUP_WIDTH_ARRAY_1 '{9, 9, 9, 9, 8, 8, 7, 6, 5, 4, 3, 2, 1}
`define GROUP_WIDTH_ARRAY_2 '{9, 9, 9, 9, 8, 8, 7, 6, 5, 4, 3, 2, 1}
`define GOLDEN_LINES_PER_PART '{1, 1, 1}
// for scramble
`define ICS_SCRAMBLE_OUTPUT_NUM 10 // 要采集 scramble_data 的次数:scramble golden data的列数除12
// for ICS input
`define ICS_C_INIT 31'h0
`define ICS_Q_SIZE 4'd2
`define ICS_PART0_EN 1'b1
`define ICS_PART0_N_SIZE 11'd32
`define ICS_PART0_E_SIZE 14'd80
`define ICS_PART0_L_SIZE 14'd80
`define ICS_PART0_ST_IDX 14'd1
`define ICS_PART1_EN 1'b1
`define ICS_PART1_N_SIZE 11'd32
`define ICS_PART1_E_SIZE 14'd80
`define ICS_PART1_L_SIZE 14'd80
`define ICS_PART1_ST_IDX 14'd1
`define ICS_PART2_EN 1'b1
`define ICS_PART2_N_SIZE 11'd32
`define ICS_PART2_E_SIZE 14'd80
`define ICS_PART2_L_SIZE 14'd80
`define ICS_PART2_ST_IDX 14'd1