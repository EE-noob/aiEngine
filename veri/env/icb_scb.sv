`ifndef ICB_SCB__SV
`define ICB_SCB__SV

class icb_scb extends uvm_scoreboard;

    // 期望事务队列
    icb_mon_tr                 expect_queue[$];
    // 端口：期望端口（来自 RM），实际端口（来自 monitor）
    uvm_blocking_get_port #(icb_mon_tr) exp_port;
    uvm_blocking_get_port #(icb_mon_tr) act_port;

    `uvm_component_utils(icb_scb)

    // -----------------------------------------
    // 构造函数
    // -----------------------------------------
    extern function new(string name, uvm_component parent = null);

    // -----------------------------------------
    // build_phase
    // -----------------------------------------
    extern virtual function void build_phase(uvm_phase phase);

    // -----------------------------------------
    // main_phase
    // -----------------------------------------
    extern virtual task main_phase(uvm_phase phase);

endclass : icb_scb

// ===========================================================
// function new
// ===========================================================
function icb_scb::new(string name, uvm_component parent = null);
    super.new(name, parent);
endfunction

// ===========================================================
// build_phase
// ===========================================================
function void icb_scb::build_phase(uvm_phase phase);
    super.build_phase(phase);
    exp_port = new("exp_port", this);
    act_port = new("act_port", this);
endfunction

// ===========================================================
// main_phase
// ===========================================================
task icb_scb::main_phase(uvm_phase phase);
    icb_mon_tr get_expect, get_actual, tmp_tran;
    bit result;

    super.main_phase(phase);

    fork
        // 收集 reference model 输出，存入队列
        forever begin
            exp_port.get(get_expect);
            expect_queue.push_back(get_expect);
            `uvm_info(get_full_name(), "Got expected transaction from RM", UVM_LOW)
        end

        // 收集 DUT 实际输出，与期望比对
        forever begin
            act_port.get(get_actual);
            if (expect_queue.size() > 0) begin
                tmp_tran = expect_queue.pop_front();
                result = get_actual.compare(tmp_tran);
                if (result) begin
                    `uvm_info(get_full_name(), "Compare SUCCESSFUL", UVM_MEDIUM);
                end
                else begin
                    `uvm_error(get_full_name(), "Compare ERROR");
                    `uvm_info(get_full_name(), "Expected packet is:", UVM_NONE);
                    tmp_tran.print();
                    `uvm_info(get_full_name(), "Actual packet is:", UVM_NONE);
                    get_actual.print();
                end
            end
            else begin
                `uvm_error(get_full_name(), "Unexpected actual packet, expect_queue is empty");
                get_actual.print();
            end
        end
    join
endtask : main_phase

`endif
