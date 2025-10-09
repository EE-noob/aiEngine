`ifndef ICB_M_DRIVER__SV
`define ICB_M_DRIVER__SV

class icb_m_driver extends uvm_driver#(icb_rsp_tr);

  `uvm_component_utils(icb_m_driver)

  m_drv_vif_t vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(m_drv_vif_t)::get(this,"","vif",vif)) begin
      `uvm_fatal(get_full_name(), "No M_DRV vif configured!")
    end
  endfunction

  virtual task run_phase(uvm_phase phase);
    icb_rsp_tr rsp;
    forever begin
      seq_item_port.get_next_item(rsp);

      // ============ 模拟从设备响应逻辑 ============
      // 采样 DUT 发过来的命令
      if (vif.cb_m_drv.m_icb_cmd_valid) begin
        vif.cb_m_drv.m_icb_cmd_ready <= 1'b1;
        @(posedge vif.clk);

        // 生成响应
        vif.cb_m_drv.m_icb_rsp_rdata <= rsp.rdata;
        vif.cb_m_drv.m_icb_rsp_err   <= rsp.err;
        vif.cb_m_drv.m_icb_rsp_valid <= 1'b1;

        // 等待 DUT ready
        do @(posedge vif.clk);
        while (!vif.cb_m_drv.m_icb_rsp_ready);

        vif.cb_m_drv.m_icb_rsp_valid <= 1'b0;
        vif.cb_m_drv.m_icb_cmd_ready <= 1'b0;

        `uvm_info(get_full_name(),
                  $sformatf("M driver responded: rdata=0x%0h err=%0b",
                            rsp.rdata, rsp.err),
                  UVM_MEDIUM)
      end
      // ===========================================
      seq_item_port.item_done();
      @(posedge vif.clk);
    end
  endtask

endclass : icb_m_driver

`endif
