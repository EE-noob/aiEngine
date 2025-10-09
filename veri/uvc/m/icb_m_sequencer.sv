`ifndef ICB_M_SEQUENCER__SV
`define ICB_M_SEQUENCER__SV

class icb_m_sequencer extends uvm_sequencer#(icb_rsp_tr);
  `uvm_component_utils(icb_m_sequencer)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
endclass : icb_m_sequencer

`endif
