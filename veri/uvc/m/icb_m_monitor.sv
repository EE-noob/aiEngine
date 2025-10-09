`ifndef ICB_M_MONITOR__SV
`define ICB_M_MONITOR__SV

class icb_m_monitor extends uvm_component;

  `uvm_component_utils(icb_m_monitor)

  m_mon_vif_t vif;
  uvm_analysis_port#(icb_mon_tr) out_port;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    out_port = new("out_port", this);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(m_mon_vif_t)::get(this,"","vif",vif)) begin
      `uvm_fatal(get_full_name(), "No M_MON vif configured!")
    end
  endfunction

  virtual task run_phase(uvm_phase phase);
    icb_mon_tr tr;
    forever begin
      @(posedge vif.clk);

      // 采样 DUT→M 的命令
      if (vif.cb_m_mon.m_icb_cmd_valid && vif.cb_m_mon.m_icb_cmd_ready) begin
        tr = icb_mon_tr::type_id::create("cmd_tr", this);
        tr.addr  = vif.cb_m_mon.m_icb_cmd_addr;
        tr.read  = vif.cb_m_mon.m_icb_cmd_read;
        tr.wdata = vif.cb_m_mon.m_icb_cmd_wdata;
        tr.wmask = vif.cb_m_mon.m_icb_cmd_wmask;
        tr.len   = '0;
        tr.side  = "M_CMD";
        out_port.write(tr);

        `uvm_info(get_full_name(),
                  $sformatf("Monitor M cmd: addr=0x%0h read=%0b wdata=0x%0h",
                            tr.addr, tr.read, tr.wdata),
                  UVM_LOW)
      end

      // 采样 M→DUT 的响应
      if (vif.cb_m_mon.m_icb_rsp_valid && vif.cb_m_mon.m_icb_rsp_ready) begin
        tr = icb_mon_tr::type_id::create("rsp_tr", this);
        tr.rdata = vif.cb_m_mon.m_icb_rsp_rdata;
        tr.err   = vif.cb_m_mon.m_icb_rsp_err;
        tr.side  = "M_RSP";
        out_port.write(tr);

        `uvm_info(get_full_name(),
                  $sformatf("Monitor M rsp: rdata=0x%0h err=%0b",
                            tr.rdata, tr.err),
                  UVM_LOW)
      end
    end
  endtask

endclass : icb_m_monitor

`endif
