// ======================================================
// golden_mem（绑定到 SA 侧，下游与 DUT 无直接连线）
// - 提供 apply_txn(addr, read, wmask, wdata) 由 tb/driver 调用
// - 字节寻址影子内存，写时更新；读不改动
// - 提供 read_byte() 给 tb 校验
// ======================================================
module golden_mem_sa #(
  parameter WIDTH=32,
  parameter ADDR_W=32,
  parameter ICB_LEN_W=3
)(
  input  wire clk,
  input  wire rst_n
);
  localparam DW = WIDTH/8;
  localparam MEM_BYTES = 1<<16;
  byte golden [0:MEM_BYTES-1];
  integer gi_write;
  // 由 tb 在发起事务过程中逐拍调用
  task automatic apply_txn(
    input logic [ADDR_W-1:0] addr,
    input logic              read,
    input logic [DW-1:0]     wmask,
    input logic [WIDTH-1:0]  wdata
  );
    if (!read) begin
        for (gi_write=0; gi_write<DW; gi_write++) begin
            if (wmask[gi_write]) begin
              int unsigned a = addr + gi_write;
              if (a<MEM_BYTES) golden[a] = wdata[8*gi_write +: 8];
            end
          end
          
    end
  endtask

  function byte read_byte(input int unsigned addr);
    if (addr < MEM_BYTES) return golden[addr];
    else return 8'h00;
  endfunction
endmodule