`ifndef ICB_SA_MONITOR__SV
`define ICB_SA_MONITOR__SV

// ============================================================
// Monitor: SA侧监视器，采样 interface.SA_MON
// ============================================================
class icb_sa_monitor extends uvm_component;

  `uvm_component_utils(icb_sa_monitor)

  sa_mon_vif_t vif; // virtual interface
  uvm_analysis_port#(icb_mon_tr) out_port;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    out_port = new("out_port", this);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(sa_mon_vif_t)::get(this,"","vif",vif)) begin
      `uvm_fatal(get_full_name(), "No SA_MON vif configured!")
    end
  endfunction

  virtual task run_phase(uvm_phase phase);
    icb_mon_tr tr;
    forever begin
      @(posedge vif.clk);
      // 采样响应
      if (vif.cb_sa_mon.sa_icb_rsp_valid && vif.cb_sa_mon.sa_icb_rsp_ready) begin
        tr = icb_mon_tr::type_id::create("tr");
        tr.rdata = vif.cb_sa_mon.sa_icb_rsp_rdata;
        tr.err   = vif.cb_sa_mon.sa_icb_rsp_err;
        tr.side  = "SA_RSP";
        out_port.write(tr);

        `uvm_info(get_full_name(),
                  $sformatf("Monitor SA rsp: rdata=0x%0h err=%0b",
                            tr.rdata, tr.err),
                  UVM_LOW)
      end
    end
  endtask

endclass : icb_sa_monitor

`endif
