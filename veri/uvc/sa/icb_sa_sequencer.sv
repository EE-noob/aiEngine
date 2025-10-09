`ifndef ICB_SA_SEQUENCER__SV
`define ICB_SA_SEQUENCER__SV

// ============================================================
// Sequencer: SA侧 sequencer
// ============================================================
class icb_sa_sequencer extends uvm_sequencer#(icb_cmd_tr);
  `uvm_component_utils(icb_sa_sequencer)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  function void ics_mon_sequencer::build_phase(uvm_phase phase);
  super.build_phase(phase);
endfunction: build_phase

endclass : icb_sa_sequencer

`endif
