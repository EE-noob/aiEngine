/*
 * ia_loader控制接口定义
 * 包含配置参数、控制信号和输出信号
 * 提供testbench和DUT两种clocking block
 */

interface ia_loader_if #(
    parameter int unsigned DATA_WIDTH = 16,
    parameter int unsigned SIZE = 16,
    parameter int unsigned REG_WIDTH = 32
) (
    input logic clk,
    input logic rst_n
);

    // =========================================================================
    // 配置控制信号
    // =========================================================================
    logic init_cfg;  // 触发配置参数锁存（单拍脉冲）

    // =========================================================================
    // Load/Send控制信号
    // =========================================================================
    logic load_ia_req;       // 申请下一次访存授权（输出）
    logic load_ia_granted;   // 外部授权下一次访存（输入）
    logic send_ia_trigger;   // 触发发送输入激活（脉冲）

    // =========================================================================
    // 矩阵尺寸配置参数
    // =========================================================================
    logic [REG_WIDTH-1:0] k;  // 输入激活矩阵行数
    logic [REG_WIDTH-1:0] n;  // 输入激活矩阵列数
    logic [REG_WIDTH-1:0] m;  // 输出矩阵列数

    // =========================================================================
    // 配置寄存器
    // =========================================================================
    logic signed [REG_WIDTH-1:0] lhs_zp;            // 输入激活零点偏移
    logic [REG_WIDTH-1:0]        lhs_row_stride_b;  // 行地址间距（字节）
    logic [REG_WIDTH-1:0]        lhs_base;          // 读取基地址
    logic                        use_16bits;        // 数据类型（1=s16, 0=s8）

    // =========================================================================
    // 输出信号到脉动阵列
    // =========================================================================
    logic                         ia_sending_done;  // 当前tile发送完成（脉冲）
    logic                         ia_row_valid;     // 当前行数据有效
    logic                         ia_is_init_data;  // 当前为第一个tile数据
    logic                         ia_calc_done;     // 当前为最后一个tile（部分和完成）
    logic signed [DATA_WIDTH-1:0] ia_out [SIZE];    // 输出数据（一行）
    logic                         ia_data_valid;    // 数据已准备好可发送

    // =========================================================================
    // Testbench端时钟块（用于驱动DUT）
    // =========================================================================
    clocking tb_cb @(posedge clk);
        // 配置输入
        output init_cfg;
        output k, n, m;
        output lhs_zp;
        output lhs_row_stride_b;
        output lhs_base;
        output use_16bits;
        
        // 控制输入
        output load_ia_granted;
        output send_ia_trigger;
        
        // DUT输出
        input load_ia_req;
        input ia_sending_done;
        input ia_row_valid;
        input ia_is_init_data;
        input ia_calc_done;
        input ia_out;
        input ia_data_valid;
    endclocking

    // =========================================================================
    // DUT端时钟块（用于监控DUT行为）
    // =========================================================================
    clocking dut_cb @(posedge clk);
        // 配置输入
        input init_cfg;
        input k, n, m;
        input lhs_zp;
        input lhs_row_stride_b;
        input lhs_base;
        input use_16bits;
        
        // 控制信号
        input load_ia_granted;
        input send_ia_trigger;
        output load_ia_req;
        
        // 输出信号
        output ia_sending_done;
        output ia_row_valid;
        output ia_is_init_data;
        output ia_calc_done;
        output ia_out;
        output ia_data_valid;
    endclocking

    // =========================================================================
    // Monitor时钟块（用于被动监控）
    // =========================================================================
    clocking monitor_cb @(posedge clk);
        input init_cfg;
        input k, n, m;
        input lhs_zp, lhs_row_stride_b, lhs_base, use_16bits;
        input load_ia_req, load_ia_granted;
        input send_ia_trigger;
        input ia_sending_done, ia_row_valid;
        input ia_is_init_data, ia_calc_done;
        input ia_out, ia_data_valid;
    endclocking

    // =========================================================================
    // Modport定义
    // =========================================================================
    modport testbench (
        clocking tb_cb,
        input clk,
        input rst_n
    );

    modport dut (
        clocking dut_cb,
        input clk,
        input rst_n
    );

    modport monitor (
        clocking monitor_cb,
        input clk,
        input rst_n
    );

    // =========================================================================
    // DUT直接连接modport（不使用clocking，用于模块例化）
    // =========================================================================
    modport dut_ports (
        // 输入
        input init_cfg,
        input load_ia_granted,
        input send_ia_trigger,
        input k, n, m,
        input lhs_zp, lhs_row_stride_b, lhs_base, use_16bits,
        
        // 输出
        output load_ia_req,
        output ia_sending_done,
        output ia_row_valid,
        output ia_is_init_data,
        output ia_calc_done,
        output ia_out,
        output ia_data_valid
    );

    // =========================================================================
    // 辅助任务：初始化配置
    // =========================================================================
    task automatic init_config(
        input [REG_WIDTH-1:0] k_val,
        input [REG_WIDTH-1:0] n_val,
        input [REG_WIDTH-1:0] m_val,
        input signed [REG_WIDTH-1:0] zp_val,
        input [REG_WIDTH-1:0] stride_val,
        input [REG_WIDTH-1:0] base_val,
        input bit use_16bits_val
    );
        @(tb_cb);
        tb_cb.k <= k_val;
        tb_cb.n <= n_val;
        tb_cb.m <= m_val;
        tb_cb.lhs_zp <= zp_val;
        tb_cb.lhs_row_stride_b <= stride_val;
        tb_cb.lhs_base <= base_val;
        tb_cb.use_16bits <= use_16bits_val;
        tb_cb.init_cfg <= 1'b1;
        @(tb_cb);
        tb_cb.init_cfg <= 1'b0;
    endtask

    // =========================================================================
    // 辅助任务：等待数据准备完成
    // =========================================================================
    task automatic wait_data_valid();
        @(tb_cb);
        while (!tb_cb.ia_data_valid) begin
            @(tb_cb);
        end
    endtask

    // =========================================================================
    // 辅助任务：发送trigger并等待完成
    // =========================================================================
    task automatic trigger_send_and_wait();
        @(tb_cb);
        tb_cb.send_ia_trigger <= 1'b1;
        @(tb_cb);
        tb_cb.send_ia_trigger <= 1'b0;
        
        // 等待发送完成
        while (!tb_cb.ia_sending_done) begin
            @(tb_cb);
        end
    endtask

    // =========================================================================
    // 辅助任务：授权load请求
    // =========================================================================
    task automatic grant_load_request();
        @(tb_cb);
        while (!tb_cb.load_ia_req) begin
            @(tb_cb);
        end
        tb_cb.load_ia_granted <= 1'b1;
        @(tb_cb);
        tb_cb.load_ia_granted <= 1'b0;
    endtask

    // =========================================================================
    // 辅助函数：检查是否为有效行
    // =========================================================================
    function automatic bit is_valid_row();
        return ia_row_valid;
    endfunction

endinterface
