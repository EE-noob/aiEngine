#==================================Env Vars===================================
#set RST_NAME				nRst
set RST_NAME				rst_n
set CLK_NAME				clk

set CLK_PERIOD_I			2.22
set CLK_PERIOD            	[expr $CLK_PERIOD_I*0.95]
set CLK_SKEW              	[expr $CLK_PERIOD*0.05]
set CLK_SOURCE_LATENCY   	[expr $CLK_PERIOD*0.1]    
set CLK_NETWORK_LATENCY   	[expr $CLK_PERIOD*0.1]  
set CLK_TRAN             	[expr $CLK_PERIOD*0.01]

set INPUT_DELAY_MAX         [expr $CLK_PERIOD*0.4]
set INPUT_DELAY_MIN           0
set OUTPUT_DELAY_MAX        [expr $CLK_PERIOD*0.4]
set OUTPUT_DELAY_MIN          0

#set MAX_FANOUT             6
set MAX_TRAN               5
set MAX_CAP                1.5

set ALL_INPUT_EX_CLK [remove_from_collection [all_inputs] [get_ports $CLK_NAME]]

#==================================Define Design Environment=========================
#GUIDANCE: use the default
set_max_area 0
#set_max_transition  $MAX_TRAN     [current_design]
#set_max_fanout      $MAX_FANOUT   [current_design]
#set_max_capacitance $MAX_CAP      [current_design]

#============================= Set Design Constraints=========================
#--------------------------------Clock and Reset Definition----------------------------
#set_drive 0 [get_ports $CLK_NAME]
# set_ideal_network                                   [get_ports rxSB_inst/TPRAM_inst/clk]
# set_ideal_network                                   [get_ports mainband_inst/crc_64p_check_inst/rstn]
# set_ideal_network                                   [get_ports mainband_inst/FLIT_FIFO_pl_inst/u_Lfifo/u_RAM/clk]

set_ideal_network                                   [get_ports $CLK_NAME]
create_clock -name $CLK_NAME -period $CLK_PERIOD    [get_ports $CLK_NAME]
#set_dont_touch_network [get_ports $CLK_NAME]

set_clock_uncertainty $CLK_SKEW [get_clocks $CLK_NAME]
set_clock_transition  $CLK_TRAN [all_clocks]
set_clock_latency -source $CLK_SOURCE_LATENCY [get_clocks $CLK_NAME]
set_clock_latency -max $CLK_NETWORK_LATENCY [get_clocks $CLK_NAME]
#rst_ports
#set_drive 0            				[get_ports $RST_NAME]
set_ideal_network                   [get_ports $RST_NAME]
#set_dont_touch_network 				[get_ports $RST_NAME]
set_false_path -from   				[get_ports $RST_NAME] 
set_ideal_network -no_propagate     [get_ports $RST_NAME]


#--------------------------------I/O Constraint-----------------------------
set_input_delay   -max $INPUT_DELAY_MAX   -clock $CLK_NAME   $ALL_INPUT_EX_CLK
set_input_delay   -min $INPUT_DELAY_MIN   -clock $CLK_NAME   $ALL_INPUT_EX_CLK -add
set_output_delay  -max $OUTPUT_DELAY_MAX  -clock $CLK_NAME   [all_outputs]
set_output_delay  -min $OUTPUT_DELAY_MIN  -clock $CLK_NAME   [all_outputs] -add

#--------------------------------Multi Cycle Constraint---------------------
# 基于 clk 时钟，设置多周期路径（5-cycle）
# setup path: 允许数据在 5 个周期内稳定
# hold path: 要求前一周期数据稳定，4 = 5 - 1
# 假设所有寄存器在同一个时钟 clk 下
# 设置 From/To cell 名称
# set cal_from_cell [get_pins -hier *ics_start_r*]
# set cal_to_cells [get_pins -hier {x_0_r* x_1_r* row_total_r* l0_div_q_r* l1_div_q_r* part0_end_row_r* part1_end_index_r*}]
# 
# set_multicycle_path -setup 10 -from $cal_from_cell -to $cal_to_cells
# set_multicycle_path -hold 9 -from $cal_from_cell -to $cal_to_cells

#set_multicycle_path -setup 10 \
#    -from [get_cells *mux_ics_start_r*] \
#    -to [get_cells {group_total_tmp}]
#
#set_multicycle_path -hold 9 \
#    -from [get_cells *mux_ics_start_r*] \
#    -to [get_cells {group_total_tmp}]
#
#set_multicycle_path -setup 10 \
#    -from [get_cells *mux_init_done_1*] \
#    -to [get_cells {group_total}]
#
#set_multicycle_path -hold 9 \
#    -from [get_cells *mux_init_done_1*] \
#    -to [get_cells {group_total}]

#负载电容 .18 200pf,45nm 10pf 
set_load  0.1 	[all_outputs]	
#单位 nf
