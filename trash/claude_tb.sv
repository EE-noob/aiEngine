// ============================================================
// ICB Unalign Bridge Testbench with Self-Checking Platform
// ============================================================

`timescale 1ns/1ps

// ============================================================
// Transaction Class Definition
// ============================================================
class icb_transaction;//>>>
  // Fields
  rand bit [31:0] addr;
  rand bit        read;        // 1=read, 0=write
  rand bit [2:0]  len;         // actual beats = len + 1
  rand bit [31:0] wdata[];     // write data array
  rand bit [3:0]  wmask;       // write mask
  
  // Response fields
  bit [31:0] rdata[];           // read data array
  bit        err;               // error flag
  
  // Constraints
  constraint c_len_range { 
    len inside {[0:7]}; 
  }
  
  constraint c_wdata_size {
    if (read) 
      wdata.size() == 0;
    else      
      wdata.size() == (len + 1);
  }
  
  constraint c_wmask_non_zero {
    if (!read) 
      wmask != 4'b0000;
  }
  
  // Soft constraint for various alignments
  constraint c_addr_align { 
    soft addr[1:0] inside {2'b00, 2'b01, 2'b10, 2'b11}; 
  }
  
  // Constructor
  function new(string name="icb_transaction");
  endfunction
  
  // Display function
  function void display(string prefix="");
    $display("%s[%0t] %s Transaction:", prefix, $time, read ? "READ" : "WRITE");
    $display("%s  addr=0x%08h, len=%0d (beats=%0d), wmask=%04b", 
             prefix, addr, len, len+1, wmask);
    if (!read) begin
      foreach (wdata[i])
        $display("%s  wdata[%0d]=0x%08h", prefix, i, wdata[i]);
    end else if (rdata.size() > 0) begin
      foreach (rdata[i])
        $display("%s  rdata[%0d]=0x%08h", prefix, i, rdata[i]);
    end
  endfunction
  
  // Copy function
  function icb_transaction copy();
    icb_transaction tr = new();
    tr.addr = this.addr;
    tr.read = this.read;
    tr.len = this.len;
    tr.wmask = this.wmask;
    tr.wdata = new[this.wdata.size()];
    foreach(this.wdata[i])
      tr.wdata[i] = this.wdata[i];
    return tr;
  endfunction
endclass
//<<<
// ============================================================
// Memory Model Class
// ============================================================
class memory_model #(parameter ADDR_W=32, DATA_W=32);//>>>
  bit [7:0] mem[bit[ADDR_W-1:0]];  // Sparse memory array
  string name;
  
  function new(string n="memory");
    name = n;
  endfunction
  
  // Write byte
  function void write_byte(bit [ADDR_W-1:0] addr, bit [7:0] data);
    mem[addr] = data;
    `ifdef DEBUG_MEM
    $display("[%s] Write: addr=0x%08h, data=0x%02h", name, addr, data);
    `endif
  endfunction
  
  // Read byte
  function bit [7:0] read_byte(bit [ADDR_W-1:0] addr);
    if (!mem.exists(addr)) begin
      mem[addr] = 8'hxx;  // Uninitialized memory
    end
    `ifdef DEBUG_MEM
    $display("[%s] Read: addr=0x%08h, data=0x%02h", name, addr, mem[addr]);
    `endif
    return mem[addr];
  endfunction
  
  // Write word with mask
  function void write_word(bit [ADDR_W-1:0] addr, bit [DATA_W-1:0] data, bit [DATA_W/8-1:0] mask);
    for (int i = 0; i < DATA_W/8; i++) begin
      if (mask[i]) begin
        write_byte(addr + i, data[i*8 +: 8]);
      end
    end
  endfunction
  
  // Read word
  function bit [DATA_W-1:0] read_word(bit [ADDR_W-1:0] addr);
    bit [DATA_W-1:0] data;
    for (int i = 0; i < DATA_W/8; i++) begin
      data[i*8 +: 8] = read_byte(addr + i);
    end
    return data;
  endfunction
  
  // Compare with another memory
  function int compare(memory_model #(ADDR_W, DATA_W) other);
    int mismatches = 0;
    bit [ADDR_W-1:0] addr_list[$];
    
    // Collect all addresses from both memories
    foreach(this.mem[addr])
      if (!(addr inside {addr_list}))
        addr_list.push_back(addr);
    
    foreach(other.mem[addr])
      if (!(addr inside {addr_list}))
        addr_list.push_back(addr);
    
    // Compare each address
    foreach(addr_list[i]) begin
      bit [7:0] data1, data2;
      data1 = this.mem.exists(addr_list[i]) ? this.mem[addr_list[i]] : 8'hxx;
      data2 = other.mem.exists(addr_list[i]) ? other.mem[addr_list[i]] : 8'hxx;
      
      if (data1 !== data2 && data1 !== 8'hxx && data2 !== 8'hxx) begin
        $display("[MEM_COMPARE] Mismatch at 0x%08h: %s=0x%02h, %s=0x%02h", 
                 addr_list[i], this.name, data1, other.name, data2);
        mismatches++;
      end
    end
    
    return mismatches;
  endfunction
  
  // Clear memory
  function void clear();
    mem.delete();
  endfunction
  
  // Display memory contents
  function void display_contents();
    bit [ADDR_W-1:0] addr_list[$];
    
    foreach(mem[addr])
      addr_list.push_back(addr);
    
    addr_list.sort();
    
    $display("[%s] Memory Contents:", name);
    foreach(addr_list[i]) begin
      $display("  0x%08h: 0x%02h", addr_list[i], mem[addr_list[i]]);
    end
  endfunction
endclass
//<<<


// ============================================================
// Main Testbench Module
// ============================================================
module tb_icb_unalign_bridge;
  
  // Parameters
  localparam WIDTH = 32;
  localparam ADDR_W = 32;
  localparam OUTS_DEPTH = 16;
  localparam ICB_LEN_W = 3;
  localparam DW = WIDTH/8;
  
  // Clock and Reset
  logic clk;
  logic rst_n;
  
  // SA (upstream) ICB interface
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
    .sa_icb_cmd_wdata   (sa_icb_cmd_wdata),
    .sa_icb_cmd_wmask   (sa_icb_cmd_wmask),
    .sa_icb_cmd_len     (sa_icb_cmd_len),
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
  // Clock Generation
  // ============================================================
  initial begin
    clk = 0;
    
    // sa_icb_rsp_rdata='b0;
    // sa_icb_rsp_err='b0;
    
    // m_icb_cmd_ready='b0;
    // m_icb_cmd_addr='b0;
    // m_icb_cmd_read=0;

    // m_icb_rsp_valid='b0;
    // m_icb_rsp_err='b0;


    forever #5 clk = ~clk;
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
  task automatic drive_sa_cmd(icb_transaction tr);
    int beat_cnt = 0;
    
    // Drive command
    @(posedge clk);
    sa_icb_cmd_valid <= 1'b1;
    sa_icb_cmd_addr <= tr.addr;
    sa_icb_cmd_read <= tr.read;
    sa_icb_cmd_len <= tr.len;
    sa_icb_cmd_wmask <= tr.wmask;
    
    // Drive write data beats
    if (!tr.read) begin
      foreach(tr.wdata[i]) begin
        sa_icb_cmd_wdata <= tr.wdata[i];
        if (i == 0) begin
          wait(sa_icb_cmd_ready);
          @(posedge clk);
          sa_icb_cmd_valid <= 1'b0;  // Only first beat needs valid
        end else begin
          @(posedge clk);
        end
      end
    end else begin
      wait(sa_icb_cmd_ready);
      @(posedge clk);
      sa_icb_cmd_valid <= 1'b0;
    end
    
    // Update golden memory for writes
    if (!tr.read) begin
      for (int i = 0; i <= tr.len; i++) begin
        golden_mem.write_word(tr.addr + i*4, tr.wdata[i], tr.wmask);
      end
    end
  endtask
  
  // ============================================================
  // SA Response Monitor
  // ============================================================
  task automatic monitor_sa_rsp();
  bit [WIDTH-1:0] expected;
    forever begin
      @(posedge clk);
      sa_icb_rsp_ready <= 1'b1;
      
      if (sa_icb_rsp_valid && sa_icb_rsp_ready) begin
        if (sa_cmd_queue.size() > 0) begin
          icb_transaction tr = sa_cmd_queue.pop_front();
          
          if (tr.read) begin
            tr.rdata = new[tr.len + 1];
            for (int i = 0; i <= tr.len; i++) begin
              wait(sa_icb_rsp_valid);
              tr.rdata[i] = sa_icb_rsp_rdata;
              tr.err = sa_icb_rsp_err;
              
              // Verify read data
              expected = golden_mem.read_word(tr.addr + i*4);
              if (tr.rdata[i] !== expected) begin
                $display("[ERROR] Read mismatch at 0x%08h: got=0x%08h, exp=0x%08h",
                         tr.addr + i*4, tr.rdata[i], expected);
                err_count++;
              end
              
              if (i < tr.len) @(posedge clk);
            end
          end
        end
      end
    end
  endtask
  
  // ============================================================
  // M Interface Responder (Memory Model)
  // ============================================================
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
    bit [2:0] len,
    bit [3:0] wmask,
    bit [31:0] data[]
  );
  
    icb_transaction tr = new();
    tr.addr = addr;
    tr.read = read;
    tr.len = len;
    tr.wmask = wmask;
    if (!read) begin
      tr.wdata = new[len + 1];
      foreach(data[i])
        if (i <= len) tr.wdata[i] = data[i];
    end
    
    $display("\n[TEST %0d] Direct Case:", test_count++);
    tr.display("  ");
    
    sa_cmd_queue.push_back(tr);
    drive_sa_cmd(tr);
  endtask
  
  // Random test case
  task test_random_case();
    icb_transaction tr = new();
    
    if (!tr.randomize()) begin
      $display("[ERROR] Randomization failed!");
      err_count++;
      return;
    end
    
    // Generate random write data
    if (!tr.read) begin
      foreach(tr.wdata[i])
        tr.wdata[i] = $random();
    end
    
    $display("\n[TEST %0d] Random Case:", test_count++);
    tr.display("  ");
    
    sa_cmd_queue.push_back(tr);
    drive_sa_cmd(tr);
  endtask
  
  // Write-then-read test
  task test_write_then_read(bit [31:0] addr, bit [31:0] data, bit [3:0] wmask);
    icb_transaction wr_tr = new();
    icb_transaction rd_tr = new();
    
    // Write transaction
    wr_tr.addr = addr;
    wr_tr.read = 0;
    wr_tr.len = 0;
    wr_tr.wmask = wmask;
    wr_tr.wdata = new[1];
    wr_tr.wdata[0] = data;
    
    // Read transaction
    rd_tr.addr = addr;
    rd_tr.read = 1;
    rd_tr.len = 0;
    
    $display("\n[TEST %0d] Write-then-Read at 0x%08h:", test_count++, addr);
    
    sa_cmd_queue.push_back(wr_tr);
    drive_sa_cmd(wr_tr);
    #100;
    
    sa_cmd_queue.push_back(rd_tr);
    drive_sa_cmd(rd_tr);
  endtask
  
  // ============================================================
  // Result Display Task
  // ============================================================
  task Finish();
    static string GREEN = "\033[1;32m";
    static string RED = "\033[1;31m";
    static string NC = "\033[0m";
    static string PASS_ASCII[$] = '{
      "██████╗  █████╗ ███████╗███████╗",
      "██╔══██╗██╔══██╗██╔════╝██╔════╝",
      "██████╔╝███████║███████╗███████╗",
      "██╔═══╝ ██╔══██║╚════██║╚════██║",
      "██║     ██║  ██║███████║███████║",
      "╚═╝     ╚═╝  ╚═╝╚══════╝╚══════╝"
    };
    static string FAIL_ASCII[$] = '{
      "███████╗ █████╗ ██╗██╗     ",
      "██╔════╝██╔══██╗██║██║     ",
      "█████╗  ███████║██║██║     ",
      "██╔══╝  ██╔══██║██║██║     ",
      "██║     ██║  ██║██║███████╗",
      "╚═╝     ╚═╝  ╚═╝╚═╝╚══════╝"
    };
    
    $display("\n////////////////////////////////////////////////////////////////////////////");
    $display("%0t: Simulation ended, ERROR count: %0d", $time, err_count);
    $display("////////////////////////////////////////////////////////////////////////////\n");
    
    if (err_count == 0) begin
      foreach (PASS_ASCII[i])
        $display("%s%s%s", GREEN, PASS_ASCII[i], NC);
    end else begin
      foreach (FAIL_ASCII[i])
        $display("%s%s%s", RED, FAIL_ASCII[i], NC);
    end
    
    $finish;
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
      m_responder();
    join_none
    
    // ========== Direct Test Cases ==========
    $display("\n========== DIRECT TEST CASES ==========");
    
    // Test 1: Aligned single write
    test_direct_case(
      .addr(32'h0000_1000),
      .read(0),
      .len(0),
      .wmask(4'b1111),
      .data('{32'hDEAD_BEEF})
    );
    #200;
    
    // Test 2: Aligned single read
    test_direct_case(
      .addr(32'h0000_1000),
      .read(1),
      .len(0),
      .wmask(4'b0000),
      .data('{}
    ));
    #200;
    
    // Test 3: Non-aligned write (offset=1)
    test_direct_case(
      .addr(32'h0000_2001),
      .read(0),
      .len(0),
      .wmask(4'b0111),
      .data('{32'hCAFEBABE})
    );
    #200;
    
    // Test 4: Non-aligned read (offset=1)
    test_direct_case(
      .addr(32'h0000_2001),
      .read(1),
      .len(0),
      .wmask(4'b0000),
      .data('{}
    ));
    #200;
    
    // Test 5: Burst write (4 beats, aligned)
    test_direct_case(
      .addr(32'h0000_3000),
      .read(0),
      .len(3),
      .wmask(4'b1111),
      .data('{32'h1111_1111, 32'h2222_2222, 32'h3333_3333, 32'h4444_4444})
    );
    #400;
    
    // Test 6: Burst read (4 beats, aligned)
    test_direct_case(
      .addr(32'h0000_3000),
      .read(1),
      .len(3),
      .wmask(4'b0000),
      .data('{}
    ));
    #400;
    
    // Test 7: Burst write (3 beats, non-aligned offset=2)
    test_direct_case(
      .addr(32'h0000_4002),
      .read(0),
      .len(2),
      .wmask(4'b0011),
      .data('{32'hAAAA_AAAA, 32'hBBBB_BBBB, 32'hCCCC_CCCC})
    );
    #400;
    
    // ========== Random Test Cases ==========
    $display("\n========== RANDOM TEST CASES ==========");
    
    repeat(10) begin
      test_random_case();
      #300;
    end
    
    // ========== Write-then-Read Tests ==========
    $display("\n========== WRITE-THEN-READ TESTS ==========");
    
    // Aligned addresses
    test_write_then_read(32'h0000_5000, 32'h1234_5678, 4'b1111);
    #300;
    
    // Non-aligned addresses
    test_write_then_read(32'h0000_5101, 32'h8765_4321, 4'b0111);
    #300;
    test_write_then_read(32'h0000_5202, 32'hFEDC_BA98, 4'b0011);
    #300;
    test_write_then_read(32'h0000_5303, 32'h89AB_CDEF, 4'b0001);
    #300;
    
    // ========== Memory Comparison ==========
    $display("\n========== MEMORY COMPARISON ==========");
    #500;  // Wait for all transactions to complete
    
    $display("\nGolden Memory Contents:");
    golden_mem.display_contents();
    
    $display("\nM Memory Contents:");
    m_mem.display_contents();
    
    $display("\nComparing memories...");
    mem_mismatches = golden_mem.compare(m_mem);
    
    if (mem_mismatches > 0) begin
      $display("[ERROR] Found %0d memory mismatches!", mem_mismatches);
      err_count += mem_mismatches;
    end else begin
      $display("[PASS] All memory contents match!");
    end
    
    // Final report
    #100;
    Finish();
  end
  
  // ============================================================
  // Timeout
  // ============================================================
  initial begin
    #100000;
    $display("[TIMEOUT] Test timed out!");
    err_count++;
    Finish();
  end

endmodule