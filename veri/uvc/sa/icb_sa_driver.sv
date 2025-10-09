`ifndef ICB_SA_DRIVER__SV
`define ICB_SA_DRIVER__SV

// ============================================================
// Driver: SA侧驱动器，驱动 interface.SA_DRV
// ============================================================
class icb_sa_driver extends uvm_driver#(icb_cmd_tr);

  `uvm_component_utils(icb_sa_driver)

  sa_drv_vif_t vif; // virtual interface (通过config_db传进来)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(sa_drv_vif_t)::get(this,"","vif",vif)) begin
      `uvm_fatal(get_full_name(), "No SA_DRV vif configured!")
    end
  endfunction

  virtual task run_phase(uvm_phase phase);
    icb_cmd_tr tr;
    forever begin
      seq_item_port.get_next_item(tr);

      // 驱动握手逻辑
      @(posedge vif.clk);
      vif.cb_sa_drv.sa_icb_cmd_addr  <= tr.addr;
      vif.cb_sa_drv.sa_icb_cmd_read  <= tr.read;
      vif.cb_sa_drv.sa_icb_cmd_wdata <= tr.wdata;
      vif.cb_sa_drv.sa_icb_cmd_wmask <= tr.wmask;
      vif.cb_sa_drv.sa_icb_cmd_len   <= tr.len;
      vif.cb_sa_drv.sa_icb_cmd_valid <= 1'b1;

      // 等待 ready
      do @(posedge vif.clk);
      while (!vif.cb_sa_drv.sa_icb_cmd_ready);

      vif.cb_sa_drv.sa_icb_cmd_valid <= 1'b0;

      `uvm_info(get_full_name(),
                $sformatf("Sent cmd: addr=0x%0h read=%0b wdata=0x%0h",
                          tr.addr, tr.read, tr.wdata),
                UVM_MEDIUM)

      seq_item_port.item_done();
    end
  endtask

endclass : icb_sa_driver

`endif
