// Task: Random outstanding test
  task automatic test_outstanding_random_old(int iterations = 100);
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
    if(iter&1)
    begin
      golden_mem.clear();
      m_mem.clear();
    end
    
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