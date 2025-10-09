`ifndef i2c_mon_MONITOR__SV
`define i2c_mon_MONITOR__SV


class i2c_mon_monitor extends uvm_monitor;
    //logic   part0_filoA_rdA_en;
    //logic   part0_filoB_rdA_en;
    //logic   part1_filoA_rdA_en;
    //logic   part1_filoB_rdA_en;
    //logic   part2_filoA_rdA_en;
    //logic   part2_filoB_rdA_en;
    //logic   [9:0] part0_filoA_rdA_data;
    //logic   part0_filoB_rdA_data;
    //logic   [9:0] part1_filoA_rdA_data;
    //logic   part1_filoB_rdA_data;
    //logic   [9:0] part2_filoA_rdA_data;
    //logic   part2_filoB_rdA_data;
    //logic   part0_filoA_rdB_en;
    //logic   part0_filoB_rdB_en;
    //logic   part1_filoA_rdB_en;
    //logic   part1_filoB_rdB_en;
    //logic   part2_filoA_rdB_en;
    //logic   part2_filoB_rdB_en;
    //logic   [3:0] part0_filoA_rdB_data;
    //logic   part0_filoB_rdB_data;
    //logic   [3:0] part1_filoA_rdB_data;
    //logic   part1_filoB_rdB_data;
    //logic   [3:0] part2_filoA_rdB_data;
    //logic   part2_filoB_rdB_data;
    //logic   part0_filoA_rd1_en;
    //logic   part0_filoB_rd1_en;
    //logic   part1_filoA_rd1_en;
    //logic   part1_filoB_rd1_en;
    //logic   part2_filoA_rd1_en;
    //logic   part2_filoB_rd1_en;
    //logic   part0_filoA_rd1_data;
    //logic   part0_filoB_rd1_data;
    //logic   part1_filoA_rd1_data;
    //logic   part1_filoB_rd1_data;
    //logic   part2_filoA_rd1_data;
    //logic   part2_filoB_rd1_data;
    //logic   part0_filoA_empty;
    //logic   part0_filoA_rdy4rd;
    //logic   part0_filoB_empty;
    //logic   part0_filoB_rdy4rd;
    //logic   part1_filoA_empty;
    //logic   part1_filoA_rdy4rd;
    //logic   part1_filoB_empty;
    //logic   part1_filoB_rdy4rd;
    //logic   part2_filoA_empty;
    //logic   part2_filoA_rdy4rd;
    //logic   part2_filoB_empty;
    //logic   part2_filoB_rdy4rd;
    //logic   [$clog2(128+1)-1:0] part0_filoA_cnt;
    //logic   part0_filoB_cnt;
    //logic   part1_filoA_cnt;
    //logic   part1_filoB_cnt;
    //logic   part2_filoA_cnt;
    //logic   part2_filoB_cnt;

    i2c_mon_agent_cfg                   cfg;
    virtual ics_if                      vif;
    i2c_mon_coverage                    cg;

    uvm_analysis_port#(i2c_mon_tr)      mon_port;
    uvm_analysis_port#(i2c_mon_tr)      out_port;

    `uvm_component_utils_begin(i2c_mon_monitor)
    `uvm_component_utils_end

    extern function new(string name, uvm_component parent);
    extern virtual function void build_phase(uvm_phase phase);
    extern virtual task run_phase(uvm_phase phase);
    extern virtual task collect_trans(uvm_phase phase);

endclass

function i2c_mon_monitor::new(string name, uvm_component parent);
    super.new(name, parent);
endfunction

function void i2c_mon_monitor::build_phase(uvm_phase phase);
    super.build_phase(phase);

    if(!uvm_config_db#(virtual ics_if)::get(this,"","ics_vif",vif))begin
        `uvm_fatal(get_full_name(),$psprintf("Got vif failed!"))
    end
    //if(cfg.cov_en) begin
    //    cg=new("i2c_mon_cg");
    //end

    mon_port = new("mon_port", this);
    out_port = new("out_port", this);
endfunction: build_phase

task i2c_mon_monitor::run_phase(uvm_phase phase);
    //todo: collect trans by vif
    forever begin
    //    collect_trans(phase);
    end
endtask: run_phase

task i2c_mon_monitor::collect_trans(uvm_phase phase);
i2c_mon_tr      mon_tr;
    //part0_filoA_rdA_en  = `uvm_hdl_read("top_tb.u_ics_top.intlv_top_inst.part0_filoA_rdA_en");
    //part0_filoB_rdA_en  = `uvm_hdl_read("top_tb.u_ics_top.intlv_top_inst");
    //part1_filoA_rdA_en  = `uvm_hdl_read("top_tb.u_ics_top.intlv_top_inst");
    //part1_filoB_rdA_en  = `uvm_hdl_read("top_tb.u_ics_top.intlv_top_inst");
    //part2_filoA_rdA_en  = `uvm_hdl_read("top_tb.u_ics_top.intlv_top_inst");
    //part2_filoB_rdA_en  = `uvm_hdl_read("top_tb.u_ics_top.intlv_top_inst");
    //part0_filoA_rdA_data    = `uvm_hdl_read("top_tb.u_ics_top.intlv_top_inst");
    //part0_filoB_rdA_data    = `uvm_hdl_read("top_tb.u_ics_top.intlv_top_inst");
    //part1_filoA_rdA_data    = `uvm_hdl_read("top_tb.u_ics_top.intlv_top_inst");
    //part1_filoB_rdA_data    = `uvm_hdl_read("top_tb.u_ics_top.intlv_top_inst");
    //part2_filoA_rdA_data    = `uvm_hdl_read("top_tb.u_ics_top.intlv_top_inst");
    //part2_filoB_rdA_data    = `uvm_hdl_read("top_tb.u_ics_top.intlv_top_inst");
    //part0_filoA_rdB_en  = `uvm_hdl_read("top_tb.u_ics_top.intlv_top_inst");
    //part0_filoB_rdB_en  = `uvm_hdl_read("top_tb.u_ics_top.intlv_top_inst");
    //part1_filoA_rdB_en  = `uvm_hdl_read("top_tb.u_ics_top.intlv_top_inst");
    //part1_filoB_rdB_en  = `uvm_hdl_read("top_tb.u_ics_top.intlv_top_inst");
    //part2_filoA_rdB_en  = `uvm_hdl_read("top_tb.u_ics_top.intlv_top_inst");
    //part2_filoB_rdB_en  = `uvm_hdl_read("top_tb.u_ics_top.intlv_top_inst");
    //part0_filoA_rdB_data    = `uvm_hdl_read("top_tb.u_ics_top.intlv_top_inst");
    //part0_filoB_rdB_data    = `uvm_hdl_read("top_tb.u_ics_top.intlv_top_inst");
    //part1_filoA_rdB_data    = `uvm_hdl_read("top_tb.u_ics_top.intlv_top_inst");
    //part1_filoB_rdB_data    = `uvm_hdl_read("top_tb.u_ics_top.intlv_top_inst");
    //part2_filoA_rdB_data    = `uvm_hdl_read("top_tb.u_ics_top.intlv_top_inst");
    //part2_filoB_rdB_data    = `uvm_hdl_read("top_tb.u_ics_top.intlv_top_inst");
    //part0_filoA_rd1_en  = `uvm_hdl_read("top_tb.u_ics_top.intlv_top_inst");
    //part0_filoB_rd1_en  = `uvm_hdl_read("top_tb.u_ics_top.intlv_top_inst");
    //part1_filoA_rd1_en  = `uvm_hdl_read("top_tb.u_ics_top.intlv_top_inst");
    //part1_filoB_rd1_en  = `uvm_hdl_read("top_tb.u_ics_top.intlv_top_inst");
    //part2_filoA_rd1_en  = `uvm_hdl_read("top_tb.u_ics_top.intlv_top_inst");
    //part2_filoB_rd1_en  = `uvm_hdl_read("top_tb.u_ics_top.intlv_top_inst");
    //part0_filoA_rd1_data    = `uvm_hdl_read("top_tb.u_ics_top.intlv_top_inst");
    //part0_filoB_rd1_data    = `uvm_hdl_read("top_tb.u_ics_top.intlv_top_inst");
    //part1_filoA_rd1_data    = `uvm_hdl_read("top_tb.u_ics_top.intlv_top_inst");
    //part1_filoB_rd1_data    = `uvm_hdl_read("top_tb.u_ics_top.intlv_top_inst");
    //part2_filoA_rd1_data    = `uvm_hdl_read("top_tb.u_ics_top.intlv_top_inst");
    //part2_filoB_rd1_data    = `uvm_hdl_read("top_tb.u_ics_top.intlv_top_inst");
    //part0_filoA_empty   = `uvm_hdl_read("top_tb.u_ics_top.intlv_top_inst");
    //part0_filoA_rdy4rd  = `uvm_hdl_read("top_tb.u_ics_top.intlv_top_inst");
    //part0_filoB_empty   = `uvm_hdl_read("top_tb.u_ics_top.intlv_top_inst");
    //part0_filoB_rdy4rd  = `uvm_hdl_read("top_tb.u_ics_top.intlv_top_inst");
    //part1_filoA_empty   = `uvm_hdl_read("top_tb.u_ics_top.intlv_top_inst");
    //part1_filoA_rdy4rd  = `uvm_hdl_read("top_tb.u_ics_top.intlv_top_inst");
    //part1_filoB_empty   = `uvm_hdl_read("top_tb.u_ics_top.intlv_top_inst");
    //part1_filoB_rdy4rd  = `uvm_hdl_read("top_tb.u_ics_top.intlv_top_inst");
    //part2_filoA_empty   = `uvm_hdl_read("top_tb.u_ics_top.intlv_top_inst");
    //part2_filoA_rdy4rd  = `uvm_hdl_read("top_tb.u_ics_top.intlv_top_inst");
    //part2_filoB_empty   = `uvm_hdl_read("top_tb.u_ics_top.intlv_top_inst");
    //part2_filoB_rdy4rd  = `uvm_hdl_read("top_tb.u_ics_top.intlv_top_inst");
    //part0_filoA_cnt = `uvm_hdl_read("top_tb.u_ics_top.intlv_top_inst");
    //part0_filoB_cnt = `uvm_hdl_read("top_tb.u_ics_top.intlv_top_inst");
    //part1_filoA_cnt = `uvm_hdl_read("top_tb.u_ics_top.intlv_top_inst");
    //part1_filoB_cnt = `uvm_hdl_read("top_tb.u_ics_top.intlv_top_inst");
    //part2_filoA_cnt = `uvm_hdl_read("top_tb.u_ics_top.intlv_top_inst");
    //part2_filoB_cnt = `uvm_hdl_read("top_tb.u_ics_top.intlv_top_inst");

    mon_tr = i2c_mon_tr::type_id::create("mon_tr",this);
    //todo: collect transaction by protocol
    //... (protocol)
    //out_port.write(mon_tr);
    //mon_port.write(mon_tr);
    @(vif.mon_cb);
    mon_port.write(mon_tr);

    //if(cfg.cov_en) begin
    //    cg.sample_tr(mon_tr);
    //end
endtask: collect_trans

`endif
