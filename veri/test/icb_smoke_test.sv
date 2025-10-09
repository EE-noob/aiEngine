`ifndef ICB_SMOKE_TEST__SV
`define ICB_SMOKE_TEST__SV

class icb_smoke_test extends uvm_test;

  `uvm_component_utils(icb_smoke_test)

  icb_env              env;   // 假定你的环境类名是 icb_env
  icb_smoke_sequence   seq;   // 假定你的冒烟序列类名是 icb_smoke_sequence

  extern function new(string name="icb_smoke_test", uvm_component parent);
  extern function void build_phase(uvm_phase phase);
  extern task run_phase(uvm_phase phase);

endclass : icb_smoke_test


function icb_smoke_test::new(string name="icb_smoke_test", uvm_component parent);
  super.new(name, parent);
endfunction : new


function void icb_smoke_test::build_phase(uvm_phase phase);
  `uvm_info(get_full_name(), "build_phase begin...", UVM_LOW)

  // 如果需要在这里传接口，可以加上：
  // uvm_config_db#(virtual icb_if)::set(this, "env.*", "icb_vif", tb_icb_vif);

  env = icb_env::type_id::create("env", this);

  `uvm_info(get_full_name(), "build_phase end...", UVM_LOW)
endfunction : build_phase


task icb_smoke_test::run_phase(uvm_phase phase);
  phase.raise_objection(this);

  seq = icb_smoke_sequence::type_id::create("seq");
  if (seq == null) `uvm_fatal("SEQ_NULL", "icb_smoke_sequence create failed")

  // 启动序列，假定环境里上游 agent 名为 i_agt，sequencer 句柄为 sqr
  seq.start(env.i_agt.sqr);

  // 给driver/monitor/scoreboard一些尾水时间
  phase.phase_done.set_drain_time(this, 50_000ns);

  phase.drop_objection(this);
endtask : run_phase

`endif // ICB_SMOKE_TEST__SV
