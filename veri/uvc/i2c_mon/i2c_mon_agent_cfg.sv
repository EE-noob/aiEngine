`ifndef i2c_mon_AGENT_CFG__SV
`define i2c_mon_AGENT_CFG__SV
class i2c_mon_agent_cfg extends i2c_mon_agent_cfg_base;

    `uvm_object_utils_begin(i2c_mon_agent_cfg)
    `uvm_object_utils_end

    extern function new(string name = "__NO_NAME__");

endclass

function i2c_mon_agent_cfg::new(string name = "__NO_NAME__");
    super.new(name);
    this.cov_en=0;
    is_active = UVM_PASSIVE;
endfunction

`endif
