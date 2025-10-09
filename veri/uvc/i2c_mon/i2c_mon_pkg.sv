`ifndef i2c_mon_PKG_SV
`define i2c_mon_PKG_SV


package i2c_mon_pkg;
    `include "uvm_macros.svh"
    import uvm_pkg::*;
    
    `include "i2c_mon_agent_cfg_base.sv"
    `include "i2c_mon_agent_cfg.sv"
    `include "i2c_mon_tr.sv"
    `include "i2c_mon_coverage.sv"
    `include "i2c_mon_sequencer.sv"
    `include "i2c_mon_monitor.sv"
    `include "i2c_mon_driver.sv"
    `include "i2c_mon_reg_adapter.sv"
    `include "i2c_mon_agent.sv"

endpackage: i2c_mon_pkg

`endif
