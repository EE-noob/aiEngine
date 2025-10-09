// case2_define.vh
`define ICS_INPUT_DATA "../../data/ics_input_data3.txt"
`define ICS_INTLV_OUT_DATA "../../data/ics_intlv_out_data3.txt"
`define ICS_OUTPUT_DATA "../../data/ics_output_data3.txt"
`define ICS_SCRAMBLE_CODE "../../data/ics_scram_code3.txt"
// for intlv
`define GROUP_WIDTH_ARRAY_0 \
  '{ \
    114, \
    113,113,113,113,113,113,113,113,113,113,113,113,113,113, \
    112,111,110,109,108,107,106,105,104,103,102,101,100,99,98,97, \
    96,95,94,93,92,91,90,89,88,87,86,85,84,83,82,81, \
    80,79,78,77,76,75,74,73,72,71,70,69,68,67,66,65, \
    64,63,62,61,60,59,58,57,56,55,54,53,52,51,50,49, \
    48,47,46,45,44,43,42,41,40,39,38,37,36,35,34,33, \
    32,31,30,29,28,27,26,25,24,23,22,21,20,19,18,17, \
    16,15,14,13,12,11,10,9,8,7,6,5,4,3,2,1 \
  }
`define GROUP_WIDTH_ARRAY_1 \
  '{ \
    78,78,78,78,78,78,78,78,78,78,78,78, \
    77,77, \
    76,75,74,73,72,71,70,69,68,67,66,65,64,63,62,61, \
    60,59,58,57,56,55,54,53,52,51,50,49,48,47,46,45, \
    44,43,42,41,40,39,38,37,36,35,34,33,32,31,30,29, \
    28,27,26,25,24,23,22,21,20,19,18,17,16,15,14,13, \
    12,11,10,9,8,7,6,5,4,3,2,1 \
  }
`define GROUP_WIDTH_ARRAY_2 \
  '{ \
    60,60, \
    59,59,59, \
    58,57,56,55,54,53,52,51,50,49,48,47,46,45,44,43, \
    42,41,40,39,38,37,36,35,34,33,32,31,30,29,28,27, \
    26,25,24,23,22,21,20,19,18,17,16,15,14,13,12,11, \
    10,9,8,7,6,5,4,3,2,1 \
  }
`define GOLDEN_LINES_PER_PART '{63, 32, 16}
// for scramble
`define ICS_SCRAMBLE_OUTPUT_NUM 147 // 要采集 scramble_data 的次数:scramble golden data的列数除12
// for input
`define ICS_C_INIT 31'h10000010
`define ICS_Q_SIZE 4'd8
`define ICS_PART0_EN 1'b1
`define ICS_PART0_N_SIZE 11'd1024
`define ICS_PART0_E_SIZE 14'd8024
`define ICS_PART0_L_SIZE 14'd8024
`define ICS_PART0_ST_IDX 14'd1
`define ICS_PART1_EN 1'b1
`define ICS_PART1_N_SIZE 11'd512
`define ICS_PART1_E_SIZE 14'd4016
`define ICS_PART1_L_SIZE 14'd4016
`define ICS_PART1_ST_IDX 14'd1
`define ICS_PART2_EN 1'b1
`define ICS_PART2_N_SIZE 11'd256
`define ICS_PART2_E_SIZE 14'd2008
`define ICS_PART2_L_SIZE 14'd2008
`define ICS_PART2_ST_IDX 14'd1