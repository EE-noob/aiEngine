// ============================================================
// ICB Unalign Bridge Testbench with Self-Checking Platform
// ============================================================
//`include "../include/para_define.sv"
`include "../include/icb_transaction.sv"
`include "../include/memory_model.sv"
`include "../include/Finish_task.sv"




// ============================================================
// Main Testbench Module
// ============================================================
module tb_icb_unalign_bridge;
  //记得修改transaction的parameter，尚未用宏的方式链接 
  // Parameters
  localparam WIDTH = 32;
  localparam ADDR_W = 32;
  localparam OUTS_DEPTH = 16;//4;//16;
  localparam ICB_LEN_W = 4;//3;
  localparam DW = WIDTH/8;
  
  // Clock and Reset
  logic clk;
  logic rst_n;
  
  // SA (upstream) ICB interface
  // cmd请求通道
  logic                   sa_icb_cmd_valid;
  logic                   sa_icb_cmd_ready;
  logic [ADDR_W-1:0]      sa_icb_cmd_addr;
  logic                   sa_icb_cmd_read;
  logic [DW-1:0]          sa_icb_cmd_wmask;
  logic [ICB_LEN_W-1:0]   sa_icb_cmd_len;
  // 写数据通道
  logic [WIDTH-1:0]       sa_icb_cmd_wdata;
  logic                   sa_icb_w_valid;
  logic                   sa_icb_w_ready;
  // 读数据响应通道
  logic                   sa_icb_rsp_valid;
  logic                   sa_icb_rsp_ready;
  logic [WIDTH-1:0]       sa_icb_rsp_rdata;
  logic                   sa_icb_rsp_err;
  
  // M (downstream) ICB interface
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
  
  // Test control
  int err_count = 0;
  int test_count = 0;
  
  // Memory models
  memory_model #(ADDR_W, WIDTH) golden_mem;
  memory_model #(ADDR_W, WIDTH) m_mem;
  
  // Transaction queues
  icb_transaction sa_cmd_queue[$];
  icb_transaction m_cmd_queue[$];
  
  // ============================================================
  // DUT Instance
  // ============================================================
  icb_unalign_bridge #(
    .WIDTH      (WIDTH),
    .ADDR_W     (ADDR_W),
    .OUTS_DEPTH (OUTS_DEPTH),
    .ICB_LEN_W  (ICB_LEN_W)
  ) dut (
    .clk                (clk),
    .rst_n              (rst_n),
    // SA interface
    .sa_icb_cmd_valid   (sa_icb_cmd_valid),
    .sa_icb_cmd_ready   (sa_icb_cmd_ready),
    .sa_icb_cmd_addr    (sa_icb_cmd_addr),
    .sa_icb_cmd_read    (sa_icb_cmd_read),
    .sa_icb_cmd_wmask   (sa_icb_cmd_wmask),
    .sa_icb_cmd_len     (sa_icb_cmd_len),
    .sa_icb_cmd_wdata   (sa_icb_cmd_wdata),
    .sa_icb_w_valid     (sa_icb_w_valid),
    .sa_icb_w_ready     (sa_icb_w_ready),
    .sa_icb_rsp_valid   (sa_icb_rsp_valid),
    .sa_icb_rsp_ready   (sa_icb_rsp_ready),
    .sa_icb_rsp_rdata   (sa_icb_rsp_rdata),
    .sa_icb_rsp_err     (sa_icb_rsp_err),
    // M interface
    .m_icb_cmd_valid    (m_icb_cmd_valid),
    .m_icb_cmd_ready    (m_icb_cmd_ready),
    .m_icb_cmd_addr     (m_icb_cmd_addr),
    .m_icb_cmd_read     (m_icb_cmd_read),
    .m_icb_cmd_wdata    (m_icb_cmd_wdata),
    .m_icb_cmd_wmask    (m_icb_cmd_wmask),
    .m_icb_rsp_valid    (m_icb_rsp_valid),
    .m_icb_rsp_ready    (m_icb_rsp_ready),
    .m_icb_rsp_rdata    (m_icb_rsp_rdata),
    .m_icb_rsp_err      (m_icb_rsp_err)
  );
  
  // ============================================================
  // Clock Generation & Signal Initialization
  // ============================================================
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end
  
  // Initialize signals
  initial begin
    sa_icb_cmd_valid = 1'b0;
    sa_icb_w_valid = 1'b0;
    sa_icb_rsp_ready = 1'b0;
    m_icb_cmd_ready = 1'b0;
    m_icb_rsp_valid = 1'b0;
  end
  
  // ============================================================
  // FSDB Dump
  // ============================================================
  initial begin
    //if ($test$plusargs("dump_fsdb")) begin
      $fsdbDumpfile("icb_bridge.fsdb");
      //$fsdbDumpvars("+all");
      $fsdbDumpvars();
      $fsdbDumpSVA();
      $fsdbDumpMDA();
      $fsdbDumpClassObject("tb_icb_unalign_bridge.memory_model");
      $fsdbDumpClassObject("tb_icb_unalign_bridge");
      $fsdbDumpClassObject("tb_icb_unalign_bridge.golden_mem");
      $fsdbDumpClassObject("tb_icb_unalign_bridge.m_mem");
    //end
  end
  
  // ============================================================
  // SA Interface Driver
  // ============================================================
  task automatic drive_sa_cmd(icb_transaction tr,logic is_b2b);
    int beat_cnt = 0;
    
    // Drive command channel
    @(posedge clk);
    
    sa_icb_cmd_valid <= #1 1'b1;
    sa_icb_cmd_addr <= #1 tr.addr;
    sa_icb_cmd_read <=#1  tr.read;
    sa_icb_cmd_len <= #1 tr.len;

    
    wait(sa_icb_cmd_ready);
    @(posedge clk);
    sa_icb_cmd_valid <= 1'b0;
    
    // Drive write data beats separately if it's a write transaction
    if (!tr.read) begin
      foreach(tr.wdata[i]) begin
        //@(posedge clk iff(sa_icb_w_ready));
        @(posedge clk );
       // #1
        sa_icb_w_valid <= 1'b1;
        sa_icb_cmd_wdata <= tr.wdata[i];
        sa_icb_cmd_wmask <= tr.read ? 4'b0000 : tr.wmask[i];  // Use first beat's wmask for cmd channel
        wait(sa_icb_w_ready);
        if(!is_b2b ) begin
          @(posedge clk);
          sa_icb_w_valid <= 1'b0;
        end
      end
    end
    
    // Update golden memory for writes
    if (!tr.read) begin
      for (int i = 0; i <= tr.len; i++) begin
        golden_mem.write_word(tr.addr + i*4, tr.wdata[i], tr.wmask[i]);
        $display("Golden Mem Updated: addr=0x%08h, data=0x%08h, mask=%04b", 
                tr.addr + i*4, tr.wdata[i], tr.wmask[i]);
      end
    end
  endtask
  
  // ============================================================
  // SA Response Monitor
  // ============================================================
  task automatic monitor_sa_rsp();
  bit [WIDTH-1:0] expected;
    forever begin
      @(negedge clk);
      sa_icb_rsp_ready <= 1'b1;
      
      if (sa_icb_rsp_valid && sa_icb_rsp_ready) begin
        //$display("if0");
        if (sa_cmd_queue.size() > 0) begin
          icb_transaction tr = sa_cmd_queue.pop_front();
              //   $display("if1");
          if (tr.read) begin
            tr.rdata = new[tr.len + 1];
                //  $display("if2");
            for (int i = 0; i <= tr.len; i++) begin
              //wait(sa_icb_rsp_valid);
              tr.rdata[i] = sa_icb_rsp_rdata;
              tr.err = sa_icb_rsp_err;
                  //  $display("if3");
              // Verify read data
              expected = golden_mem.read_word(tr.addr + i*4);
              if (tr.rdata[i] !== expected) begin
                $display("[ERROR] case: %d Read mismatch at 0x%08h: got=0x%08h, exp=0x%08h",
                         test_count, tr.addr + i*4, tr.rdata[i], expected);
                err_count++;
              end
             else begin
                $display("[INFO] Read match at 0x%08h: data=0x%08h",
                         tr.addr + i*4, tr.rdata[i]);
             end 
              if (i < tr.len) @(negedge clk);
            end
          end
        end
      end
    end
  endtask
  
  // ============================================================
  // M Interface Responder (Memory Model)
  // ============================================================

  always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
          m_mem.clear(); 
    end
    else  begin
      if (m_icb_cmd_valid && m_icb_cmd_ready)begin
        // Command accepted
        if (!m_icb_cmd_read)  begin
          // Write operation
          m_mem.write_word(m_icb_cmd_addr, m_icb_cmd_wdata, m_icb_cmd_wmask);
          $display("[M_MEM] Write: addr=0x%08h, data=0x%08h, mask=%04b", 
                   m_icb_cmd_addr, m_icb_cmd_wdata, m_icb_cmd_wmask);
        end
      end
    end
  end
  // logic m_icb_cmd_read_dff;//rsp晚一拍
  // always @(posedge clk or negedge rst_n) begin//rsp
  //   if(!rst_n)begin
  //     m_icb_cmd_read_dff <= 1'b1;//
  //   end
  //   else begin
  //     //if (m_icb_cmd_valid && m_icb_cmd_ready)
  //       m_icb_cmd_read_dff <= m_icb_cmd_read;
  //   end
  // end
  always @(posedge clk or negedge rst_n) begin//rsp
    if(!rst_n)begin
      m_icb_cmd_ready <= 1'b1;//TODO:add random ready
      m_icb_rsp_valid <= 1'b0;
      m_icb_rsp_rdata <= '0;
      m_icb_rsp_err <= 1'b0;
    end
    else begin
            // Command accepted
            if (m_icb_cmd_read) begin
              if (m_icb_cmd_valid && m_icb_cmd_ready)begin
                m_icb_rsp_valid <= 1'b1;//todo:多拍后返回数据，使用queue/fifo暂存，待够四拍可以往外发
                m_icb_rsp_rdata<= m_mem.read_word(m_icb_cmd_addr);
                m_icb_rsp_err <= 1'b0;
              end
              else if(m_icb_rsp_valid && m_icb_rsp_ready)begin
                m_icb_rsp_valid <= 1'b0;
                m_icb_rsp_rdata<='b0;
                m_icb_rsp_err <= 1'b0;
              end
            end else begin     // write rsp operation
              if (m_icb_cmd_valid && m_icb_cmd_ready)begin
                m_icb_rsp_valid <= 1'b1;
                m_icb_rsp_err <= 1'b0;//TODO: 注入错误
              end
              else if(m_icb_rsp_valid && m_icb_rsp_ready)begin
                m_icb_rsp_valid <= 1'b0;
                m_icb_rsp_err <= 1'b0;
              end
            end
      end
    end
  
  task automatic m_responder();
    forever begin
      @(posedge clk);
      m_icb_cmd_ready <= 1'b1;
      m_icb_rsp_valid <= 1'b0;
      
      if (m_icb_cmd_valid && m_icb_cmd_ready) begin
        // Command accepted
        if (m_icb_cmd_read) begin
          // Read operation
          @(posedge clk);
          m_icb_rsp_valid <= 1'b1;
          m_icb_rsp_rdata <= m_mem.read_word(m_icb_cmd_addr);

          m_icb_rsp_err <= 1'b0;
          wait(m_icb_rsp_ready);
          @(posedge clk);
          m_icb_rsp_valid <= 1'b0;
        end else begin
          // Write operation
          m_mem.write_word(m_icb_cmd_addr, m_icb_cmd_wdata, m_icb_cmd_wmask);
          $display("[M_MEM] Write: addr=0x%08h, data=0x%08h, mask=%04b", 
                   m_icb_cmd_addr, m_icb_cmd_wdata, m_icb_cmd_wmask);
          @(posedge clk);
          m_icb_rsp_valid <= 1'b1;
          m_icb_rsp_err <= 1'b0;
          wait(m_icb_rsp_ready);
          @(posedge clk);
          m_icb_rsp_valid <= 1'b0;
        end
      end
    end
  endtask
  
  // ============================================================
  // Test Tasks
  // ============================================================
  
  // Direct test case
  task test_direct_case(
    bit [31:0] addr,
    bit read,
    bit  [ICB_LEN_W-1:0] len,
    bit [3:0] wmask[],
    bit [31:0] data[],
    bit is_b2b = 0
  );
  
   automatic icb_transaction tr = new();
    tr.addr = addr;
    tr.read = read;
    tr.len = len;
    if (!read) begin
      tr.wdata = new[len + 1];
      tr.wmask = new[len + 1];
      foreach(data[i])
        if (i <= len) tr.wdata[i] = data[i];
      foreach(wmask[i])
        if (i <= len) tr.wmask[i] = wmask[i];
    end
    
    $display("\n[TEST %0d] Direct Case (B2B=%0d):", ++test_count, is_b2b);
    tr.display("  ");
    
    sa_cmd_queue.push_back(tr);
    drive_sa_cmd(tr, is_b2b);
  endtask
  
  // Random test case
  task test_random_case(bit is_b2b = 0);
  automatic  icb_transaction tr = new();
    
    if (!tr.randomize()) begin
  $display("[ERROR] case: %d Randomization failed!", test_count);
      err_count++;
      return;
    end
    
    // Generate random write data
    if (!tr.read) begin
      foreach(tr.wdata[i])
        tr.wdata[i] = $random();
    end
    
    $display("\n[TEST %0d] Random Case (B2B=%0d):", ++test_count, is_b2b);
    tr.display("  ");
    
    sa_cmd_queue.push_back(tr);
    drive_sa_cmd(tr, is_b2b);
  endtask
  
  // Write-then-read test
  task test_write_then_read(bit [31:0] addr, bit [31:0] data, bit [3:0] wmask, bit is_b2b = 0);
  automatic  icb_transaction wr_tr = new();
  automatic   icb_transaction rd_tr = new();
    
    // Write transaction
    wr_tr.addr = addr;
    wr_tr.read = 0;
    wr_tr.len = 0;
    wr_tr.wdata = new[1];
    wr_tr.wmask = new[1];
    wr_tr.wdata[0] = data;
    wr_tr.wmask[0] = wmask;
    
    // Read transaction
    rd_tr.addr = addr;
    rd_tr.read = 1;
    rd_tr.len = 0;
    
    $display("\n[TEST %0d] Write-then-Read at 0x%08h (B2B=%0d):", ++test_count, addr, is_b2b);
    
    sa_cmd_queue.push_back(wr_tr);
    drive_sa_cmd(wr_tr, is_b2b);
    if (!is_b2b) #100;
    
    sa_cmd_queue.push_back(rd_tr);
    drive_sa_cmd(rd_tr, is_b2b);
  endtask
  
  // B2B Burst Write-Read-Write-Read test for non-aligned len=7
  task test_b2b_burst_wrwr(bit [31:0] base_addr);
  automatic   icb_transaction wr1_tr = new();
  automatic   icb_transaction rd1_tr = new();
  automatic   icb_transaction wr2_tr = new();
  automatic   icb_transaction rd2_tr = new();
    
    // First burst write (len=7, 8 beats, non-aligned)
    wr1_tr.addr = base_addr;
    wr1_tr.read = 0;
    wr1_tr.len = 7;
    wr1_tr.wdata = new[8];
    wr1_tr.wmask = new[8];
    for (int i = 0; i < 8; i++) begin
      wr1_tr.wdata[i] = 32'h1000_0000 + (i << 8) + i;
      wr1_tr.wmask[i] = 4'b1111;
    end
    
    // First burst read (len=7, 8 beats, same address)
    rd1_tr.addr = base_addr;
    rd1_tr.read = 1;
    rd1_tr.len = 7;
    
    // Second burst write (len=7, 8 beats, different pattern)
    wr2_tr.addr = base_addr + 32'h100;
    wr2_tr.read = 0;
    wr2_tr.len = 7;
    wr2_tr.wdata = new[8];
    wr2_tr.wmask = new[8];
    for (int i = 0; i < 8; i++) begin
      wr2_tr.wdata[i] = 32'h2000_0000 + (i << 12) + (i << 4) + i;
      wr2_tr.wmask[i] = 4'b1111;
    end
    
    // Second burst read (len=7, 8 beats, same address as second write)
    rd2_tr.addr = base_addr + 32'h100;
    rd2_tr.read = 1;
    rd2_tr.len = 7;
    
    $display("\n[TEST %0d] B2B Burst WRWR at 0x%08h (len=7, non-aligned):", ++test_count, base_addr);
    
    // Execute all transactions back-to-back
    sa_cmd_queue.push_back(wr1_tr);
    drive_sa_cmd(wr1_tr, 1'b1);  // B2B write
    
    sa_cmd_queue.push_back(rd1_tr);
    drive_sa_cmd(rd1_tr, 1'b1);  // B2B read
    
    sa_cmd_queue.push_back(wr2_tr);
    drive_sa_cmd(wr2_tr, 1'b1);  // B2B write
    
    sa_cmd_queue.push_back(rd2_tr);
    drive_sa_cmd(rd2_tr, 1'b1);  // B2B read
    
    $display("[INFO] B2B Burst WRWR sequence completed");
  endtask
  
 
  
  // ============================================================
  // Main Test Sequence
  // ============================================================
  int mem_mismatches;
  initial begin
    // Initialize
    golden_mem = new("golden_mem");
    m_mem = new("m_mem");
    
    sa_icb_cmd_valid = 0;
    sa_icb_cmd_addr = 0;
    sa_icb_cmd_read = 0;
    sa_icb_cmd_wdata = 0;
    sa_icb_cmd_wmask = 0;
    sa_icb_cmd_len = 0;
    sa_icb_rsp_ready = 1;
    
    // Reset
    rst_n = 0;
    repeat(10) @(posedge clk);
    rst_n = 1;
    repeat(5) @(posedge clk);
    
    // Start background tasks
    fork
      monitor_sa_rsp();
      //m_responder();
    join_none
    
    // ========== Direct Test Cases ==========
    $display("\n========== DIRECT TEST CASES ==========");
    
    // Test 1: Aligned single write
    test_direct_case(
      .addr(32'h0000_1000),
      .read(0),
      .len(0),
      .wmask('{4'b0111}),
      .data('{32'hDEAD_BEEF}),
      .is_b2b(0)
    );
    #200;
   // compare_mem("Case 1");
    // Test 2: Aligned single read
    test_direct_case(
      .addr(32'h0000_1000),
      .read(1),
      .len(0),
      .wmask('{4'b0000}),
      .data('{}),
      .is_b2b(0)
    );
    #200;
    // Test 3: Non-aligned write (offset=1)
    test_direct_case(
      .addr(32'h0000_2001),
      .read(0),
      .len(0),
      .wmask('{4'b1101}),
      .data('{32'hCAFEBABE}),
      .is_b2b(0)
    );
    #200;
    
    //compare_mem(" Case 3");
    // Test 4: Non-aligned read (offset=1)
    test_direct_case(
      .addr(32'h0000_2001),
      .read(1),
      .len(0),
      .wmask('{4'b0000}),
      .data('{}),
      .is_b2b(0)
    );
    #200;
    
    // Test 5: Burst write (4 beats, aligned)
    test_direct_case(
      .addr(32'h0000_3000),
      .read(0),
      .len(3),
      //.wmask('{4'b1111, 4'b1111, 4'b1111, 4'b1111}),
      .wmask('{4'b0111, 4'b1011, 4'b1101, 4'b1100}),
      .data('{32'h1111_1111, 32'h2222_2222, 32'h3333_3333, 32'h4444_4444}),
      .is_b2b(0)
    );
    #400;
    
    compare_mem(" Case 5");
    // Test 6: Burst read (4 beats, aligned)
    test_direct_case(
      .addr(32'h0000_3000),
      .read(1),
      .len(3),
      .wmask('{4'b0000, 4'b0000, 4'b0000, 4'b0000}),
      .data('{}),
      .is_b2b(0)
    );
    #400;
    
    // Test 7: Burst write (3 beats, non-aligned offset=2)
    test_direct_case(
      .addr(32'h0000_4002),
      .read(0),
      .len(2),
      .wmask('{4'b1011, 4'b1111, 4'b0001}),
      .data('{32'hAAAA_AAAA, 32'hBBBB_BBBB, 32'hCCCC_CCCC}),
      .is_b2b(0)
    );
    #400;
    
    //compare_mem("Case 7");

        // Test 8: Burst write (4 beats, aligned)
    test_direct_case(
      .addr(32'h0000_3000),
      .read(0),
      .len(3),
      //.wmask('{4'b1111, 4'b1111, 4'b1111, 4'b1111}),
      .wmask('{4'b0111, 4'b1011, 4'b1101, 4'b1100}),
      .data('{32'h1111_1111, 32'h2222_2222, 32'h3333_3333, 32'h4444_4444}),
      .is_b2b(1)
    );
    #400;
    
    compare_mem(" Case 8");
    // Test 9: Burst read (4 beats, aligned)
    test_direct_case(
      .addr(32'h0000_3000),
      .read(1),
      .len(3),
      .wmask('{4'b0000, 4'b0000, 4'b0000, 4'b0000}),
      .data('{}),
      .is_b2b(1)
    );
    #400;
    
    // Test 10: Burst write (3 beats, non-aligned offset=2)
    test_direct_case(
      .addr(32'h0000_4002),
      .read(0),
      .len(4),
      .wmask('{4'b1111, 4'b1000, 4'b1111,4'b1001,4'b1011}),
      .data('{32'hAAAA_AAAA, 32'hBBBB_BBBB, 32'hCCCC_CCCC,32'hDDDD_DDDD,32'hEEEE_EEEE}),
      .is_b2b(1)
    );
    #400;
        // Test 11: Burst read (3 beats, non-aligned offset=2)
    test_direct_case(
      .addr(32'h0000_4002),
      .read(1),
      .len(4),
      .wmask('{}),
      .data('{}),
      .is_b2b(1)
    );
    #400;
    // ========== Write-then-Read Tests ==========
    $display("\n========== WRITE-THEN-READ TESTS ==========");
    

    compare_mem(" Case 11");
    // Non-aligned addresses
     // Test 12:
    test_write_then_read(32'h0000_5101, 32'h8765_4321, 4'b0111);
    #300;
 
       // Test 13:
    test_write_then_read(32'h0000_5202, 32'hFEDC_BA98, 4'b0011);
    #300;
       // Test 14:
    test_write_then_read(32'h0000_5303, 32'h89AB_CDEF, 4'b0001);
    #300;


  

    // ========== B2B Burst Tests (Non-aligned len=7) ==========
    $display("\n========== B2B BURST TESTS ==========");
    
    // B2B Test 15: offset=1
       // Test 15:
    test_b2b_burst_wrwr(32'h0000_6001);
    #1000;
    compare_mem(" Case 15");
    // B2B Test 16: offset=2  
    test_b2b_burst_wrwr(32'h0000_6102);
    #1000;
    
    // B2B Test 17: offset=3
    test_b2b_burst_wrwr(32'h0000_6203);
    #1000;
    
    // B2B Test 18: offset=1 (different base address)
    test_b2b_burst_wrwr(32'h0000_7001);
    #1000;


// ========== Write-then-Read
        // // Test 19:Aligned addresses
    test_write_then_read(32'h0000_5000, 32'h1234_5678, 4'b1111);
    #300;
    // Insert at line 868 (after B2B burst tests)
      
      // ========== Outstanding Tests ==========
    $display("\n========== OUTSTANDING TESTS ==========");
    //case20
    // Directed pattern tests
    test_outstanding_directed("WWWRRR", 32'h0000_8000, '{0});  // All transactions with len=0
    #1000;
    compare_mem("Outstanding 20 WWWRRR");
    //case21
    test_outstanding_directed("WRWWRR", 32'h0000_8100, '{1});  // All transactions with len=1
    #1000;
    compare_mem("Outstanding 21 WRWWRR");
    //case 22
    test_outstanding_directed("WWWRWRWRW", 32'h0000_8200, '{5});  // All transactions with len=5
    //test_outstanding_directed("WWWwWWWwW", 32'h0000_8200, '{0});  // All transactions with len=5
    //test_outstanding_directed("WWWwWWWrr", 32'h0000_8200, '{0});  // All transactions with len=5
    #1000;
    compare_mem("Outstanding 22 WWWRWRWRW");
    //case 23
    test_outstanding_directed("WWWWRRRR", 32'h0000_8302, '{2});  // All transactions with len=2
    #1000;
    compare_mem("Outstanding 23 WWWWRRRR");
    
    
    // // case 24 Maximum outstanding test
    // test_outstanding_max();
    // #2000;
    // compare_mem("Outstanding MAX_16");
    
    // case 24 Maximum outstanding test
    test_outstanding_directed("WWWWRRRRWWWWRRRR", 32'h0000_8403, '{3});  // All transactions with len=3
    #1000;
    compare_mem("Outstanding Maximum outstanding WWWWRRRRWWWWRRRR");

  // case 25 Overflow outstanding test
    test_outstanding_directed("WWWWRRRRWWWWRRRRWRWR", 32'h0000_8500, '{3});  // All transactions with len=3
    #1000;
   // compare_mem("Outstanding Overflow WWWWRRRRWWWWRRRRWRWR");
 // case 26 Overflow outstanding test
        //case 26
    test_outstanding_directed("WWWWRRRR", 32'h0000_8601, '{0});  // All transactions with len=0
    #1000;
    compare_mem("Outstanding 26 ");
   //test_outstanding_directed("WWWWRRRRWWWWRRRRWRWR", 32'h0000_8600, 1);
    #1000;

        //case27
    // Directed pattern tests
    test_outstanding_directed("WWWRRR", 32'h1111_8000, '{0,1,2,0,1,2});  // All transactions with len=0
    //test_outstanding_directed("WWWRRR", 32'h1111_8000, '{0,1,1,1,1,1});  // All transactions with len=0
    #1000;
    compare_mem("Outstanding 27 WWWRRR");
    //case28
    test_outstanding_directed("WRWWRR", 32'h1111_8100, '{5,4,3,2,1,0});  // All transactions with len=1
    #1000;
    compare_mem("Outstanding 28 WRWWRR");
    //case 29
    test_outstanding_directed("WWWRWRWRW", 32'h1111_8201, '{1,5,1,0,1,0,1,3,1});  // All transactions with len=5
    #10000;
    compare_mem("Outstanding 29 WWWRWRWRW");

    //case 30
    test_outstanding_directed("WWRWRWRW", 32'h1111_8203, '{1,5,10,0,13,15,1,3,1});  // All transactions with len=5
    #1000;
    compare_mem("Outstanding 30 WWWRWRWRW");

       //case 31
    test_outstanding_directed("wwwwwwww", 32'h1120_8200, '{4,3,1,0,1,0,1,3,1});  // All transactions with len=5
    #1000;
    compare_mem("Outstanding 31 WWWRWRWRW");

      //case 32
    test_outstanding_directed("RRRRrrrr", 32'h1120_8200, '{4,13,1,0,11,0,12,3,1});  // All transactions with len=5
    #1000;
    compare_mem("Outstanding 32 WWWRWRWRW");
      // // Overflow test
      //case 33
    //test_outstanding_directed("WWWWwwwwWWWWwwwwWWWWwwww", 32'h2220_0000, '{3,3,3,3, 3,3,3,3, 3,3,3,3, 3,3,3,1, 0,1,1,3,0,1,1,3});  // All transactions with len=5
    test_outstanding_directed("WWWWwwwwWWWWwwwwWWWWwwwwWWWW", 32'h0000_0001, '{3,3,3,3, 3,3,3,3, 3,3,3,3, 3,3,3,1, 0,1,1,3, 0,1,1,3 ,2,3,4,5});  // All transactions with len=5
    //test_outstanding_directed("WWWWwwwwWWWWwwwwWWWWwwwwWWWW", 32'h0000_0001, '{0});  // All transactions with len=5
    #10000;
    compare_mem("Outstanding 33 WWWRWRWRW");
      //case 34
    test_outstanding_directed("RRRRrrrrRRRRrrrrRRRRrrrr", 32'h0010_0001, '{3,3,3,3, 3,3,3,3, 3,3,3,3, 3,3,3,1, 0,1,1,3,0,1,1,3});  // All transactions with len=5
    #1000;
    compare_mem("Outstanding 34 WWWRWRWRW");
    
    //case 35
    test_outstanding_directed("WWWWWWWWWWRRRRRRRRRRWW", 32'h0020_0000, '{15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15  ,10,9});
    #2000;
    compare_mem("Outstanding 35 len=15");
    
    //case 36
    test_outstanding_directed("WWWWWWWWWWRRRRRRRRRRWW", 32'h0030_0001, '{13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13 ,10,9});
    #2000;
    compare_mem("Outstanding 36 len=13");
    
    //case 37
    test_outstanding_directed("WWWWWWWWWWRRRRRRRRRRWW", 32'h0040_0002, '{12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12 ,10,9});
    #2000;
    compare_mem("Outstanding 37 len=12");
    
    //case 38
    test_outstanding_directed("WWWWWWWWWWRRRRRRRRRRWW", 32'h0050_0003, '{7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7  ,10,9});
    #2000;
    compare_mem("Outstanding 38 len=7");


  
//同一条outstandingcase中应该w要先与r，要么就是只有r，因为tb里面是outstanding一来就先更新了golden mem了，这里还没有改成使用sa的mon来更新。
    

  
    

    // ========== Random Test Cases ==========
    $display("\n========== RANDOM TEST CASES ==========");
    repeat(100) begin
      test_random_case();
      #300;
    end
  compare_mem("none-Outstanding RANDOM");
    // Random outstanding tests
    test_outstanding_random(200);
    #5000;
    compare_mem("Outstanding RANDOM");

    // compare_mem("All Cases DONE");
    // // Final report
    // #100;
    $display("err_count=%d",err_count);
    Finish(err_count,test_count);
  end
 
  task  compare_mem(string casename);
        // ========== Memory Comparison ==========
  $display("\n========== MEMORY COMPARISON ==========");
  $display("\n========== %s ==========",casename);
  #500;  // Wait for all transactions to complete
  

  
  $display("\nComparing memories...");
  mem_mismatches = golden_mem.compare(m_mem);
  
  if (mem_mismatches > 0) begin
    //err_count += mem_mismatches;
    err_count +=1;
  $display("[ERROR] case: %d Found %0d memory mismatches! now err_count=%d", test_count, mem_mismatches,err_count);
    $display("\nGolden Memory Contents:");
    golden_mem.display_contents();
    $display("\nM Memory Contents:");
    m_mem.display_contents();

  end else begin
    $display("[PASS] All memory contents match!");
    //golden_mem.display_contents();
  end
  
  endtask //automatic
// ============================================================
// Outstanding Test Task
// ============================================================

// Task: Drive multiple outstanding transactions without waiting for responses
  task automatic test_outstanding(
    int num_trans,                    // Number of outstanding transactions
    bit read_pattern[$],              // Read/Write pattern (1=read, 0=write)
    bit [ICB_LEN_W-1:0] len_pattern[$],        // Burst length pattern
    bit [31:0] addr_pattern[$],      // Address pattern
    bit [3:0] wmask_pattern[$][$],   // Write mask pattern
    bit [31:0] wdata_pattern[$][$],  // Write data pattern
    string test_name = "Outstanding"
  );
    icb_transaction trans_queue[$];
    
    $display("\n========== [TEST %0d] %s Test: %0d Outstanding Transactions ==========", 
             ++test_count, test_name, num_trans);
             @(negedge clk);
    // Create all transactions
    for (int i = 0; i < num_trans; i++) begin
      automatic icb_transaction tr = new();
      tr.addr = addr_pattern[i];
      tr.read = read_pattern[i];
      tr.len = len_pattern[i];
      
      if (!tr.read) begin
        tr.wdata = new[tr.len + 1];
        tr.wmask = new[tr.len + 1];
        for (int j = 0; j <= tr.len; j++) begin
          tr.wdata[j] = wdata_pattern[i][j];
          tr.wmask[j] = wmask_pattern[i][j];
        end
      end
      
      trans_queue.push_back(tr);
      $display("[OUTSTANDING_%0d] %s: addr=0x%08h, len=%0d", 
               i, tr.read ? "READ" : "WRITE", tr.addr, tr.len);
    end
          fork  
            // Phase 1: Send all CMD requests back-to-back (outstanding)
            begin
            $display("[PHASE 1] Sending all %0d CMD requests...", num_trans);
            foreach (trans_queue[i]) begin
              sa_cmd_queue.push_back(trans_queue[i]);

              // Setup signals before clock edge - MUST use blocking assignment
             #1;
              sa_icb_cmd_valid = 1'b1;
              sa_icb_cmd_addr = trans_queue[i].addr;
              sa_icb_cmd_read = trans_queue[i].read;
              sa_icb_cmd_len = trans_queue[i].len;
              $display("[CMD_SETUP_%0d] addr=0x%08h, time=%0t (before clk)", i, trans_queue[i].addr, $time);
              $display("[CMD_AFTER_CLK_%0d] time=%0t (same time, reactive region)", i, $time);
              wait(sa_icb_cmd_ready);
              @(posedge clk);
              $display("[CMD_HANDSHAKE_%0d] addr=0x%08h, time=%0t", i, trans_queue[i].addr, $time);
            end
            #1;
            sa_icb_cmd_valid = 1'b0;
            @(posedge clk);
          end

          begin
          // Phase 2: Send all write data for write transactions
          $display("[PHASE 2] Sending write data...");
          foreach (trans_queue[i]) begin
            if (!trans_queue[i].read) begin
              // Update golden memory for writes
              for (int k = 0; k <= trans_queue[i].len; k++) begin
                golden_mem.write_word(trans_queue[i].addr + k*4, trans_queue[i].wdata[k], trans_queue[i].wmask[k]);
                $display("Golden Mem Updated: addr=0x%08h, data=0x%08h, mask=%04b", 
                        trans_queue[i].addr + k*4, trans_queue[i].wdata[k], trans_queue[i].wmask[k]);
              end
              
              // Send write data beats
              for (int j = 0; j <= trans_queue[i].len; j++) begin
                @(posedge clk);
                #1;
                sa_icb_w_valid = 1'b1;
                sa_icb_cmd_wdata = trans_queue[i].wdata[j];
                sa_icb_cmd_wmask = trans_queue[i].wmask[j];
              
                wait(sa_icb_w_ready);
                $display("[WDATA_SENT_outstanding%0d.%0d] data=0x%08h, mask=%04b", i, j, trans_queue[i].wdata[j], trans_queue[i].wmask[j]);

              end
            end
          end
          @(posedge clk);
          sa_icb_w_valid = 1'b0;
          
        end
      join
    $display("[INFO] All %0d outstanding transactions sent (CMD + WDATA)", num_trans);
  endtask
  
  // Task: Directed outstanding test with specific read/write pattern
  task automatic test_outstanding_directed(
    string pattern,           // e.g., "WWWRRR", "WRWWRR"
    bit [31:0] base_addr,
    bit [ICB_LEN_W-1:0] burst_len_queue[$] = '{0}  // Queue of burst lengths for each transaction
  );
    int num_trans = pattern.len();
    bit read_pattern[$];
    bit [ICB_LEN_W-1:0] len_pattern[$];
    bit [31:0] addr_pattern[$];
    bit [3:0] wmask_pattern[$][$];
    bit [31:0] wdata_pattern[$][$];
    int read_count=0 ;
    int write_count=0;
    bit [31:0] addr;
    bit  [ICB_LEN_W-1:0] current_len;
    
    // If burst_len_queue has only one element, use it for all transactions
    bit single_len_mode = (burst_len_queue.size() == 1);
    string len_queue_str = "{";
    
    // Build burst_len_queue display string
    for (int k = 0; k < burst_len_queue.size(); k++) begin
      len_queue_str = {len_queue_str, $sformatf("%0d", burst_len_queue[k])};
      if (k < burst_len_queue.size() - 1) 
        len_queue_str = {len_queue_str, ", "};
    end
    len_queue_str = {len_queue_str, "}"};
    
    $display("\n[DIRECTED OUTSTANDING] Pattern: %s, Base: 0x%08h, Len Queue: %s (Size: %0d)", 
             pattern, base_addr, len_queue_str, burst_len_queue.size());

    // Parse pattern and generate transactions
    for (int i = 0; i < num_trans; i++) begin
      bit is_read = (pattern[i] == "R" || pattern[i] == "r");
      
      // Get burst length for this transaction
      if (single_len_mode) begin
        current_len = burst_len_queue[0];
      end else if (i < burst_len_queue.size()) begin
        current_len = burst_len_queue[i];
      end else begin
        current_len = 0;  // Default to 0 if not enough lengths provided
        $display("[WARNING] Not enough burst lengths provided, using default 0 for transaction %0d", i);
      end
      
      //bit [31:0] addr = is_read?  (base_addr + (read_count++ * 32) ) : (base_addr + (write_count++ * 32) ) ; // Offset each transaction
      if(is_read)
        addr = base_addr + (read_count++ * 32) ;
      else
        addr = base_addr + (write_count++ * 32) ;
      //bit [31:0] addr = is_read?  (base_addr + (read_count++ * 32) ) : (base_addr + (write_count++ * 32) ) ; // Offset each transaction
      
      read_pattern.push_back(is_read);
      len_pattern.push_back(current_len);
      addr_pattern.push_back(addr);
      
      if (!is_read) begin
        bit [3:0] wmask_temp[$];
        bit [31:0] wdata_temp[$];
        
        for (int j = 0; j <= current_len; j++) begin
          wmask_temp.push_back(4'b1111);
          wdata_temp.push_back(32'h10000000 + (i << 16) + (j << 8) + i);
        end
        
        wmask_pattern.push_back(wmask_temp);
        wdata_pattern.push_back(wdata_temp);
      end else begin
        bit [3:0] wmask_temp[$];
        bit [31:0] wdata_temp[$];
        wmask_pattern.push_back(wmask_temp);
        wdata_pattern.push_back(wdata_temp);
      end
    end
    
    test_outstanding(num_trans, read_pattern, len_pattern, addr_pattern, 
                     wmask_pattern, wdata_pattern, pattern);
  endtask
  // Task: Random outstanding test
  task automatic test_outstanding_random(int iterations = 100);
    $display("\n========== RANDOM OUTSTANDING TESTS (iterations=%0d) ==========", iterations);
    
    for (int iter = 0; iter < iterations; iter++) begin
      int num_trans ;//= $urandom_range(1, 16);  // 1 to 16 outstanding
      bit read_pattern[$];
      bit [ICB_LEN_W-1:0] len_pattern[$];
      bit [31:0] addr_pattern[$];
      bit [3:0] wmask_pattern[$][$];
      bit [31:0] wdata_pattern[$][$];
      bit [31:0] base_addr = 32'h0003_0000 + (iter * 32'h1000);
      
      int num_trans_rand = $urandom_range(0, 99);  // 生成 0-99 的随机数用于百分比判断
      int write_count = 0;
      int read_count = 0;

      if (num_trans_rand < 50) begin
        // 80% 概率: num_trans = 0-3
        num_trans = $urandom_range(0, 3);
      end else if (num_trans_rand < 70) begin
        // 15% 概率: num_trans = 4-7 (代表 4-19 范围，但受限于 3-bit 最大值 7)
          num_trans =$urandom_range(4, 19);
      end else begin
        // 5% 概率: num_trans = 7 (代表 20-30 范围，但受限于 3-bit 最大值 7)
          num_trans= $urandom_range(20, 30);
      end
      // Generate transactions ensuring W count >= R count at any point
      for (int i = 0; i < num_trans; i++) begin
        bit is_read;
        bit [ICB_LEN_W-1:0] len = $urandom_range(0, 2**ICB_LEN_W-1);  // Burst length 0-3
        bit [1:0] align = $urandom_range(0, 3); // Alignment offset 0-3
        bit [31:0] addr = base_addr + (i * 64) + align;
        
        // Decide read/write: ensure write_count >= read_count at all times
        if (write_count <= read_count) begin
          // Must write to keep write_count >= read_count
          is_read = 0;
        end else begin
          // Can choose randomly, but prefer write
          // 70% write, 30% read when we have buffer
          int rand_val = $urandom_range(0, 99);
          is_read = (rand_val < 30) ? 1 : 0;
        end
        
        if (is_read) begin
          read_count++;
        end else begin
          write_count++;
        end
        
        read_pattern.push_back(is_read);
        len_pattern.push_back(len);
        addr_pattern.push_back(addr);
        
        if (!is_read) begin
          bit [3:0] wmask_temp[$];
          bit [31:0] wdata_temp[$];
          
          for (int j = 0; j <= len; j++) begin
            wmask_temp.push_back($urandom_range(1, 15)); // Random mask (non-zero)
            wdata_temp.push_back($urandom());
          end
          
          wmask_pattern.push_back(wmask_temp);
          wdata_pattern.push_back(wdata_temp);
        end else begin
          bit [3:0] wmask_temp[$];
          bit [31:0] wdata_temp[$];
          wmask_pattern.push_back(wmask_temp);
          wdata_pattern.push_back(wdata_temp);
        end
      end
      
      // Display statistics
      $display("[RANDOM_%0d] Generated %0d transactions: %0d writes, %0d reads (W >= R guaranteed)", 
               iter, num_trans, write_count, read_count);
      
      test_outstanding(num_trans, read_pattern, len_pattern, addr_pattern, 
                       wmask_pattern, wdata_pattern, $sformatf("RANDOM_%0d", iter));
      
      #1000; // Wait between random iterations
      compare_mem($sformatf("testcount_%0d  RANDOM_%0d",test_count, iter));
    end
    
    $display("[INFO] Completed %0d random outstanding test iterations", iterations);
  endtask
  // ============================================================
  // Timeout
  // ============================================================
  initial begin
    $display(" **********start simulation*******");
    #1000_000;
    $display("[TIMEOUT] Test timed out!");
    err_count++;
    Finish(err_count,test_count);
  end

endmodule