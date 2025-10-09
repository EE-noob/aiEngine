// ICB Unalign Bridge Module
// 功能：将非对齐的ICB访问转换为对齐访问，支持burst和outstanding管理

module icb_unalign_bridge #(
    parameter WIDTH       = 32,           // 数据位宽
    parameter ADDR_W      = 32,           // 地址位宽  
    parameter OUTS_DEPTH  = 16,           // 上游outstanding深度
    parameter ICB_LEN_W   = 3,            // burst长度位宽
    parameter DW          = WIDTH/8       // 数据字节数
  )(
    input  wire                   clk,
    input  wire                   rst_n,
  
    // 上游ICB从接口
    //cmd请求通道
    input  wire                   sa_icb_cmd_valid,
    output wire                   sa_icb_cmd_ready,
    input  wire [ADDR_W-1:0]      sa_icb_cmd_addr,
    input  wire                   sa_icb_cmd_read,
    input  wire [DW-1:0]          sa_icb_cmd_wmask, 
    input  wire [ICB_LEN_W-1:0]   sa_icb_cmd_len,
    //cmd写数据通道
    input  wire [WIDTH-1:0]       sa_icb_cmd_wdata,
    input  wire                   sa_icb_w_valid,
    output wire                   sa_icb_w_ready,
   //rsp读数据通道
    output wire                   sa_icb_rsp_valid,
    input  wire                   sa_icb_rsp_ready,
    output wire [WIDTH-1:0]       sa_icb_rsp_rdata,
    output wire                   sa_icb_rsp_err,
  
    // 下游ICB主接口
    output wire                   m_icb_cmd_valid,
    input  wire                   m_icb_cmd_ready,
    output wire [ADDR_W-1:0]      m_icb_cmd_addr,
    output wire                   m_icb_cmd_read,
    output wire [WIDTH-1:0]       m_icb_cmd_wdata,
    output wire [DW-1:0]          m_icb_cmd_wmask,
    input  wire                   m_icb_rsp_valid,
    output wire                   m_icb_rsp_ready,
    input  wire [WIDTH-1:0]       m_icb_rsp_rdata,
    input  wire                   m_icb_rsp_err
  );
  
    // ========================================
    // 参数和常量定义
    // ========================================
    localparam FIFO_DEPTH = 2**($clog2(OUTS_DEPTH));
    localparam PTR_W = $clog2(FIFO_DEPTH);
    localparam CREDIT_W = 3;  // 支持最多4个outstanding
    
    // ========================================
    // 信号声明
    // ========================================
    
    // Outstanding FIFO相关信号
    logic                        cmd_fifo_wen;
    logic                        cmd_fifo_ren;
    logic                        cmd_fifo_full;
    logic                        cmd_fifo_empty;
    logic [ADDR_W+ICB_LEN_W:0]   cmd_fifo_wdata;
    logic [ADDR_W+ICB_LEN_W:0]   cmd_fifo_rdata;
    logic [PTR_W:0]              cmd_fifo_wptr;
    logic [PTR_W:0]              cmd_fifo_rptr;
    logic [ADDR_W+ICB_LEN_W:0]   cmd_fifo_mem[FIFO_DEPTH];
    
    // 解析后的请求信息
    logic                        cur_is_read;
    logic [ADDR_W-1:0]           cur_addr;
    logic [ICB_LEN_W-1:0]        cur_len;
    logic [1:0]                  cur_offset;
    logic [ADDR_W-1:0]           cur_base_addr;
    logic                        cur_cross_boundary;
    logic [ICB_LEN_W:0]          cur_burst_cnt;
    logic [ICB_LEN_W:0]          burst_cnt_nxt;
    
    // 写数据缓存
    logic [WIDTH-1:0]            wdata_buf;
    logic [DW-1:0]               wmask_buf;
    logic                        wdata_buf_valid;
    logic [WIDTH-1:0]            wdata_aligned;
    logic [DW-1:0]               wmask_aligned;
    
    // 读数据缓存
    logic [WIDTH-1:0]            rdata_buf;
    logic                        rdata_buf_valid;
    logic [WIDTH-1:0]            rdata_aligned;
    
    // Outstanding credit管理
    logic [CREDIT_W-1:0]        credit_cnt;
    logic                        credit_avail;
    logic                        credit_consume;
    logic                        credit_release;
    
    // 状态机
    typedef enum logic [1:0] {
      IDLE    = 2'b00,
      FIRST   = 2'b01,
      last  = 2'b10,
      BURST   = 2'b11
    } state_t;
    
    state_t                      cmd_state;
    state_t                      cmd_state_nxt;
    state_t                      rsp_state;
    state_t                      rsp_state_nxt;
    
    // 控制信号
    logic                        cmd_fire;
    logic                        rsp_fire;
    logic                        is_last_burst;
    logic                        last_beat_sent;
    
    // 响应FIFO
    logic                        rsp_fifo_wen;
    logic                        rsp_fifo_ren;
    logic                        rsp_fifo_full;
    logic                        rsp_fifo_empty;
    logic [WIDTH:0]              rsp_fifo_wdata;
    logic [WIDTH:0]              rsp_fifo_rdata;
    logic [PTR_W:0]              rsp_fifo_wptr;
    logic [PTR_W:0]              rsp_fifo_rptr;
    logic [WIDTH:0]              rsp_fifo_mem[FIFO_DEPTH];
    
    // ========================================
    // Outstanding命令FIFO
    // ========================================
    
    // FIFO写入控制
    assign cmd_fifo_wen = sa_icb_cmd_valid & sa_icb_cmd_ready;
    assign cmd_fifo_wdata = {sa_icb_cmd_read, sa_icb_cmd_addr, sa_icb_cmd_len};
    
    // FIFO读取控制
    assign cmd_fifo_ren = !cmd_fifo_empty & credit_avail & (cmd_state == IDLE);
    assign {cur_is_read, cur_addr, cur_len} = cmd_fifo_rdata;
    
    // FIFO满空标志
    assign cmd_fifo_full = (cmd_fifo_wptr[PTR_W] != cmd_fifo_rptr[PTR_W]) & 
                           (cmd_fifo_wptr[PTR_W-1:0] == cmd_fifo_rptr[PTR_W-1:0]);
    assign cmd_fifo_empty = (cmd_fifo_wptr == cmd_fifo_rptr);
    
    // FIFO指针更新
    always_ff @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
        cmd_fifo_wptr <= '0;
        cmd_fifo_rptr <= '0;
      end else begin
        if (cmd_fifo_wen)
          cmd_fifo_wptr <= cmd_fifo_wptr + 1'b1;
        if (cmd_fifo_ren)
          cmd_fifo_rptr <= cmd_fifo_rptr + 1'b1;
      end
    end
    
    // FIFO存储器
    always_ff @(posedge clk) begin
      if (cmd_fifo_wen)
        cmd_fifo_mem[cmd_fifo_wptr[PTR_W-1:0]] <= cmd_fifo_wdata;
    end
    assign cmd_fifo_rdata = cmd_fifo_mem[cmd_fifo_rptr[PTR_W-1:0]];
    
    // ========================================
    // 地址对齐计算
    // ========================================
    
    assign cur_offset = cur_addr[1:0];
    assign cur_base_addr = {cur_addr[ADDR_W-1:2], 2'b00};
    
    // // 判断是否跨越4字节边界
    // always_comb begin
    //   logic [2:0] byte_cnt;
    //   byte_cnt = '0;
    //   for (int i = 0; i < DW; i++) begin
    //     if (sa_icb_cmd_wmask[i])
    //       byte_cnt = byte_cnt + 1'b1;
    //   end
    //   cur_cross_boundary = (cur_offset + byte_cnt) > DW;
    // end
    
    assign cur_cross_boundary = cur_addr[1:0]== 2'b00;
    // ========================================
    // 命令发送状态机
    // ========================================
    
    always_ff @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
        cmd_state <= IDLE;
        cur_burst_cnt <= '0;
        last_beat_sent <= 1'b0;
      end else begin
        cmd_state <= cmd_state_nxt;
        cur_burst_cnt <= burst_cnt_nxt;
        
        case (cmd_state_nxt)
          IDLE: last_beat_sent <= 1'b0;
          FIRST: begin
            if (cmd_fire && cur_cross_boundary)
              last_beat_sent <= 1'b0;
          end
          last: begin
            if (cmd_fire)
              last_beat_sent <= 1'b1;
          end
          default: ;
        endcase
      end
    end
    
    // 状态机下一状态逻辑
    always_comb begin
      cmd_state_nxt = cmd_state;
      burst_cnt_nxt = cur_burst_cnt;
      
      case (cmd_state)
        IDLE: begin
          if (cmd_fifo_ren) begin
            cmd_state_nxt = FIRST;
            burst_cnt_nxt = '0;
          end
        end
        
        FIRST: begin
          if (cmd_fire) begin
            if (cur_cross_boundary) begin
              cmd_state_nxt = last;
            end else if (is_last_burst) begin
              cmd_state_nxt = IDLE;
            end else begin
              cmd_state_nxt = BURST;
              burst_cnt_nxt = cur_burst_cnt + 1'b1;
            end
          end
        end
        
        last: begin
          if (cmd_fire) begin
            if (is_last_burst) begin
              cmd_state_nxt = IDLE;
            end else begin
              cmd_state_nxt = BURST;
              burst_cnt_nxt = cur_burst_cnt + 1'b1;
            end
          end
        end
        
        BURST: begin
          if (cmd_fire) begin
            if (cur_cross_boundary && !last_beat_sent) begin
              cmd_state_nxt = last;
            end else if (is_last_burst) begin
              cmd_state_nxt = IDLE;
            end else begin
              burst_cnt_nxt = cur_burst_cnt + 1'b1;
            end
          end
        end
      endcase
    end
    
    assign is_last_burst = (cur_burst_cnt == cur_len);
    assign cmd_fire =sa_icb_w_valid & sa_icb_w_ready & m_icb_cmd_valid & m_icb_cmd_ready;
    
    //TODO:sa_icb_w_ready 的逻辑是
    //sa_icb_w_ready
    // ========================================
    // 写数据对齐处理
    // ========================================
    
    always_ff @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
        wdata_buf <= '0;
        wmask_buf <= '0;
        wdata_buf_valid <= 1'b0;
      end else begin
        //if (cmd_state == FIRST && cmd_fire && cur_cross_boundary) begin
        if ( (cmd_state == FIRST || cmd_state ==  BURST) ) begin
          // 缓存跨界的高位部分
          wdata_buf <= sa_icb_cmd_wdata >> ((DW - cur_offset) * 8);
          wmask_buf <= sa_icb_cmd_wmask >> (DW - cur_offset);
          wdata_buf_valid <= 1'b1;
        end else if (cmd_state == last && cmd_fire) begin
          wdata_buf_valid <= 1'b0;
        end
      end
    end
    
    // 生成对齐的写数据和掩码
    always_comb begin
      wdata_aligned = '0;
      wmask_aligned = '0;
      
      if (cmd_state == FIRST || cmd_state == BURST) begin
        if (cur_cross_boundary) begin
          // 跨界第一拍：低位部分
          //TODO:乘法优化为移位
          wdata_aligned = sa_icb_cmd_wdata << (cur_offset * 8);
          wmask_aligned = sa_icb_cmd_wmask << cur_offset;
        end else begin
          // 不跨界
          wdata_aligned = sa_icb_cmd_wdata << (cur_offset * 8);
          wmask_aligned = sa_icb_cmd_wmask << cur_offset;
        end
      end else if (cmd_state == last) begin
        // 跨界第二拍：高位部分
        if (wdata_buf_valid) begin
          wdata_aligned = wdata_buf;
          wmask_aligned = wmask_buf;
        end
      end
    end
    
    // ========================================
    // 读数据对齐处理
    // ========================================
    
    always_ff @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
        rdata_buf <= '0;
        rdata_buf_valid <= 1'b0;
      end else begin
        if (rsp_fire && cur_is_read) begin
          if (rsp_state == FIRST && cur_cross_boundary) begin
            // 缓存跨界的低位部分
            rdata_buf <= m_icb_rsp_rdata >> (cur_offset * 8);
            rdata_buf_valid <= 1'b1;
          end else if (rsp_state == last) begin
            rdata_buf_valid <= 1'b0;
          end
        end
      end
    end
    
    // 生成对齐的读数据
    always_comb begin
      rdata_aligned = '0;
      
      if (cur_is_read) begin
        if (rsp_state == FIRST || rsp_state == BURST) begin
          if (cur_cross_boundary && rdata_buf_valid) begin
            // 跨界情况：拼接两拍数据
            rdata_aligned = (m_icb_rsp_rdata << ((DW - cur_offset) * 8)) | rdata_buf;
          end else begin
            // 不跨界
            rdata_aligned = m_icb_rsp_rdata >> (cur_offset * 8);
          end
        end else if (rsp_state == last) begin
          // 第二拍数据与缓存拼接
          rdata_aligned = (m_icb_rsp_rdata << ((DW - cur_offset) * 8)) | rdata_buf;
        end
      end
    end
    
    // ========================================
    // Outstanding Credit管理
    // ========================================
    
    assign credit_avail = (credit_cnt > 0);
    assign credit_consume = cmd_fire;
    assign credit_release = m_icb_rsp_valid & m_icb_rsp_ready;
    
    always_ff @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
        credit_cnt <= 3'd4;  // 初始4个credit
      end else begin
        case ({credit_consume, credit_release})
          2'b10: credit_cnt <= credit_cnt - 1'b1;
          2'b01: credit_cnt <= credit_cnt + 1'b1;
          default: ;  // 00或11不变
        endcase
      end
    end
    
    // ========================================
    // 响应处理状态机
    // ========================================
    
    always_ff @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
        rsp_state <= IDLE;
      end else begin
        rsp_state <= rsp_state_nxt;
      end
    end
    
    always_comb begin
      rsp_state_nxt = rsp_state;
      
      case (rsp_state)
        IDLE: begin
          if (rsp_fire)
            rsp_state_nxt = FIRST;
        end
        
        FIRST: begin
          if (rsp_fire) begin
            if (cur_cross_boundary)
              rsp_state_nxt = last;
            else if (is_last_burst)
              rsp_state_nxt = IDLE;
            else
              rsp_state_nxt = BURST;
          end
        end
        
        last: begin
          if (rsp_fire) begin
            if (is_last_burst)
              rsp_state_nxt = IDLE;
            else
              rsp_state_nxt = BURST;
          end
        end
        
        BURST: begin
          if (rsp_fire) begin
            if (cur_cross_boundary && !last_beat_sent)
              rsp_state_nxt = last;
            else if (is_last_burst)
              rsp_state_nxt = IDLE;
          end
        end
      endcase
    end
    
    assign rsp_fire = m_icb_rsp_valid & m_icb_rsp_ready;
    
    // ========================================
    // 响应FIFO
    // ========================================
    
    assign rsp_fifo_wen = rsp_fire && (
      (cur_is_read && ((rsp_state == FIRST && !cur_cross_boundary) || 
                       (rsp_state == last) || 
                       (rsp_state == BURST))) ||
      (!cur_is_read && is_last_burst && 
       ((rsp_state == FIRST && !cur_cross_boundary) || (rsp_state == last)))
    );
    
    assign rsp_fifo_wdata = {m_icb_rsp_err, rdata_aligned};
    assign rsp_fifo_ren = sa_icb_rsp_valid & sa_icb_rsp_ready;
    
    assign rsp_fifo_full = (rsp_fifo_wptr[PTR_W] != rsp_fifo_rptr[PTR_W]) & 
                           (rsp_fifo_wptr[PTR_W-1:0] == rsp_fifo_rptr[PTR_W-1:0]);
    assign rsp_fifo_empty = (rsp_fifo_wptr == rsp_fifo_rptr);
    
    always_ff @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
        rsp_fifo_wptr <= '0;
        rsp_fifo_rptr <= '0;
      end else begin
        if (rsp_fifo_wen)
          rsp_fifo_wptr <= rsp_fifo_wptr + 1'b1;
        if (rsp_fifo_ren)
          rsp_fifo_rptr <= rsp_fifo_rptr + 1'b1;
      end
    end
    
    always_ff @(posedge clk) begin
      if (rsp_fifo_wen)
        rsp_fifo_mem[rsp_fifo_wptr[PTR_W-1:0]] <= rsp_fifo_wdata;
    end
    assign rsp_fifo_rdata = rsp_fifo_mem[rsp_fifo_rptr[PTR_W-1:0]];
    
    // ========================================
    // 接口信号连接
    // ========================================
    
    // 上游接口
    assign sa_icb_cmd_ready = !cmd_fifo_full;
    assign sa_icb_rsp_valid = !rsp_fifo_empty;
    assign {sa_icb_rsp_err, sa_icb_rsp_rdata} = rsp_fifo_rdata;
    
    // 下游接口
    assign m_icb_cmd_valid = (cmd_state != IDLE) && credit_avail;
    assign m_icb_cmd_addr = (cmd_state == last) ? (cur_base_addr + DW) : cur_base_addr;
    assign m_icb_cmd_read = cur_is_read;
    assign m_icb_cmd_wdata = wdata_aligned;
    assign m_icb_cmd_wmask = wmask_aligned;
    assign m_icb_rsp_ready = !rsp_fifo_full;
  
  endmodule