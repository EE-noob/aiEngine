// ============================================================
// IA Loader Transaction Class
// ============================================================
class ia_transaction;
    // 矩阵维度参数
    rand int k;              // 输入激活矩阵行数
    rand int n;              // 输入激活矩阵列数  
    rand int m;              // 输出矩阵列数
    rand bit use_16bits;     // 数据类型：1=s16, 0=s8
    
    // 内存配置
    rand int base_addr;      // 基地址
    int row_stride;          // 行步长（字节）- 派生参数
    
    // 矩阵数据（动态数组）
    logic signed [15:0] ia_matrix[][];
    
    // 数据生成模式
    rand bit random_data;    // 1=随机数据, 0=有规律数据
    
    // =========================================================================
    // 约束条件
    // =========================================================================
    
    // 基本维度约束
    constraint dim_range {
        k inside {[1:128]};
        n inside {[1:128]};
        m inside {[1:128]};
    }
    
    // 地址对齐约束
    constraint addr_align {
        base_addr[11:0] == 12'h000;  // 4KB对齐
        base_addr inside {[32'h0000_1000:32'h0001_0000]};
    }
    
    // 数据类型分布
    constraint data_type_dist {
        use_16bits dist {0 := 50, 1 := 50};  // 50% s8, 50% s16
    }
    
    // 数据模式分布
    constraint data_mode_dist {
        random_data dist {0 := 30, 1 := 70};  // 30%有规律, 70%随机
    }
    
    // =========================================================================
    // 构造函数
    // =========================================================================
    function new();
        k = 16;
        n = 16;
        m = 16;
        use_16bits = 1;
        base_addr = 32'h0000_1000;
        row_stride = 0;
        random_data = 0;
    endfunction
    
    // =========================================================================
    // 后随机化：计算派生参数和生成矩阵数据
    // =========================================================================
    function void post_randomize();
        // 计算行步长（向上对齐到4字节边界）
        if (use_16bits) begin
            row_stride = ((n * 2 + 3) / 4) * 4;
        end else begin
            row_stride = ((n + 3) / 4) * 4;
        end
        
        // 生成矩阵数据
        generate_matrix();
    endfunction
    
    // =========================================================================
    // 生成矩阵数据
    // =========================================================================
    function void generate_matrix();
        ia_matrix = new[k];
        for (int i = 0; i < k; i++) begin
            ia_matrix[i] = new[n];
            for (int j = 0; j < n; j++) begin
                if (random_data) begin
                    // 随机数据
                    ia_matrix[i][j] = $random & 16'hFFFF;
                end else begin
                    // 有规律数据（便于调试）
                    if (use_16bits) begin
                        // 高字节=行号，低字节=列号
                        ia_matrix[i][j] = {i[7:0], j[7:0]};
                    end else begin
                        // 8位：线性递增
                        ia_matrix[i][j] = (i * n + j) & 16'h00FF;
                    end
                end
            end
        end
    endfunction
    
    // =========================================================================
    // 加载数据到内存模型
    // =========================================================================
    function void load_to_memory(memory_model #(32, 32) mem);
        int addr;
        $display("[IA_TRANSACTION] Loading matrix to memory:");
        $display("  k=%0d, n=%0d, m=%0d, base=0x%08h, stride=%0d, 16bit=%0b",
                 k, n, m, base_addr, row_stride, use_16bits);
        
        for (int i = 0; i < k; i++) begin
            addr = base_addr + i * row_stride;
            for (int j = 0; j < n; j++) begin
                if (use_16bits) begin
                    mem.write_halfword(addr + j*2, ia_matrix[i][j]);
                end else begin
                    mem.write_byte(addr + j, ia_matrix[i][j][7:0]);
                end
            end
        end
    endfunction
    
    // =========================================================================
    // 显示事务信息
    // =========================================================================
    function void display(string prefix = "");
        $display("%sIA Transaction:", prefix);
        $display("%s  Matrix: [%0d x %0d], Output cols: %0d", prefix, k, n, m);
        $display("%s  Data type: %s, Mode: %s", prefix, 
                 use_16bits ? "s16" : "s8",
                 random_data ? "random" : "regular");
        $display("%s  Base addr: 0x%08h, Stride: %0d bytes", prefix, base_addr, row_stride);
        
        // 显示部分数据（前3x3）
        if (k > 0 && n > 0) begin
            $display("%s  Matrix preview (first 3x3):", prefix);
            for (int i = 0; i < (k < 3 ? k : 3); i++) begin
                $write("%s    Row[%0d]: ", prefix, i);
                for (int j = 0; j < (n < 3 ? n : 3); j++) begin
                    $write("0x%04h ", ia_matrix[i][j]);
                end
                $display("");
            end
        end
    endfunction
    
    // =========================================================================
    // 深拷贝
    // =========================================================================
    function ia_transaction copy();
        ia_transaction tr = new();
        tr.k = this.k;
        tr.n = this.n;
        tr.m = this.m;
        tr.use_16bits = this.use_16bits;
        tr.base_addr = this.base_addr;
        tr.row_stride = this.row_stride;
        tr.random_data = this.random_data;
        
        // 深拷贝矩阵
        tr.ia_matrix = new[this.k];
        for (int i = 0; i < this.k; i++) begin
            tr.ia_matrix[i] = new[this.n];
            for (int j = 0; j < this.n; j++) begin
                tr.ia_matrix[i][j] = this.ia_matrix[i][j];
            end
        end
        
        return tr;
    endfunction
    
    // =========================================================================
    // 比较函数
    // =========================================================================
    function bit compare(ia_transaction tr);
        if (this.k != tr.k || this.n != tr.n || this.m != tr.m) return 0;
        if (this.use_16bits != tr.use_16bits) return 0;
        if (this.base_addr != tr.base_addr) return 0;
        
        for (int i = 0; i < k; i++) begin
            for (int j = 0; j < n; j++) begin
                if (this.ia_matrix[i][j] !== tr.ia_matrix[i][j]) return 0;
            end
        end
        
        return 1;
    endfunction
    
endclass
