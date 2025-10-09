module serial_divider (
    input clk,
    input rst_n,
    input start,
    input [15:0] dividend,//被除数
    input [15:0] divisor,//除数
    output reg done,
    output reg [15:0] quotient,//商
    output reg [15:0] remainder//余数
);

    reg [4:0] count; // 计数器，最多16次
    reg [15:0] dividend_reg;
    reg [15:0] divisor_reg;
    reg [15:0] rem;
    reg [15:0] quot;
    reg busy;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            done <= 0;
            quotient <= 0;
            remainder <= 0;
            count <= 0;
            busy <= 0;
        end else begin
            if (start && !busy) begin
                // 初始化
                dividend_reg <= dividend;
                divisor_reg <= divisor;
                quot <= 0;
                rem <= 0;
                count <= 0;
                done <= 0;
                busy <= 1;
            end else if (busy) begin
                // 移位和减法
                rem = {rem[14:0], dividend_reg[15]};
                dividend_reg = dividend_reg << 1;

                if (rem >= divisor_reg) begin
                    rem = rem - divisor_reg;
                    quot = {quot[14:0], 1'b1};
                end else begin
                    quot = {quot[14:0], 1'b0};
                end

                count = count + 1;
                if (count == 16) begin
                    busy <= 0;
                    done <= 1;
                    quotient <= quot;
                    remainder <= rem;
                end
            end else begin
                done <= 0; // 清除done信号
            end
        end
    end

endmodule