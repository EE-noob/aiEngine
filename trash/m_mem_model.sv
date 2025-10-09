// ======================================================
// 下游 m_mem 模型（也可 bind 到 DUT）
// - 字节寻址内存
// - 写：按 wmask 写入
// - 读：1 拍后返回
// ======================================================
module m_mem_model #(
  parameter WIDTH=32,
  parameter ADDR_W=32
)(
  input  wire clk,
  input  wire rst_n,
  input  wire                   m_icb_cmd_valid,
  output wire                   m_icb_cmd_ready,
  input  wire [ADDR_W-1:0]      m_icb_cmd_addr,
  input  wire                   m_icb_cmd_read,
  input  wire [WIDTH-1:0]       m_icb_cmd_wdata,
  input  wire [WIDTH/8-1:0]     m_icb_cmd_wmask,
  output logic                  m_icb_rsp_valid,
  input  wire                   m_icb_rsp_ready,
  output logic [WIDTH-1:0]      m_icb_rsp_rdata,
  output logic                  m_icb_rsp_err
);
  localparam DW = WIDTH/8;
  localparam MEM_BYTES = 1<<16; // 64KB
  byte mem [0:MEM_BYTES-1];

  // 新增：模块作用域静态循环变量，避免自动变量被层次引用
  integer li_write;    // 写循环
  integer lj_read;     // 读拼装循环
  integer lk_dump;     // 其他需要时也可以共用

  bit always_ready = 1'b1;
  task set_always_ready(input bit en); always_ready = en; endtask
  assign m_icb_cmd_ready = always_ready;

  // 写
  always_ff @(posedge clk) begin
    if (rst_n && m_icb_cmd_valid && m_icb_cmd_ready && !m_icb_cmd_read) begin
              for (li_write=0; li_write<DW; li_write++) begin
                if (m_icb_cmd_wmask[li_write]) begin
                  int unsigned a = m_icb_cmd_addr + li_write;
                  if (a < MEM_BYTES) mem[a] <= m_icb_cmd_wdata[8*li_write +: 8];
                end
              end

    end
  end

  // 读 1 拍后返回
  logic                     rd_pipe_v;
  logic [ADDR_W-1:0]        rd_pipe_a;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rd_pipe_v <= 1'b0;
      m_icb_rsp_valid <= 1'b0;
      m_icb_rsp_rdata <= '0;
      m_icb_rsp_err   <= 1'b0;
    end else begin
      // 捕获读请求
      if (m_icb_cmd_valid && m_icb_cmd_ready && m_icb_cmd_read) begin
        rd_pipe_v <= 1'b1;
        rd_pipe_a <= m_icb_cmd_addr;
      end else begin
        rd_pipe_v <= 1'b0;
      end

      // 返回
      if (rd_pipe_v) begin
        // 组合出 32b
        logic [WIDTH-1:0] r;
        for (lj_read=0; lj_read<DW; lj_read++) begin
          int unsigned a = rd_pipe_a + lj_read;
          r[8*lj_read +: 8] = (a<MEM_BYTES)? mem[a] : 8'h00;
        end
        
        m_icb_rsp_rdata <= r;
        m_icb_rsp_err   <= 1'b0;
        m_icb_rsp_valid <= 1'b1;
      end else if (m_icb_rsp_valid && m_icb_rsp_ready) begin
        m_icb_rsp_valid <= 1'b0;
      end
    end
  end

  // 提供 byte 级读接口给 tb 校验
  function byte read_byte(input int unsigned addr);
    if (addr < MEM_BYTES) return mem[addr];
    else return 8'h00;
  endfunction
endmodule