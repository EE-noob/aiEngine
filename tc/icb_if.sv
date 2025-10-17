/*
 * ICB总线接口定义
 * 包含扩展三通道：命令通道、响应通道
 * 提供Master和Slave两种clocking block便于testbench使用
 */

`include "../include/icb_types.svh"

interface icb_if #(
    parameter int unsigned BUS_WIDTH = 32
) (
    input logic clk,
    input logic rst_n
);

    // =========================================================================
    // 命令通道信号
    // =========================================================================
    icb_ext_cmd_m_t cmd_m;  // Master -> Slave: 命令有效载荷
    icb_ext_cmd_s_t cmd_s;  // Slave -> Master: 命令就绪

    // =========================================================================
    // 响应通道信号
    // =========================================================================
    icb_ext_rsp_s_t rsp_s;  // Slave -> Master: 响应有效载荷
    icb_ext_rsp_m_t rsp_m;  // Master -> Slave: 响应就绪

    // =========================================================================
    // Master端时钟块（用于testbench作为发起方）
    // =========================================================================
    clocking master_cb @(posedge clk);
        // 输出：Master驱动的信号
        output cmd_m;
        output rsp_m;
        
        // 输入：Slave返回的信号
        input cmd_s;
        input rsp_s;
    endclocking

    // =========================================================================
    // Slave端时钟块（用于testbench作为响应方）
    // =========================================================================
    clocking slave_cb @(posedge clk);
        // 输入：Master驱动的信号
        input cmd_m;
        input rsp_m;
        
        // 输出：Slave返回的信号
        output cmd_s;
        output rsp_s;
    endclocking

    // =========================================================================
    // Monitor时钟块（用于监控总线事务）
    // =========================================================================
    clocking monitor_cb @(posedge clk);
        input cmd_m;
        input cmd_s;
        input rsp_s;
        input rsp_m;
    endclocking

    // =========================================================================
    // Modport定义
    // =========================================================================
    modport master (
        clocking master_cb,
        input clk,
        input rst_n
    );

    modport slave (
        clocking slave_cb,
        input clk,
        input rst_n
    );

    modport monitor (
        clocking monitor_cb,
        input clk,
        input rst_n
    );

    // =========================================================================
    // DUT连接modport（直接信号连接，不使用clocking）
    // =========================================================================
    modport dut_master (
        output cmd_m,
        input cmd_s,
        input rsp_s,
        output rsp_m
    );

    modport dut_slave (
        input cmd_m,
        output cmd_s,
        output rsp_s,
        input rsp_m
    );

    // =========================================================================
    // 辅助函数：命令握手检测
    // =========================================================================
    function automatic bit is_cmd_handshake();
        return cmd_m.valid && cmd_s.ready;
    endfunction

    // =========================================================================
    // 辅助函数：响应握手检测
    // =========================================================================
    function automatic bit is_rsp_handshake();
        return rsp_s.rsp_valid && rsp_m.rsp_ready;
    endfunction

    // =========================================================================
    // 辅助任务：等待命令握手完成
    // =========================================================================
    task automatic wait_cmd_handshake();
        @(posedge clk);
        while (!is_cmd_handshake()) begin
            @(posedge clk);
        end
    endtask

    // =========================================================================
    // 辅助任务：等待响应握手完成
    // =========================================================================
    task automatic wait_rsp_handshake();
        @(posedge clk);
        while (!is_rsp_handshake()) begin
            @(posedge clk);
        end
    endtask

endinterface
