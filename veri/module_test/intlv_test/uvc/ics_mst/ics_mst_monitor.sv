`ifndef ics_mst_MONITOR__SV
`define ics_mst_MONITOR__SV
class ics_mst_monitor extends uvm_monitor;

    ics_mst_agent_cfg                   cfg;
    virtual ics_if                 vif;
    ics_mst_coverage                    cg;

    uvm_analysis_port#(ics_mst_tr)      mon_port;
    uvm_analysis_port#(ics_mst_tr)      out_port;

    `uvm_component_utils_begin(ics_mst_monitor)
    `uvm_component_utils_end

    extern function new(string name, uvm_component parent);
    extern virtual function void build_phase(uvm_phase phase);
    extern virtual task run_phase(uvm_phase phase);
    extern virtual task collect_trans(uvm_phase phase);

endclass

function ics_mst_monitor::new(string name, uvm_component parent);
    super.new(name, parent);
endfunction

function void ics_mst_monitor::build_phase(uvm_phase phase);
    super.build_phase(phase);

    if(!uvm_config_db#(virtual ics_if)::get(this,"","ics_vif",vif))begin
        `uvm_fatal(get_full_name(),$psprintf("Got vif failed!"))
    end
    //if(cfg.cov_en) begin
    //    cg=new("ics_mst_cg");
    //end

    mon_port = new("mon_port", this);
    out_port = new("out_port", this);
endfunction: build_phase

task ics_mst_monitor::run_phase(uvm_phase phase);
    //todo: collect trans by vif
    //forever begin
    //    collect_trans(phase);
    //end
endtask: run_phase

task ics_mst_monitor::collect_trans(uvm_phase phase);
    ics_mst_tr mon_tr;
    mon_tr = ics_mst_tr::type_id::create("mon_tr",this);
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
