// ===============================================================
// tri_wr32_consistency_chk.sv
//  - 统计 & 对比 wr32 触发次数和 E_left32bits_nums 递减次数
// ===============================================================
module tri_wr32_consistency_chk #(
    parameter string ID = "part0"   // 便于打印时区分实例
)(
    input  logic        clk,
    input  logic        rst_n,
    input  logic        tri_wr32_en,          // 被监控的 wr32 脉冲
    input  logic [13:0] E_left32bits_nums     // 对应 part 的计数器
);

    // 上一拍的 E_left 值，用来检测“递减 1”事件
    logic [13:0] E_left_prev;

    // 两个计数器
    logic [31:0] wr32_cnt;    // tri_wr32_en 拉高次数
    logic [31:0] dec_cnt;     // E_left32bits_nums 递减 1 次数

    // 记录首次不一致的时刻，只打印一次即可
    logic first_mismatch_reported;

    //------------------ 计数逻辑 ------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr32_cnt                <= '0;
            dec_cnt                 <= '0;
            E_left_prev             <= '0;
            first_mismatch_reported <= 1'b0;
        end else begin
            // 统计 wr32_en 拉高
            if (tri_wr32_en) wr32_cnt++;

            // 侦测 “递减 1” 事件再计数
            if (E_left_prev - E_left32bits_nums == 1)
                dec_cnt++;

            // 记录上一拍值
            E_left_prev <= E_left32bits_nums;

            // 若二者第一次出现不一致，立即打印位置
            if (!first_mismatch_reported && wr32_cnt != dec_cnt) begin
                first_mismatch_reported <= 1'b1;
                $display("%0t [%s] cnt begin unsame: wr32_cnt=%0d  dec_cnt=%0d",
                         $time, ID, wr32_cnt, dec_cnt);
            end
        end
    end

    //------------------ 一致性断言 ------------------
    property p_cnt_consistent;
        @(posedge clk) disable iff (!rst_n)
            wr32_cnt == dec_cnt;
    endproperty

    // 如果模拟过程中任何一个时刻出现不一致就报错
    // always_ff @(posedge clk ) begin
    // assert property (p_cnt_consistent)
    //     else $error("[%s] wr32_cnt=%0d 与 dec_cnt=%0d unsame ！ (@%0t)",
    //                 ID, wr32_cnt, dec_cnt, $time);
    //     end
    //------------------ 结束时打印汇总 ------------------
    final begin
        $display("[%s] final cnt：wr32_cnt=%0d  dec_cnt=%0d", ID, wr32_cnt, dec_cnt);
    end

endmodule

// ===============================================================
// tri_wr32_bind.sv
// ===============================================================
//import tri_wr32_consistency_chk::*;

bind intlv_top
    tri_wr32_consistency_chk #("part0") chk_p0
    ( .clk(clk), .rst_n(rst_n),
      .tri_wr32_en(part0_tri_wr32_en),
      .E_left32bits_nums(part0_E_left_32bits_nums));

bind intlv_top
    tri_wr32_consistency_chk #("part1") chk_p1
    ( .clk(clk), .rst_n(rst_n),
      .tri_wr32_en(part1_tri_wr32_en),
      .E_left32bits_nums(part1_E_left_32bits_nums));

bind intlv_top
    tri_wr32_consistency_chk #("part2") chk_p2
    ( .clk(clk), .rst_n(rst_n),
      .tri_wr32_en(part2_tri_wr32_en),
      .E_left32bits_nums(part2_E_left_32bits_nums));
