`ifndef ICB_SA_AGENT__SV
`define ICB_SA_AGENT__SV

// ============================================================
// Agent: SA侧 agent，包含 driver + sequencer + monitor
// ============================================================
class icb_sa_agent extends uvm_agent;

  `uvm_component_utils(icb_sa_agent)

  uvm_active_passive_enum is_active = UVM_ACTIVE;

  icb_sa_driver      drv;
  icb_sa_monitor     mon;
  icb_sa_sequencer   sqr;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(uvm_active_passive_enum)::get(this,"","is_active",is_active)) begin
      is_active = UVM_ACTIVE; // 默认active
    end

    mon = icb_sa_monitor::type_id::create("mon", this);

    if (is_active == UVM_ACTIVE) begin
      sqr = icb_sa_sequencer::type_id::create("sqr", this);
      drv = icb_sa_driver   ::type_id::create("drv", this);
    end
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    if (is_active == UVM_ACTIVE) begin
      drv.seq_item_port.connect(sqr.seq_item_export);
    end
  endfunction

endclass : icb_sa_agent

`endif
