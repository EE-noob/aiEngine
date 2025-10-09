`ifndef i2c_mon_TR__SV
`define i2c_mon_TR__SV

class i2c_mon_tr extends uvm_sequence_item;

    logic part0_filoA_rdA_en; 
    logic part0_filoB_rdA_en;
    logic part1_filoA_rdA_en; 
    logic part1_filoB_rdA_en;
    logic part2_filoA_rdA_en; 
    logic part2_filoB_rdA_en;
    logic [9:0] part0_filoA_rdA_data; 
    logic [9:0] part0_filoB_rdA_data;
    logic [9:0] part1_filoA_rdA_data; 
    logic [9:0] part1_filoB_rdA_data;
    logic [9:0] part2_filoA_rdA_data; 
    logic [9:0] part2_filoB_rdA_data;
    logic part0_filoA_rdB_en; 
    logic part0_filoB_rdB_en;
    logic part1_filoA_rdB_en; 
    logic part1_filoB_rdB_en;
    logic part2_filoA_rdB_en; 
    logic part2_filoB_rdB_en;
    logic [3:0] part0_filoA_rdB_data; 
    logic [3:0] part0_filoB_rdB_data;
    logic [3:0] part1_filoA_rdB_data; 
    logic [3:0] part1_filoB_rdB_data;
    logic [3:0] part2_filoA_rdB_data; 
    logic [3:0] part2_filoB_rdB_data;
    logic part0_filoA_rd1_en; 
    logic part0_filoB_rd1_en;
    logic part1_filoA_rd1_en; 
    logic part1_filoB_rd1_en;
    logic part2_filoA_rd1_en; 
    logic part2_filoB_rd1_en;
    logic part0_filoA_rd1_data;
    logic part0_filoB_rd1_data;
    logic part1_filoA_rd1_data;
    logic part1_filoB_rd1_data;
    logic part2_filoA_rd1_data;
    logic part2_filoB_rd1_data;
    logic part0_filoA_empty;
    logic part0_filoA_rdy4rd;
    logic part0_filoB_empty;
    logic part0_filoB_rdy4rd;
    logic part1_filoA_empty;
    logic part1_filoA_rdy4rd;
    logic part1_filoB_empty;
    logic part1_filoB_rdy4rd;
    logic part2_filoA_empty;
    logic part2_filoA_rdy4rd;
    logic part2_filoB_empty;
    logic part2_filoB_rdy4rd;
    logic [$clog2(128+1)-1:0] part0_filoA_cnt;
    logic [$clog2(128+1)-1:0] part0_filoB_cnt;
    logic [$clog2(128+1)-1:0] part1_filoA_cnt;
    logic [$clog2(128+1)-1:0] part1_filoB_cnt;
    logic [$clog2(128+1)-1:0] part2_filoA_cnt;
    logic [$clog2(128+1)-1:0] part2_filoB_cnt;
    
    //todo: complete tr_cons
    //constraint tr_cons{

    //}

    //todo: fill field automation list
    `uvm_object_utils_begin(i2c_mon_tr)
        //`uvm_field_int(rx_lp_data,UVM_ALL_ON)
    `uvm_object_utils_end

    extern function new(string name="__NO_NAME__");
endclass: i2c_mon_tr

function i2c_mon_tr::new(string name="__NO_NAME__");
    super.new(name);
endfunction

`endif
