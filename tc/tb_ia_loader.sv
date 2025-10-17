/*
 * ia_loader testbench
 * 连接ia_loader、icb_unalign和memory_model
 * 包含定向和随机测试用例
 */

`timescale 1ns/1ps

`include "../include/define.svh"
`include "../include/icb_types.svh"
`include "../include/memory_model.sv"
`include "../include/Finish_task.sv"

module tb_ia_loader;

    // =========================================================================
    // 参数定义
    // =========================================================================
    parameter int DATA_WIDTH = 16;
    parameter int SIZE = 16;
    parameter int REG_WIDTH = 32;
    parameter int BUS_WIDTH = 32;
    parameter int ADDR_WIDTH = 32;

    // =========================================================================
    // 时钟和复位
    // =========================================================================
    logic clk;
    logic rst_n;

    // 时钟生成
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz
    end

    // 复位生成
    initial begin
        rst_n = 0;
        repeat(10) @(posedge clk);
        rst_n = 1;
    end

    // =========================================================================
    // Interface实例化
    // =========================================================================
    ia_loader_if #(
        .DATA_WIDTH(DATA_WIDTH),
        .SIZE(SIZE),
        .REG_WIDTH(REG_WIDTH)
    ) ia_if (
        .clk(clk),
        .rst_n(rst_n)
    );

    // ICB信号定义（不使用interface，直接连线）
    // SA端（ia_loader master端）
    logic                   sa_icb_cmd_valid;
    logic                   sa_icb_cmd_ready;
    logic [ADDR_WIDTH-1:0]  sa_icb_cmd_addr;
    logic                   sa_icb_cmd_read;
    logic [3:0]             sa_icb_cmd_len;
    logic                   sa_icb_rsp_valid;
    logic                   sa_icb_rsp_ready;
    logic [BUS_WIDTH-1:0]   sa_icb_rsp_rdata;
    logic                   sa_icb_rsp_err;

    // M端（连接memory）
    logic                   m_icb_cmd_valid;
    logic                   m_icb_cmd_ready;
    logic [ADDR_WIDTH-1:0]  m_icb_cmd_addr;
    logic                   m_icb_cmd_read;
    logic [BUS_WIDTH-1:0]   m_icb_cmd_wdata;
    logic [3:0]             m_icb_cmd_wmask;
    logic                   m_icb_rsp_valid;
    logic                   m_icb_rsp_ready;
    logic [BUS_WIDTH-1:0]   m_icb_rsp_rdata;
    logic                   m_icb_rsp_err;

    // =========================================================================
    // DUT实例化
    // =========================================================================
    ia_loader #(
        .DATA_WIDTH(DATA_WIDTH),
        .SIZE(SIZE),
        .BUS_WIDTH(BUS_WIDTH),
        .REG_WIDTH(REG_WIDTH)
    ) u_ia_loader (
        .clk(clk),
        .rst_n(rst_n),
        
        // 控制接口
        .init_cfg(ia_if.init_cfg),
        .load_ia_req(ia_if.load_ia_req),
        .load_ia_granted(ia_if.load_ia_granted),
        .send_ia_trigger(ia_if.send_ia_trigger),
        
        // 配置参数
        .k(ia_if.k),
        .n(ia_if.n),
        .m(ia_if.m),
        .lhs_zp(ia_if.lhs_zp),
        .lhs_row_stride_b(ia_if.lhs_row_stride_b),
        .lhs_base(ia_if.lhs_base),
        .use_16bits(ia_if.use_16bits),
        
        // ICB接口
        .icb_cmd_m({sa_icb_cmd_valid, sa_icb_cmd_read, sa_icb_cmd_addr, sa_icb_cmd_len, 32'h0, 4'h0}),
        .icb_cmd_s({sa_icb_cmd_ready}),
        .icb_rsp_s({sa_icb_rsp_valid, sa_icb_rsp_rdata, sa_icb_rsp_err}),
        .icb_rsp_m({sa_icb_rsp_ready}),
        
        // 输出接口
        .ia_sending_done(ia_if.ia_sending_done),
        .ia_row_valid(ia_if.ia_row_valid),
        .ia_is_init_data(ia_if.ia_is_init_data),
        .ia_calc_done(ia_if.ia_calc_done),
        .ia_out(ia_if.ia_out),
        .ia_data_valid(ia_if.ia_data_valid)
    );

    // =========================================================================
    // ICB Unalign模块实例化
    // =========================================================================
    icb_unalign #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(BUS_WIDTH)
    ) u_icb_unalign (
        .clk(clk),
        .rst_n(rst_n),
        
        // ICB slave接口（连接ia_loader）
        .icb_s_cmd_valid(sa_icb_cmd_valid),
        .icb_s_cmd_ready(sa_icb_cmd_ready),
        .icb_s_cmd_read(sa_icb_cmd_read),
        .icb_s_cmd_addr(sa_icb_cmd_addr),
        .icb_s_cmd_len(sa_icb_cmd_len),
        .icb_s_rsp_valid(sa_icb_rsp_valid),
        .icb_s_rsp_ready(sa_icb_rsp_ready),
        .icb_s_rsp_rdata(sa_icb_rsp_rdata),
        .icb_s_rsp_err(sa_icb_rsp_err),
        
        // ICB master接口（连接memory）
        .icb_m_cmd_valid(m_icb_cmd_valid),
        .icb_m_cmd_ready(m_icb_cmd_ready),
        .icb_m_cmd_read(m_icb_cmd_read),
        .icb_m_cmd_addr(m_icb_cmd_addr),
        .icb_m_cmd_wdata(m_icb_cmd_wdata),
        .icb_m_cmd_wmask(m_icb_cmd_wmask),
        .icb_m_rsp_valid(m_icb_rsp_valid),
        .icb_m_rsp_ready(m_icb_rsp_ready),
        .icb_m_rsp_rdata(m_icb_rsp_rdata),
        .icb_m_rsp_err(m_icb_rsp_err)
    );

    // =========================================================================
    // Memory Model实例化
    // =========================================================================
    memory_model #(
        .ADDR_W(ADDR_WIDTH),
        .DATA_W(BUS_WIDTH)
    ) golden_mem;
    
    memory_model #(
        .ADDR_W(ADDR_WIDTH),
        .DATA_W(BUS_WIDTH)
    ) m_mem;

    // =========================================================================
    // Memory Responder（参考tb_unalign）
    // =========================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            m_icb_cmd_ready <= 1'b1;
            m_icb_rsp_valid <= 1'b0;
            m_icb_rsp_rdata <= '0;
            m_icb_rsp_err <= 1'b0;
        end else begin
            if (m_icb_cmd_read) begin
                if (m_icb_cmd_valid && m_icb_cmd_ready) begin
                    m_icb_rsp_valid <= 1'b1;
                    m_icb_rsp_rdata <= m_mem.read_word(m_icb_cmd_addr);
                    m_icb_rsp_err <= 1'b0;
                    $display("[M_MEM] Read: addr=0x%08h, data=0x%08h", m_icb_cmd_addr, m_mem.read_word(m_icb_cmd_addr));
                end else if (m_icb_rsp_valid && m_icb_rsp_ready) begin
                    m_icb_rsp_valid <= 1'b0;
                    m_icb_rsp_rdata <= '0;
                    m_icb_rsp_err <= 1'b0;
                end
            end else begin
                if (m_icb_cmd_valid && m_icb_cmd_ready) begin
                    m_mem.write_word(m_icb_cmd_addr, m_icb_cmd_wdata, m_icb_cmd_wmask);
                    $display("[M_MEM] Write: addr=0x%08h, data=0x%08h, mask=%04b", 
                             m_icb_cmd_addr, m_icb_cmd_wdata, m_icb_cmd_wmask);
                    m_icb_rsp_valid <= 1'b1;
                    m_icb_rsp_err <= 1'b0;
                end else if (m_icb_rsp_valid && m_icb_rsp_ready) begin
                    m_icb_rsp_valid <= 1'b0;
                    m_icb_rsp_err <= 1'b0;
                end
            end
        end
    end

    // =========================================================================
    // 测试数据结构
    // =========================================================================
    typedef struct {
        int k;
        int n;
        int m;
        bit use_16bits;
        logic signed [15:0] ia_matrix[];
        int base_addr;
        int row_stride;
    } test_config_t;

    test_config_t current_test;

    // =========================================================================
    // 监控变量
    // =========================================================================
    int monitor_tile_row;
    int monitor_tile_col;
    int monitor_loop_cnt;
    logic signed [DATA_WIDTH-1:0] expected_row[SIZE];
    logic signed [DATA_WIDTH-1:0] actual_row[SIZE];
    int error_count;
    int tile_count;
    int total_test_count = 0;
    int total_error_count = 0;

    // =========================================================================
    // 任务：生成IA矩阵数据
    // =========================================================================
    task automatic generate_ia_matrix(
        input int k,
        input int n,
        input bit use_16bits,
        input bit random_data,
        output logic signed [15:0] ia_matrix[]
    );
        ia_matrix = new[k];
        for (int i = 0; i < k; i++) begin
            ia_matrix[i] = new[n];
            for (int j = 0; j < n; j++) begin
                if (random_data) begin
                    ia_matrix[i][j] = $random & 16'hFFFF;
                end else begin
                    if (use_16bits) begin
                        ia_matrix[i][j] = {i[7:0], j[7:0]};
                    end else begin
                        ia_matrix[i][j] = (i * n + j) & 16'h00FF;
                    end
                end
            end
        end
    endtask

    // =========================================================================
    // 任务：将IA矩阵加载到内存
    // =========================================================================
    task automatic load_ia_to_memory(
        input logic signed [15:0] ia_matrix[][],
        input int k,
        input int n,
        input int base_addr,
        input int row_stride,
        input bit use_16bits
    );
        int addr;
        $display("[%0t] Loading IA matrix to memory: k=%0d, n=%0d, base=0x%0h, stride=%0d, 16bit=%0b", 
                 $time, k, n, base_addr, row_stride, use_16bits);
        
        for (int i = 0; i < k; i++) begin
            addr = base_addr + i * row_stride;
            for (int j = 0; j < n; j++) begin
                if (use_16bits) begin
                    golden_mem.write_halfword(addr + j*2, ia_matrix[i][j]);
                    m_mem.write_halfword(addr + j*2, ia_matrix[i][j]);
                end else begin
                    golden_mem.write_byte(addr + j, ia_matrix[i][j][7:0]);
                    m_mem.write_byte(addr + j, ia_matrix[i][j][7:0]);
                end
            end
        end
        $display("[%0t] Memory loading completed", $time);
    endtask

    // =========================================================================
    // 任务：运行测试激励
    // =========================================================================
    task automatic run_test(
        input int k,
        input int n,
        input int m,
        input bit use_16bits,
        input bit random_data,
        input int verbose_level
    );
        logic signed [15:0] ia_matrix[][];
        int base_addr = 32'h0000_1000;
        int row_stride;
        int test_error_count_before;
        
        total_test_count++;
        test_error_count_before = error_count;
        
        // 计算行步长（字节对齐到4字节边界）
        if (use_16bits) begin
            row_stride = ((n * 2 + 3) / 4) * 4;  // 向上对齐到4字节
        end else begin
            row_stride = ((n + 3) / 4) * 4;      // 向上对齐到4字节
        end
        
        current_test.k = k;
        current_test.n = n;
        current_test.m = m;
        current_test.use_16bits = use_16bits;
        current_test.base_addr = base_addr;
        current_test.row_stride = row_stride;
        
        // 生成并加载IA矩阵
        generate_ia_matrix(k, n, use_16bits, random_data, ia_matrix);
        current_test.ia_matrix = ia_matrix;
        load_ia_to_memory(ia_matrix, k, n, base_addr, row_stride, use_16bits);
        
        // 初始化监控变量
        monitor_tile_row = 0;
        monitor_tile_col = 0;
        monitor_loop_cnt = 0;
        error_count = 0;
        tile_count = 0;
        
        // 配置ia_loader
        $display("\n[%0t] ========== Starting Test ==========", $time);
        $display("[%0t] Configuration: k=%0d, n=%0d, m=%0d, 16bit=%0b, random=%0b, verbose=%0d",
                 $time, k, n, m, use_16bits, random_data, verbose_level);
        
        @(posedge clk);
        ia_if.tb_cb.k <= k;
        ia_if.tb_cb.n <= n;
        ia_if.tb_cb.m <= m;
        ia_if.tb_cb.lhs_zp <= 0;
        ia_if.tb_cb.lhs_row_stride_b <= row_stride;
        ia_if.tb_cb.lhs_base <= base_addr;
        ia_if.tb_cb.use_16bits <= use_16bits;
        ia_if.tb_cb.init_cfg <= 1'b1;
        @(posedge clk);
        ia_if.tb_cb.init_cfg <= 1'b0;
        
        repeat(5) @(posedge clk);
        
        // 开始加载和发送循环
        fork
            // 自动授权load请求
            forever begin
                @(posedge clk);
                if (ia_if.load_ia_req && !ia_if.load_ia_granted) begin
                    repeat(1) @(posedge clk);
                    ia_if.tb_cb.load_ia_granted <= 1'b1;
                    @(posedge clk);
                    ia_if.tb_cb.load_ia_granted <= 1'b0;
                end
            end
            
            // 自动触发发送
            forever begin
                @(posedge clk);
                if (ia_if.ia_data_valid && !ia_if.send_ia_trigger) begin
                    repeat(1) @(posedge clk);
                    ia_if.tb_cb.send_ia_trigger <= 1'b1;
                    @(posedge clk);
                    ia_if.tb_cb.send_ia_trigger <= 1'b0;
                end
            end
            
            // 监控和比较
            begin
                monitor_and_compare(verbose_level);
            end
        join_any
        disable fork;
        
        // 输出测试结果
        $display("\n[%0t] ========== Test Completed ==========", $time);
        $display("[%0t] Total tiles checked: %0d", $time, tile_count);
        if (error_count == test_error_count_before) begin
            $display("[%0t] TEST PASSED - No errors detected", $time);
        end else begin
            $display("[%0t] TEST FAILED - %0d errors detected", $time, error_count - test_error_count_before);
            total_error_count += (error_count - test_error_count_before);
        end
        $display("=======================================\n");
        
        repeat(10) @(posedge clk);
    endtask

    // =========================================================================
    // 任务：监控并比较输出
    // =========================================================================
    task automatic monitor_and_compare(input int verbose_level);
        int row_tile_num, col_tile_num, loop_row_num;
        int current_row_in_tile;
        int total_tiles;
        bit is_first_tile, is_last_tile;
        
        row_tile_num = (current_test.n + SIZE - 1) / SIZE;
        col_tile_num = (current_test.k + SIZE - 1) / SIZE;
        loop_row_num = (current_test.m + SIZE - 1) / SIZE;
        total_tiles = col_tile_num * row_tile_num * loop_row_num;
        
        current_row_in_tile = 0;
        
        $display("[%0t] Monitor: row_tile_num=%0d, col_tile_num=%0d, loop_row_num=%0d, total=%0d",
                 $time, row_tile_num, col_tile_num, loop_row_num, total_tiles);
        
        while (tile_count < total_tiles) begin
            @(posedge clk);
            
            if (ia_if.ia_row_valid) begin
                calculate_expected_row(monitor_tile_row, monitor_tile_col, current_row_in_tile);
                
                for (int i = 0; i < SIZE; i++) begin
                    actual_row[i] = ia_if.ia_out[i];
                end
                
                int dut_tile_row = u_ia_loader.tile_row_idx;
                int dut_tile_col = u_ia_loader.tile_col_idx;
                int dut_loop_cnt = u_ia_loader.loop_row_cnt;
                
                is_first_tile = (monitor_tile_col == 0);
                is_last_tile = (monitor_tile_col == row_tile_num - 1) && (monitor_loop_cnt == loop_row_num - 1);
                
                compare_and_display(verbose_level, dut_tile_row, dut_tile_col, dut_loop_cnt, 
                                   is_first_tile, is_last_tile, current_row_in_tile);
                
                current_row_in_tile++;
                
                if (ia_if.ia_sending_done) begin
                    tile_count++;
                    current_row_in_tile = 0;
                    
                    if (monitor_tile_col == row_tile_num - 1) begin
                        monitor_tile_col = 0;
                        if (monitor_loop_cnt == loop_row_num - 1) begin
                            monitor_loop_cnt = 0;
                            monitor_tile_row++;
                        end else begin
                            monitor_loop_cnt++;
                        end
                    end else begin
                        monitor_tile_col++;
                    end
                    
                    if (verbose_level >= 1) begin
                        $display("[%0t] Tile completed: row=%0d, col=%0d, loop=%0d (progress: %0d/%0d)",
                                $time, monitor_tile_row, monitor_tile_col, monitor_loop_cnt, 
                                tile_count, total_tiles);
                    end
                end
            end
        end
    endtask

    // =========================================================================
    // 任务：计算期望行数据
    // =========================================================================
    task automatic calculate_expected_row(
        input int tile_row,
        input int tile_col,
        input int row_in_tile
    );
        int actual_row_idx = tile_row * SIZE + row_in_tile;
        int actual_col_start = tile_col * SIZE;
        int valid_cols;
        
        if (actual_row_idx >= current_test.k) begin
            for (int i = 0; i < SIZE; i++) begin
                expected_row[i] = 0;
            end
            return;
        end
        
        if (tile_col == (current_test.n + SIZE - 1) / SIZE - 1) begin
            valid_cols = current_test.n - actual_col_start;
        end else begin
            valid_cols = SIZE;
        end
        
        for (int i = 0; i < SIZE; i++) begin
            if (i < valid_cols && actual_col_start + i < current_test.n) begin
                expected_row[i] = current_test.ia_matrix[actual_row_idx][actual_col_start + i];
            end else if (valid_cols > 0) begin
                expected_row[i] = current_test.ia_matrix[actual_row_idx][actual_col_start + valid_cols - 1];
            end else begin
                expected_row[i] = 0;
            end
        end
    endtask

    // =========================================================================
    // 任务：比较并显示结果
    // =========================================================================
    task automatic compare_and_display(
        input int verbose_level,
        input int dut_tile_row,
        input int dut_tile_col,
        input int dut_loop_cnt,
        input bit is_first,
        input bit is_last,
        input int row_in_tile
    );
        bit row_match = 1;
        string result_str;
        
        for (int i = 0; i < SIZE; i++) begin
            if (expected_row[i] !== actual_row[i]) begin
                row_match = 0;
                error_count++;
            end
        end
        
        result_str = row_match ? "PASS" : "FAIL";
        
        if (verbose_level == 0) begin
            if (!row_match) begin
                $display("[%0t] [%s] Tile[%0d][%0d] Loop[%0d] Row=%0d (DUT: [%0d][%0d] Loop[%0d])",
                        $time, result_str, monitor_tile_row, monitor_tile_col, monitor_loop_cnt, row_in_tile,
                        dut_tile_row, dut_tile_col, dut_loop_cnt);
            end
        end else if (verbose_level >= 1) begin
            $display("[%0t] [%s] Tile[%0d][%0d] Loop[%0d] Row=%0d",
                    $time, result_str, monitor_tile_row, monitor_tile_col, monitor_loop_cnt, row_in_tile);
            if (verbose_level >= 2 || !row_match) begin
                display_row_comparison(!row_match);
            end
        end
    endtask

    // =========================================================================
    // 任务：显示行比较
    // =========================================================================
    task automatic display_row_comparison(input bit only_errors);
        string exp_str, act_str;
        
        exp_str = "  Expected: [";
        act_str = "  Actual:   [";
        
        for (int i = 0; i < SIZE; i++) begin
            if (!only_errors || (expected_row[i] !== actual_row[i])) begin
                exp_str = {exp_str, $sformatf("%04h", expected_row[i])};
                act_str = {act_str, $sformatf("%04h", actual_row[i])};
                if (i < SIZE - 1) begin
                    exp_str = {exp_str, ", "};
                    act_str = {act_str, ", "};
                end
            end
        end
        
        exp_str = {exp_str, "]"};
        act_str = {act_str, "]"};
        
        $display("%s", exp_str);
        $display("%s", act_str);
    endtask

    // =========================================================================
    // 测试用例
    // =========================================================================
    initial begin
        // 初始化memory model
        golden_mem = new("golden_mem");
        m_mem = new("m_mem");
        
        // 等待复位完成
        @(posedge rst_n);
        repeat(10) @(posedge clk);
        
        // =====================================================================
        // 测试用例1: 16位数据，69x66矩阵，有规律数据
        // =====================================================================
        $display("\n");
        $display("╔════════════════════════════════════════════════════════╗");
        $display("║          Test Case 1: 16-bit, 69x66, Regular          ║");
        $display("╚════════════════════════════════════════════════════════╝");
        run_test(.k(69), .n(66), .m(64), .use_16bits(1), .random_data(0), .verbose_level(2));
        
        // =====================================================================
        // 测试用例2: 8位数据，65x68矩阵
        // =====================================================================
        $display("\n");
        $display("╔════════════════════════════════════════════════════════╗");
        $display("║           Test Case 2: 8-bit, 65x68, Regular          ║");
        $display("╚════════════════════════════════════════════════════════╝");
        run_test(.k(65), .n(68), .m(48), .use_16bits(0), .random_data(0), .verbose_level(2));
        
        // =====================================================================
        // 测试用例3: 16位数据，精确tile大小
        // =====================================================================
        $display("\n");
        $display("╔════════════════════════════════════════════════════════╗");
        $display("║       Test Case 3: 16-bit, 16x16, Exact Tile          ║");
        $display("╚════════════════════════════════════════════════════════╝");
        run_test(.k(16), .n(16), .m(16), .use_16bits(1), .random_data(0), .verbose_level(3));
        
        // =====================================================================
        // 测试用例4: 8位数据，多次循环
        // =====================================================================
        $display("\n");
        $display("╔════════════════════════════════════════════════════════╗");
        $display("║      Test Case 4: 8-bit, 32x32, Multiple Loops        ║");
        $display("╚════════════════════════════════════════════════════════╝");
        run_test(.k(32), .n(32), .m(80), .use_16bits(0), .random_data(0), .verbose_level(1));
        
        // =====================================================================
        // 测试用例5: 边界条件 - 小矩阵
        // =====================================================================
        $display("\n");
        $display("╔════════════════════════════════════════════════════════╗");
        $display("║         Test Case 5: 16-bit, 8x8, Small Matrix        ║");
        $display("╚════════════════════════════════════════════════════════╝");
        run_test(.k(8), .n(8), .m(8), .use_16bits(1), .random_data(0), .verbose_level(3));
        
        // =====================================================================
        // 随机测试用例（100次）
        // =====================================================================
        $display("\n");
        $display("╔════════════════════════════════════════════════════════╗");
        $display("║              Random Test Cases (100x)                  ║");
        $display("╚════════════════════════════════════════════════════════╝");
        
        for (int i = 0; i < 100; i++) begin
            int rand_k, rand_n, rand_m;
            bit rand_use_16bits;
            
            // 随机生成参数
            rand_k = $urandom_range(1, 128);
            rand_n = $urandom_range(1, 128);
            rand_m = $urandom_range(1, 128);
            rand_use_16bits = $urandom_range(0, 1);
            
            $display("\n[Random Test %0d/100] k=%0d, n=%0d, m=%0d, 16bit=%0b",
                    i+1, rand_k, rand_n, rand_m, rand_use_16bits);
            
            run_test(.k(rand_k), .n(rand_n), .m(rand_m), 
                    .use_16bits(rand_use_16bits), .random_data(1), .verbose_level(0));
        end
        
        // 测试完成 - 调用Finish任务
        $display("\n");
        $display("╔════════════════════════════════════════════════════════╗");
        $display("║              ALL TESTS COMPLETED                       ║");
        $display("╚════════════════════════════════════════════════════════╝");
        
        repeat(100) @(posedge clk);
        
        // 调用Finish任务显示最终结果
        Finish(total_error_count, total_test_count);
    end

    // =========================================================================
    // FSDB Dump
    // =========================================================================
    initial begin
        $fsdbDumpfile("tb_ia_loader.fsdb");
        $fsdbDumpvars();
        $fsdbDumpSVA();
        $fsdbDumpMDA();
    end

    // =========================================================================
    // 超时保护
    // =========================================================================
    initial begin
        #100_000_000;
        $display("[ERROR] Simulation timeout!");
        $finish;
    end

endmodule

