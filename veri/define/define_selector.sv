`ifdef ICS_CASE1
  `include "define/case1_define.vh"
`elsif ICS_CASE2
  `include "define/case2_define.vh"
`elsif ICS_CASE3
  `include "define/case3_define.vh"
`elsif ICS_CASE4
  `include "define/case4_define.vh"
`elsif ICS_CASE5
  `include "define/case5_define.vh"
`elsif ICS_CASE6
  `include "define/case6_define.vh"
`elsif ICS_CASE7
  `include "define/case7_define.vh"
`elsif ICS_CASE8
  `include "define/case8_define.vh"
`elsif ICS_CASE9
  `include "define/case9_define.vh"
`elsif ICS_CASE10
  `include "define/case10_define.vh"
`else
`include "define/default_define.vh"
`endif