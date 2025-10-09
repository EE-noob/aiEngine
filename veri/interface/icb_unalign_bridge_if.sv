// ============================================================
// ICB Unalign Bridge Interface (parameterized, split CBs)
// - 驱动与监视 clocking block 分离：*_drv / *_mon
// - monitor 的 clocking block 全部为 input（只采样不驱动）
// ============================================================
interface icb_unalign_bridge_if #(
    parameter int WIDTH      = 32,        // 数据位宽
    parameter int ADDR_W     = 32,        // 地址位宽
    parameter int ICB_LEN_W  = 3,         // burst长度位宽
    parameter int DW         = (WIDTH/8), // 字节数
    time setup_time          = 0.1ns,     // 输入采样提前量
    time hold_time           = 0.1ns      // 输出保持量
  )(
    input  logic clk,
    input  logic rst_n
  );
  
    // -----------------------------
    // 与 DUT 端口一致的信号
    // -----------------------------
    // 上游（SA -> DUT）
    logic                   sa_icb_cmd_valid;
    logic                   sa_icb_cmd_ready;
    logic [ADDR_W-1:0]      sa_icb_cmd_addr;
    logic                   sa_icb_cmd_read;
    logic [WIDTH-1:0]       sa_icb_cmd_wdata;
    logic [DW-1:0]          sa_icb_cmd_wmask;
    logic [ICB_LEN_W-1:0]   sa_icb_cmd_len;
  
    logic                   sa_icb_rsp_valid;
    logic                   sa_icb_rsp_ready;
    logic [WIDTH-1:0]       sa_icb_rsp_rdata;
    logic                   sa_icb_rsp_err;
  
    // 下游（DUT -> M）
    logic                   m_icb_cmd_valid;
    logic                   m_icb_cmd_ready;
    logic [ADDR_W-1:0]      m_icb_cmd_addr;
    logic                   m_icb_cmd_read;
    logic [WIDTH-1:0]       m_icb_cmd_wdata;
    logic [DW-1:0]          m_icb_cmd_wmask;
  
    logic                   m_icb_rsp_valid;
    logic                   m_icb_rsp_ready;
    logic [WIDTH-1:0]       m_icb_rsp_rdata;
    logic                   m_icb_rsp_err;
  
    // =========================================================
    // Clocking blocks
    //  - *_drv：供 driver 使用（含 output 能驱动）
    //  - *_mon：供 monitor 使用（全 input 只采样）
    // =========================================================
  
    // ---------- 上游 SA：driver ----------
    clocking cb_sa_drv @(posedge clk);
      default input #setup_time output #hold_time;
      // driver 驱动 -> DUT 接收
      output sa_icb_cmd_valid, sa_icb_cmd_addr, sa_icb_cmd_read;
      output sa_icb_cmd_wdata, sa_icb_cmd_wmask, sa_icb_cmd_len;
      output sa_icb_rsp_ready;
      // driver 采样 <- DUT 驱动
      input  sa_icb_cmd_ready, sa_icb_rsp_valid, sa_icb_rsp_rdata, sa_icb_rsp_err;
    endclocking
  
    // ---------- 上游 SA：monitor（全 input） ----------
    clocking cb_sa_mon @(posedge clk);
      default input #setup_time output #hold_time;
      // 只采样 SA/DUT 之间的全部信号（不驱动）
      input  sa_icb_cmd_valid, sa_icb_cmd_ready, sa_icb_cmd_addr, sa_icb_cmd_read;
      input  sa_icb_cmd_wdata, sa_icb_cmd_wmask, sa_icb_cmd_len;
      input  sa_icb_rsp_valid, sa_icb_rsp_ready, sa_icb_rsp_rdata, sa_icb_rsp_err;
    endclocking
  
    // ---------- 下游 M：driver ----------
    clocking cb_m_drv @(posedge clk);
      default input #setup_time output #hold_time;
      // driver 采样 <- DUT 驱动
      input  m_icb_cmd_valid, m_icb_cmd_addr, m_icb_cmd_read, m_icb_cmd_wdata, m_icb_cmd_wmask;
      input  m_icb_rsp_ready;
      // driver 驱动 -> DUT 接收
      output m_icb_cmd_ready, m_icb_rsp_valid, m_icb_rsp_rdata, m_icb_rsp_err;
    endclocking
  
    // ---------- 下游 M：monitor（全 input） ----------
    clocking cb_m_mon @(posedge clk);
      default input #setup_time output #hold_time;
      // 只采样 DUT/M 之间的全部信号（不驱动）
      input  m_icb_cmd_valid, m_icb_cmd_ready, m_icb_cmd_addr, m_icb_cmd_read;
      input  m_icb_cmd_wdata, m_icb_cmd_wmask;
      input  m_icb_rsp_valid, m_icb_rsp_ready, m_icb_rsp_rdata, m_icb_rsp_err;
    endclocking
  
    // -----------------------------
    // Modports
    // -----------------------------
    // DUT 直连
    modport DUT (
      input  clk, rst_n,
  
      // SA（上游）
      input  sa_icb_cmd_valid,
      output sa_icb_cmd_ready,
      input  sa_icb_cmd_addr,
      input  sa_icb_cmd_read,
      input  sa_icb_cmd_wdata,
      input  sa_icb_cmd_wmask,
      input  sa_icb_cmd_len,
      output sa_icb_rsp_valid,
      input  sa_icb_rsp_ready,
      output sa_icb_rsp_rdata,
      output sa_icb_rsp_err,
  
      // M（下游）
      output m_icb_cmd_valid,
      input  m_icb_cmd_ready,
      output m_icb_cmd_addr,
      output m_icb_cmd_read,
      output m_icb_cmd_wdata,
      output m_icb_cmd_wmask,
      input  m_icb_rsp_valid,
      output m_icb_rsp_ready,
      input  m_icb_rsp_rdata,
      input  m_icb_rsp_err
    );
  
    // 上游 SA 侧
    modport SA_DRV (input rst_n, clocking cb_sa_drv);
    modport SA_MON (input rst_n, clocking cb_sa_mon);
  
    // 下游 M 侧
    modport M_DRV  (input rst_n, clocking cb_m_drv);
    modport M_MON  (input rst_n, clocking cb_m_mon);
  
  `ifndef SYNTHESIS
    // -----------------------------
    // 基础握手断言（仿真用）
    // -----------------------------
    // SA：cmd_valid 保持直到握手
    property p_sa_cmd_handshake;
      @(posedge clk) disable iff(!rst_n)
        sa_icb_cmd_valid |-> (sa_icb_cmd_valid throughout !sa_icb_cmd_ready);
    endproperty
    assert property (p_sa_cmd_handshake)
      else $error("SA cmd handshake violated");
  
    // M：rsp_valid 保持直到握手
    property p_m_rsp_handshake;
      @(posedge clk) disable iff(!rst_n)
        m_icb_rsp_valid |-> (m_icb_rsp_valid throughout !m_icb_rsp_ready);
    endproperty
    assert property (p_m_rsp_handshake)
      else $error("M rsp handshake violated");
  `endif
  
  endinterface
  