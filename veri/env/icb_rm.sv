`ifndef ICB_RM__SV
`define ICB_RM__SV

class icb_rm extends uvm_component;

    // 输入：来自 SA agent 的命令事务
    uvm_blocking_get_port #(icb_cmd_tr)  in_port;
    // 输出：转换后的参考结果事务，送往 scoreboard
    uvm_analysis_port    #(icb_mon_tr)   out_port;

    extern function new(string name, uvm_component parent);
    extern function void build_phase(uvm_phase phase);
    extern virtual task main_phase (uvm_phase phase);

    `uvm_component_utils(icb_rm)

endclass : icb_rm

// -----------------------------------------------------------
// 构造函数
// -----------------------------------------------------------
function icb_rm::new(string name, uvm_component parent);
    super.new(name, parent);
endfunction

// -----------------------------------------------------------
// build_phase：实例化端口
// -----------------------------------------------------------
function void icb_rm::build_phase(uvm_phase phase);
    super.build_phase(phase);
    in_port  = new("in_port", this);
    out_port = new("out_port", this);
endfunction

// -----------------------------------------------------------
// main_phase：参考模型逻辑
// -----------------------------------------------------------
task icb_rm::main_phase(uvm_phase phase);
    icb_cmd_tr  in_tr;
    icb_mon_tr  out_tr;

    super.main_phase(phase);
    forever begin
        // 从 SA agent driver 发过来的 input transaction
        in_port.get(in_tr);

        // 创建一个输出事务
        out_tr = icb_mon_tr::type_id::create("out_tr", this);
        // 简单复制字段，后续可在这里实现 reference model 的行为
        out_tr.addr  = in_tr.addr;
        out_tr.read  = in_tr.read;
        out_tr.wdata = in_tr.wdata;
        out_tr.wmask = in_tr.wmask;
        out_tr.len   = in_tr.len;

        // 这里可以加参考模型对 rdata/err 的预测逻辑
        out_tr.rdata = '0;
        out_tr.err   = 0;
        out_tr.side  = "RM_EXP";

        `uvm_info(get_full_name(), $sformatf("RM generate expected tr @addr=0x%0h", in_tr.addr), UVM_MEDIUM)

        // 输出到 scoreboard
        out_port.write(out_tr);
    end
endtask

`endif
