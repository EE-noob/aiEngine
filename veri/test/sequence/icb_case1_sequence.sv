`ifndef ICB_SMOKE_SEQUENCE__SV
`define ICB_SMOKE_SEQUENCE__SV

`include "uvm_macros.svh"
import uvm_pkg::*;
import icb_uvm_pkg::*; // 使用包里定义的 ICB_WIDTH/ADDR_W/LEN_W/DW 和 icb_cmd_tr

// 连续进行：非四字节对齐访问(写→读)、四字节对齐访问(写→读)，len ∈ [0..min(8, 2^ICB_LEN_W-1)]
class icb_smoke_sequence extends uvm_sequence#(icb_cmd_tr);
  `uvm_object_utils(icb_smoke_sequence)

  // 配置：每类发多少组
  rand int unsigned unalign_pairs = 4;
  rand int unsigned align_pairs   = 4;

  // 地址发射窗口（示例，可按需修改）
  localparam int unsigned ADDR_LOW  = 'h0000_0000;
  localparam int unsigned ADDR_HIGH = 'h0000_0FFF;

  // len 上限：min(8, 2^ICB_LEN_W - 1)
  localparam int LCAP = ((1<<ICB_LEN_W)-1 < 8) ? (1<<ICB_LEN_W)-1 : 8;

  function new(string name="icb_smoke_sequence");
    super.new(name);
  endfunction

  // 生成不对齐地址：addr[1:0] ∈ {1,2,3}
  function automatic bit [ICB_ADDR_W-1:0] gen_unalign_addr();
    bit [ICB_ADDR_W-1:0] base;
    base = $urandom_range(ADDR_LOW, ADDR_HIGH);
    base[1:0] = $urandom_range(1,3); // 强制非4字节对齐
    return base;
  endfunction

  // 生成对齐地址：addr[1:0] = 0
  function automatic bit [ICB_ADDR_W-1:0] gen_align_addr();
    bit [ICB_ADDR_W-1:0] base;
    base = $urandom_range(ADDR_LOW, ADDR_HIGH);
    base[1:0] = 2'b00; // 4字节对齐
    return base;
  endfunction

  // 生成 len（0..LCAP）
  function automatic bit [ICB_LEN_W-1:0] gen_len();
    return $urandom_range(0, LCAP);
  endfunction

  // 生成掩码（不全0）
  function automatic bit [ICB_DW-1:0] gen_wmask();
    bit [ICB_DW-1:0] m;
    do m = $urandom(); while (m == '0);
    return m;
  endfunction

  // 主体
  virtual task body();
    icb_cmd_tr tr;

    `uvm_info(get_full_name(), $sformatf(
      "ICB smoke start: unalign_pairs=%0d align_pairs=%0d len_max=%0d",
      unalign_pairs, align_pairs, LCAP), UVM_LOW)

    // ----------------------------------------------------
    // 1) 非4字节对齐：写 -> 读
    // ----------------------------------------------------
    for (int i = 0; i < unalign_pairs; i++) begin
      bit [ICB_ADDR_W-1:0] A  = gen_unalign_addr();
      bit [ICB_LEN_W-1:0]  LN = gen_len();
      bit [ICB_DW-1:0]     WM = gen_wmask();
      bit [ICB_WIDTH-1:0]  WD = $urandom();

      // 写
      `uvm_do_with(tr, {
        addr  == A;
        read  == 1'b0;
        wdata == WD;
        wmask == WM;
        len   == LN;
      })

      // 读回
      `uvm_do_with(tr, {
        addr  == A;
        read  == 1'b1;
        // 读不关心写掩码/写数据，但字段必须有值
        wdata == '0;
        wmask == '0;
        len   == LN;
      })
    end

    // ----------------------------------------------------
    // 2) 4字节对齐：写 -> 读
    // ----------------------------------------------------
    for (int j = 0; j < align_pairs; j++) begin
      bit [ICB_ADDR_W-1:0] A  = gen_align_addr();
      bit [ICB_LEN_W-1:0]  LN = gen_len();
      bit [ICB_DW-1:0]     WM = gen_wmask();
      bit [ICB_WIDTH-1:0]  WD = $urandom();

      // 写
      `uvm_do_with(tr, {
        addr  == A;
        read  == 1'b0;
        wdata == WD;
        wmask == WM;
        len   == LN;
      })

      // 读回
      `uvm_do_with(tr, {
        addr  == A;
        read  == 1'b1;
        wdata == '0;
        wmask == '0;
        len   == LN;
      })
    end

    `uvm_info(get_full_name(), "ICB smoke done", UVM_LOW)
  endtask

endclass : icb_smoke_sequence

`endif
