`ifndef ICB_RSP_TR__SV
`define ICB_RSP_TR__SV
`include "uvm_macros.svh"
import uvm_pkg::*;
class icb_rsp_tr extends uvm_sequence_item;

  rand bit [31:0] rdata;
  rand bit        err;

  `uvm_object_utils_begin(icb_rsp_tr)
    `uvm_field_int(rdata, UVM_ALL_ON)
    `uvm_field_int(err  , UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name="icb_rsp_tr");
    super.new(name);
  endfunction

endclass : icb_rsp_tr

`endif
