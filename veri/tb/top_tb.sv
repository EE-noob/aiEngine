`ifndef TOP_TB__SV
`define TOP_TB__SV
module tb_top ();
  `include "uvm_macros.svh"
  import uvm_pkg::*;

  // -------------------------------------------------
  // 与 DUT/Interface 对齐的参数
  // -------------------------------------------------
  localparam int WIDTH      = 32;
  localparam int ADDR_W     = 32;
  localparam int OUTS_DEPTH = 16;
  localparam int ICB_LEN_W  = 3;
  localparam int DW         = (WIDTH/8);

  // -------------------------------------------------
  // 时钟 / 复位
  // -------------------------------------------------
  logic clk;
  logic rst_n;

  // 100MHz 示例时钟
  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  // 复位：低有效，保持 100ns
  initial begin
    rst_n = 1'b1;
    repeat(5) @(negedge clk);
    rst_n = 1'b0;
    repeat(10) @(negedge clk);
    rst_n = 1'b1;
  end

  initial begin
    $fsdbDumpfile("sim.fsdb");
    $fsdbDumpvars(0,tb_top);
    $fsdbDumpMDA(0,tb_top);
    end
  // -------------------------------------------------
  // 接口实例（参数化 + 带 clocking block）
  // -------------------------------------------------
  icb_unalign_bridge_if #(
    .WIDTH     (WIDTH),
    .ADDR_W    (ADDR_W),
    .ICB_LEN_W (ICB_LEN_W),
    .DW        (DW),
    .setup_time(0.1ns),
    .hold_time (0.1ns)
  ) vif (
    .clk   (clk),
    .rst_n (rst_n)
  );

  // -------------------------------------------------
  // DUT 实例，并通过 vif.DUT 连接所有端口
  // -------------------------------------------------
  icb_unalign_bridge #(
    .WIDTH      (WIDTH),
    .ADDR_W     (ADDR_W),
    .OUTS_DEPTH (OUTS_DEPTH),
    .ICB_LEN_W  (ICB_LEN_W)
  ) dut (
    // 时钟复位
    .clk               (clk),
    .rst_n             (rst_n),

    // 上游 ICB 从接口
    .sa_icb_cmd_valid  (vif.sa_icb_cmd_valid),
    .sa_icb_cmd_ready  (vif.sa_icb_cmd_ready),
    .sa_icb_cmd_addr   (vif.sa_icb_cmd_addr),
    .sa_icb_cmd_read   (vif.sa_icb_cmd_read),
    .sa_icb_cmd_wdata  (vif.sa_icb_cmd_wdata),
    .sa_icb_cmd_wmask  (vif.sa_icb_cmd_wmask),
    .sa_icb_cmd_len    (vif.sa_icb_cmd_len),
    .sa_icb_rsp_valid  (vif.sa_icb_rsp_valid),
    .sa_icb_rsp_ready  (vif.sa_icb_rsp_ready),
    .sa_icb_rsp_rdata  (vif.sa_icb_rsp_rdata),
    .sa_icb_rsp_err    (vif.sa_icb_rsp_err),

    // 下游 ICB 主接口
    .m_icb_cmd_valid   (vif.m_icb_cmd_valid),
    .m_icb_cmd_ready   (vif.m_icb_cmd_ready),
    .m_icb_cmd_addr    (vif.m_icb_cmd_addr),
    .m_icb_cmd_read    (vif.m_icb_cmd_read),
    .m_icb_cmd_wdata   (vif.m_icb_cmd_wdata),
    .m_icb_cmd_wmask   (vif.m_icb_cmd_wmask),
    .m_icb_rsp_valid   (vif.m_icb_rsp_valid),
    .m_icb_rsp_ready   (vif.m_icb_rsp_ready),
    .m_icb_rsp_rdata   (vif.m_icb_rsp_rdata),
    .m_icb_rsp_err     (vif.m_icb_rsp_err)
  );

  // -------------------------------------------------
  // 将 modport-typed virtual interface 下发给各 agent 的
  // driver / monitor（通过 config_db）
  // -------------------------------------------------
  initial begin
    // 上游（SA）侧：Driver/Monitor 各拿对应的 modport
    virtual icb_unalign_bridge_if#(WIDTH,ADDR_W,ICB_LEN_W,DW).SA_DRV sa_drv_vif = vif;
    virtual icb_unalign_bridge_if#(WIDTH,ADDR_W,ICB_LEN_W,DW).SA_MON sa_mon_vif = vif;

    // 下游（M）侧：Driver/Monitor 各拿对应的 modport
    virtual icb_unalign_bridge_if#(WIDTH,ADDR_W,ICB_LEN_W,DW).M_DRV  m_drv_vif  = vif;
    virtual icb_unalign_bridge_if#(WIDTH,ADDR_W,ICB_LEN_W,DW).M_MON  m_mon_vif  = vif;

    // === 上游 SA agent ===
    // driver
    uvm_config_db#(virtual icb_unalign_bridge_if#(WIDTH,ADDR_W,ICB_LEN_W,DW).SA_DRV )::set(
      null, "uvm_test_top.env.sa_agent.driver", "vif", sa_drv_vif
    );
    // monitor
    uvm_config_db#(virtual icb_unalign_bridge_if#(WIDTH,ADDR_W,ICB_LEN_W,DW).SA_MON )::set(
      null, "uvm_test_top.env.sa_agent.monitor", "vif", sa_mon_vif
    );

    // 也可用通配符传给 agent 让其内部分发（按你环境决定是否需要）
    // uvm_config_db#(virtual icb_unalign_bridge_if#(WIDTH,ADDR_W,ICB_LEN_W,DW).SA_DRV )::set(
    //   null, "uvm_test_top.env.sa_agent.*", "vif_drv", sa_drv_vif
    // );
    // uvm_config_db#(virtual icb_unalign_bridge_if#(WIDTH,ADDR_W,ICB_LEN_W,DW).SA_MON )::set(
    //   null, "uvm_test_top.env.sa_agent.*", "vif_mon", sa_mon_vif
    // );

    // === 下游 M agent ===
    // driver
    uvm_config_db#(virtual icb_unalign_bridge_if#(WIDTH,ADDR_W,ICB_LEN_W,DW).M_DRV )::set(
      null, "uvm_test_top.env.m_agent.driver", "vif", m_drv_vif
    );
    // monitor
    uvm_config_db#(virtual icb_unalign_bridge_if#(WIDTH,ADDR_W,ICB_LEN_W,DW).M_MON )::set(
      null, "uvm_test_top.env.m_agent.monitor", "vif", m_mon_vif
    );
    //   ✅ 直接 virtual interface_type.modport var = interface_inst; 可行；

    //   ✅ 接口比 modport 多的信号不影响使用；
  
    //   ⚠️ 确保参数与类型一致，最好用 typedef 统一；
  
    //   ⚠️ get/set 的模板参数必须与字段类型一模一样，否则取不到。
    // 启动 UVM
    `uvm_info("tb_top","------uvm run test start--------",UVM_LOW);
    run_test();
  end

endmodule
`endif
