// 可选：未来把 m_mem 也切到 bind 时，打开这个宏
//`define BIND_M_SIDE
// ======================================================

module tb_icb_unalign_bridge;

  // --------- 参数 ----------
  localparam WIDTH      = 32;
  localparam ADDR_W     = 32;
  localparam ICB_LEN_W  = 3;
  localparam DW         = WIDTH/8;
  localparam CLK_PERIOD = 10; // 100MHz

  // --------- 时钟复位 ----------
  bit clk, rst_n;
  initial begin
    clk = 0;
    forever #(CLK_PERIOD/2) clk = ~clk;
  end

  initial begin
    rst_n = 0;
    repeat(10) @(posedge clk);
    rst_n = 1;
  end

  // ------------------ FSDB -------------------------------
  initial begin
    if ($test$plusargs("dump_fsdb")) begin
      $fsdbDumpfile("icb_unalign_bridge_tb.fsdb");
      $fsdbDumpvars("+all");
      $fsdbDumpSVA();
      $fsdbDumpMDA();
    end
  end

  // --------- DUT 端口 ----------
  // sa (slave/upstream)
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

  // m (master/downstream)
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

  // --------- DUT 实例 ----------
  icb_unalign_bridge #(
    .WIDTH      (WIDTH),
    .ADDR_W     (ADDR_W),
    .OUTS_DEPTH (16),
    .ICB_LEN_W  (ICB_LEN_W),
    .DW         (DW)
  ) dut (
    .clk,
    .rst_n,
    // sa
    .sa_icb_cmd_valid,
    .sa_icb_cmd_ready,
    .sa_icb_cmd_addr,
    .sa_icb_cmd_read,
    .sa_icb_cmd_wdata,
    .sa_icb_cmd_wmask,
    .sa_icb_cmd_len,
    .sa_icb_rsp_valid,
    .sa_icb_rsp_ready,
    .sa_icb_rsp_rdata,
    .sa_icb_rsp_err,
    // m
    .m_icb_cmd_valid,
    .m_icb_cmd_ready,
    .m_icb_cmd_addr,
    .m_icb_cmd_read,
    .m_icb_cmd_wdata,
    .m_icb_cmd_wmask,
    .m_icb_rsp_valid,
    .m_icb_rsp_ready,
    .m_icb_rsp_rdata,
    .m_icb_rsp_err
  );

  // ======================================================
  // 下游存储器模型：m_mem
  // - ICB 一拍 ready
  // - 读 1 拍后返回数据
  // - 严格按 wmask/addr 字节对齐读写
  // ======================================================
`ifndef BIND_M_SIDE
  m_mem_model #(
    .WIDTH (WIDTH),
    .ADDR_W(ADDR_W)
  ) u_m_mem (
    .clk, .rst_n,
    .m_icb_cmd_valid,
    .m_icb_cmd_ready,
    .m_icb_cmd_addr,
    .m_icb_cmd_read,
    .m_icb_cmd_wdata,
    .m_icb_cmd_wmask,
    .m_icb_rsp_valid,
    .m_icb_rsp_ready,
    .m_icb_rsp_rdata,
    .m_icb_rsp_err
  );
`endif

  // ======================================================
  // golden_mem：绑定到 SA 侧（在事务发起时由 driver 调用其 apply_txn）
  // ======================================================
  bind icb_unalign_bridge golden_mem_sa #(
    .WIDTH (WIDTH),
    .ADDR_W(ADDR_W),
    .ICB_LEN_W(ICB_LEN_W)
  ) u_golden_sa (
    .clk,
    .rst_n
  );

`ifdef BIND_M_SIDE
  bind icb_unalign_bridge m_mem_model #(
    .WIDTH (WIDTH),
    .ADDR_W(ADDR_W)
  ) u_m_mem (
    .clk, .rst_n,
    .m_icb_cmd_valid,
    .m_icb_cmd_ready,
    .m_icb_cmd_addr,
    .m_icb_cmd_read,
    .m_icb_cmd_wdata,
    .m_icb_cmd_wmask,
    .m_icb_rsp_valid,
    .m_icb_rsp_ready,
    .m_icb_rsp_rdata,
    .m_icb_rsp_err
  );
`endif

  // ======================================================
  // 激励事务类（不依赖 UVM）
  // ======================================================
  class icb_cmd_tr;
    rand bit [ADDR_W-1:0] addr;
    rand bit              read;        // 1=读, 0=写
    rand bit [ICB_LEN_W-1:0] len;      // 拍数 = len+1
    rand bit [WIDTH-1:0]  wdata[];     // 写数据数组，size=len+1
    rand bit [DW-1:0]     wmask;       // 每拍相同的字节掩码（简化）
  //   function new();
  //   wdata = new[len0];
  // endfunction
    constraint c_len { len inside {[0:(1<<ICB_LEN_W)-1]}; }

    // ---- 关键：让求解器先定 read/len，再决定 wdata 的 size ----
  constraint c_solve_order {
    solve read before wdata;
    solve len  before wdata;
  }

    constraint c_wsize {
      if (read) wdata.size()==0;
      else      wdata.size()==(len+1);
    }
    //写掩码非 0
    constraint c_wmask {
      if (!read) wmask != '0;
    }
    // 允许产生各种非对齐
    constraint c_addr_lo_soft { soft addr[1:0] inside {2'b00,2'b01,2'b10,2'b11}; }

    function void print();
      $display("[TR] addr=0x%08x read=%0d len=%0d beats=%0d wmask=%b",
        addr, read, len, (len+1), wmask);
      if (!read) begin
        foreach (wdata[i]) $display("      wdata[%0d]=0x%08x", i, wdata[i]);
      end
    endfunction
  endclass

  // ======================================================
  // Driver：握手一次写入 cmd FIFO，但在整个 burst 期间
  // 持续更新 sa_icb_cmd_wdata/wmask 以匹配当前拍
  // ======================================================
  task send_tr(input icb_cmd_tr tr, output int last_beat_addr_lo, output int total_beats);
    int beats;
    int beat_idx = 0;
    int rsp_cnt = 0;
    beats = tr.len + 1;
    total_beats = beats;
    last_beat_addr_lo = tr.addr + (beats-1)*DW;

    // 1) 命令首拍：握手写入 FIFO（addr/read/len）
    @(posedge clk);
    sa_icb_cmd_addr  <= tr.addr;
    sa_icb_cmd_read  <= tr.read;
    sa_icb_cmd_len   <= tr.len;
    sa_icb_cmd_wmask <= (tr.read)? '0 : tr.wmask;
    sa_icb_cmd_wdata <= (tr.read)? '0 : tr.wdata[0];
    sa_icb_cmd_valid <= 1'b1;

    // ready 等待
    do @(posedge clk); while(!sa_icb_cmd_ready);
    // 首拍握手完成
    sa_icb_cmd_valid <= 1'b0;

    // 2) 在整个 burst 生命周期内，随着 DUT 往下游发每拍 m_icb_cmd_valid&ready，
    //    同步更新 sa_icb_cmd_wdata/wmask 为当前拍（仅写）
    while (beat_idx < beats) begin
      @(posedge clk);
      // 当下游消费一拍
      if (m_icb_cmd_valid && m_icb_cmd_ready) begin
        if (!tr.read) begin
          sa_icb_cmd_wmask <= tr.wmask;
          sa_icb_cmd_wdata <= tr.wdata[beat_idx];
        end
        beat_idx++;
      end
    end

    // 3) 等待上游响应拍数匹配（读：每拍返回；写：最后一拍返回）
    sa_icb_rsp_ready <= 1'b1;
    while (rsp_cnt < beats) begin
      @(posedge clk);
      if (sa_icb_rsp_valid && sa_icb_rsp_ready) begin
        rsp_cnt++;
      end
    end
    sa_icb_rsp_ready <= 1'b0;
  endtask

  // ======================================================
  // 应用事务并调用 golden_mem（bind 在 dut 下）记录期望值
  // ======================================================
  import "DPI-C" context function void sv_fatal(string s); // 可选：示例留空

  // 在 bind 实例下可层级调用：
  // dut.u_golden_sa.apply_txn(addr, read, len, wmask, wdata[i]) 逐拍应用
  task apply_golden(input icb_cmd_tr tr);
    int beats = 1;//tr.len+1;
    for (int i=0;i<beats;i++) begin
      $display("traddr=",tr.addr);


      dut.u_golden_sa.apply_txn(tr.addr + i*DW, tr.read, tr.wmask, (tr.read? '0 : tr.wdata[i]));
    end
  endtask

  // ======================================================
  // Case 结束后的自校验：对比 golden_mem 与 m_mem 的重叠地址窗口
  // ======================================================
  integer err_count = 0;

  task check_window(input int unsigned base_addr, input int unsigned beats);
    int unsigned lo = base_addr & 'hffff_fffc; // 向下按 4 对齐
    int unsigned hi = base_addr + beats*DW - 1;

    int unsigned addr;
    bit [7:0] g_b, m_b;
    int local_err = 0;

    for (addr = lo; addr <= hi; addr++) begin
      g_b = dut.u_golden_sa.read_byte(addr);
`ifndef BIND_M_SIDE
      m_b = u_m_mem.read_byte(addr);
`else
      m_b = dut.u_m_mem.read_byte(addr);
`endif
      if (g_b !== m_b) begin
        local_err++;
        $display("  MISMATCH @0x%08x  golden=%02x  m_mem=%02x", addr, g_b, m_b);
      end
    end

    if (local_err==0) $display("[CHECK] Window 0x%08x~0x%08x PASS", lo, hi);
    else begin
      $display("[CHECK] Window 0x%08x~0x%08x FAIL: %0d errors", lo, hi, local_err);
      err_count += local_err;
    end
  endtask

  // ======================================================
  // Directed + Random 场景
  // ======================================================
  function bit [WIDTH-1:0] rand_word(); rand_word = $urandom(); endfunction

  task run_directed();
    icb_cmd_tr tr;
    int last_lo, beats;

    // 1) 对齐写（len=0）
    tr = new();
    tr.addr = 32'h0000_1000; tr.read = 0; tr.len=0; tr.wmask=4'b1111;
    tr.wdata = new[1]; tr.wdata[0] = 32'hA5A5_5A5A;
    tr.print();
    //apply_golden(tr);
    send_tr(tr, last_lo, beats);
    check_window(tr.addr, beats);

    // 2) 非对齐写（addr[1:0]=2），len=0
    tr = new();
    tr.addr = 32'h0000_1002; tr.read = 0; tr.len=0; tr.wmask=4'b1111;
    tr.wdata = new[1]; tr.wdata[0] = 32'h1122_3344;
    tr.print();
    //apply_golden(tr);
    send_tr(tr, last_lo, beats);
    check_window(tr.addr, beats);

    // 3) 对齐读 burst（len=3 => 4 拍）
    tr = new();
    tr.addr = 32'h0000_1000; tr.read = 1; tr.len=3; tr.wmask='0; tr.wdata = new[0];
    tr.print();
    //apply_golden(tr); // 读对 golden 不写，但为了统一流程可不调用
    send_tr(tr, last_lo, beats);
    check_window(tr.addr, beats);

    // 4) 非对齐写 burst（len=2 => 3 拍），掩码=1111
    tr = new();
    tr.addr = 32'h0000_1001; tr.read = 0; tr.len=2; tr.wmask=4'b1111;
    tr.wdata = new[3];
    foreach(tr.wdata[i]) tr.wdata[i] = rand_word();
    tr.print();
    //apply_golden(tr);
    send_tr(tr, last_lo, beats);
    check_window(tr.addr, beats);

    // 5) 非对齐读 burst（len=2）
    tr = new();
    tr.addr = 32'h0000_1003; tr.read = 1; tr.len=2; tr.wmask='0; tr.wdata=new[0];
    tr.print();
    //apply_golden(tr);
    send_tr(tr, last_lo, beats);
    check_window(tr.addr, beats);
  endtask

  task run_random(int N=10);
    icb_cmd_tr tr;
    int last_lo, beats;

    repeat(N) begin
      tr = new();
      assert(tr.randomize() with {
        // 控制分布：读写各一半
        read dist {0:=50, 1:=50};
        // 地址覆盖更多非对齐
        addr[7:0] inside {[8'h00:8'hEF]};
        // 写时：适当稀疏掩码
        (!read) -> (wmask dist {
          4'b0001:=10,4'b0010:=10,4'b0100:=10,4'b1000:=10,
          4'b0011:=10,4'b1100:=10,4'b0110:=10,4'b1111:=30
        });
      });
      if (!tr.read) begin
        tr.wdata = new[tr.len+1];
        foreach(tr.wdata[i]) tr.wdata[i] = rand_word();
      end
      else begin
        tr.wdata = new[0];
      end
      tr.print();
      //apply_golden(tr);
      send_tr(tr, last_lo, beats);
      check_window(tr.addr, beats);
    end
  endtask

  // ======================================================
  // Finish 任务（彩色 PASS/FAIL 大字）
  // ======================================================
  task Finish ();
    static string GREEN="\033[1;32m", RED="\033[1;31m", NC="\033[0m";
    static string PASS_ASCII[$]= '{
      "██████╗  █████╗  ███████╗███████╗",
      "██╔══██╗██╔══██╗██╔════╝██╔════╝",
      "██████╔╝███████║███████╗███████╗",
      "██╔═══╝ ██╔══██║╚════██║╚════██║",
      "██║     ██║  ██║███████║███████║",
      "╚═╝     ╚═╝  ╚═╝╚══════╝╚══════╝"
    };
    static string FAIL_ASCII[$]= '{
      "███████╗ █████╗  ██╗██╗     ",
      "██╔════╝██╔══██╗ ██║██║     ",
      "███████╗███████║ ██║██║     ",
      "██╔════╝██╔══██║ ██║██║     ",
      "██║     ██║  ██║ ██║███████╗",
      "╚═╝     ╚═╝  ╚═╝ ╚═╝╚══════╝"
    };
    $display("\n////////////////////////////////////////////////////////////////////////////");
    $display("%0t: Simulation ended, ERROR count: %0d", $time, err_count);
    $display("////////////////////////////////////////////////////////////////////////////\n");
    if (err_count==0) foreach (PASS_ASCII[i]) $display("%s%s%s",GREEN,PASS_ASCII[i],NC);
    else              foreach (FAIL_ASCII[i]) $display("%s%s%s",RED,FAIL_ASCII[i],NC);
    $finish;
  endtask

  // ======================================================
  // 主流程
  // ======================================================
  initial begin
    // 默认值
    sa_icb_cmd_valid = 0;
    sa_icb_cmd_addr  = '0;
    sa_icb_cmd_read  = 0;
    sa_icb_cmd_len   = '0;
    sa_icb_cmd_wdata = '0;
    sa_icb_cmd_wmask = '0;
    sa_icb_rsp_ready = 0;

`ifndef BIND_M_SIDE
    // 下游 ready 拉高（可注入 backpressure 测试）
    u_m_mem.set_always_ready(1);
`else
    dut.u_m_mem.set_always_ready(1);
`endif

    wait(rst_n==1);
    repeat(5) @(posedge clk);

    $display("==== Directed Cases ====");
    run_directed();

    $display("==== Random Cases ====");
    run_random(15);

    Finish();
  end

endmodule




