`ifndef ics_ENV__SV
`define ics_ENV__SV

class ics_env extends uvm_env;

    ics_mst_agent       i_agt;
    ics_rm              rm;
    ics_scb             scb;
    ics_mem_model       mem;
    filo_collector      collector;


    function new(string name = "ics_env", uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        i_agt = ics_mst_agent::type_id::create("i_agt", this);
        scb = ics_scb::type_id::create("scb",this);
        rm = ics_rm::type_id::create("rm",this);
        mem = ics_mem_model::type_id::create("mem",this);
        collector = filo_collector::type_id::create("collector",this);
    endfunction

    extern virtual function void connect_phase(uvm_phase phase);

    `uvm_component_utils(ics_env)
endclass

function void ics_env::connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    uvm_root::get().print_topology();
endfunction

`endif
