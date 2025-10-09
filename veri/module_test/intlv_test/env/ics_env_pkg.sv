`ifndef ics_ENV_PKG_SV
`define ics_ENV_PKG_SV

package ics_env_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    import ics_mst_pkg::*;
    import ics_mem_model_pkg::*;
    import filo_collector_pkg::*;
    `include "ics_rm.sv"
    `include "ics_scb.sv"
    `include "ics_env.sv"

endpackage: ics_env_pkg

`endif
