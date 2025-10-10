  // Task: Maximum outstanding test (16 transactions)
  task automatic test_outstanding_max();
  int num_trans = 16;
  bit read_pattern[$];
  bit [2:0] len_pattern[$];
  bit [31:0] addr_pattern[$];
  bit [3:0] wmask_pattern[$][$];
  bit [31:0] wdata_pattern[$][$];
  bit [31:0] base_addr = 32'h0001_0000;
  
  $display("\n[MAX OUTSTANDING] Testing maximum 16 outstanding transactions");
  
  for (int i = 0; i < num_trans; i++) begin
    bit is_read = (i % 2 == 0);  // Alternate read/write
    bit [2:0] len = i % 4;        // Vary burst length 0-3
    bit [31:0] addr = base_addr + (i * 64);
    
    read_pattern.push_back(is_read);
    len_pattern.push_back(len);
    addr_pattern.push_back(addr);
    
    if (!is_read) begin
      bit [3:0] wmask_temp[$];
      bit [31:0] wdata_temp[$];
      
      for (int j = 0; j <= len; j++) begin
        wmask_temp.push_back(4'b1111);
        wdata_temp.push_back(32'h20000000 + (i << 16) + (j << 8));
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
                   wmask_pattern, wdata_pattern, "MAX_16");
endtask

// Task: Overflow test (17 transactions - exceeds FIFO depth)
task automatic test_outstanding_overflow();
  int num_trans = 17;
  bit read_pattern[$];
  bit [2:0] len_pattern[$];
  bit [31:0] addr_pattern[$];
  bit [3:0] wmask_pattern[$][$];
  bit [31:0] wdata_pattern[$][$];
  bit [31:0] base_addr = 32'h0002_0000;
  
  $display("\n[OVERFLOW TEST] Testing 17 outstanding transactions (exceeds depth 16)");
  
  for (int i = 0; i < num_trans; i++) begin
    bit is_read = (i % 3 != 0);  // Mix of read/write
    bit [2:0] len = (i % 2 == 0) ? 0 : 1;
    bit [31:0] addr = base_addr + (i * 32);
    
    read_pattern.push_back(is_read);
    len_pattern.push_back(len);
    addr_pattern.push_back(addr);
    
    if (!is_read) begin
      bit [3:0] wmask_temp[$];
      bit [31:0] wdata_temp[$];
      
      for (int j = 0; j <= len; j++) begin
        wmask_temp.push_back(4'b1111);
        wdata_temp.push_back(32'h30000000 + (i << 16) + j);
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
                   wmask_pattern, wdata_pattern, "OVERFLOW_17");
endtask