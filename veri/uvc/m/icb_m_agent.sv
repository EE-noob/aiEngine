`ifndef ICB_M_AGENT__SV
`define ICB_M_AGENT__SV

class icb_m_agent extends uvm_agent;

  `uvm_component_utils(icb_m_agent)

  uvm_active_passive_enum is_active = UVM_ACTIVE;

  icb_m_driver     drv;
  icb_m_monitor    mon;
  icb_m_sequencer  sqr;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(uvm_active_passive_enum)::get(this,"","is_active",is_active)) begin
      is_active = UVM_ACTIVE;
    end

    mon = icb_m_monitor::type_id::create("mon", this);

    if (is_active == UVM_ACTIVE) begin
      drv = icb_m_driver   ::type_id::create("drv", this);
      sqr = icb_m_sequencer::type_id::create("sqr", this);
    end
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    if (is_active == UVM_ACTIVE) begin
      drv.seq_item_port.connect(sqr.seq_item_export);
    end
  endfunction

endclass : icb_m_agent

`endif
