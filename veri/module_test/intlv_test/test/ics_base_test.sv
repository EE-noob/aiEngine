`ifndef ics_BASE_TEST__SV
`define ics_BASE_TEST__SV

class ics_base_test extends uvm_test;

    `uvm_component_utils(ics_base_test)

    ics_env                         env;
    ics_smoke_sequence              seq;

    extern function new(string name="ics_base_test", uvm_component parent);
    extern function void build_phase(uvm_phase phase);
    extern task run_phase(uvm_phase phase);

endclass:ics_base_test

function ics_base_test::new(string name="ics_base_test",uvm_component parent);
    super.new(name,parent);
endfunction:new

function void ics_base_test::build_phase(uvm_phase phase);
    `uvm_info(get_full_name(),"build_phase begin...", UVM_LOW)
    env = ics_env::type_id::create("env",this);
    `uvm_info(get_full_name(),"build_phase end...", UVM_LOW)
endfunction: build_phase

task ics_base_test::run_phase(uvm_phase phase);
    phase.raise_objection(this);

    seq = ics_smoke_sequence::type_id::create("seq");

    //todo:add sequence operation
    fork
        seq.start(env.i_agt.sqr);
    join

    phase.phase_done.set_drain_time(this, 50000);
    phase.drop_objection(this);
endtask:run_phase

`endif
