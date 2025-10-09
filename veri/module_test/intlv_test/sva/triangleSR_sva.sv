//============================================================
// triangleSR_sva.sv  ——  绑定 TriangleSR 并打印 13×13 三角
//============================================================
    `ifndef TRIANGLESR_SVA_SV
    `define TRIANGLESR_SVA_SV
    
    module triangleSR_sva #(
        parameter int SIDE        = 128,       // 与 DUT 保持一致
        parameter int TOTAL_BITS  = SIDE*(SIDE+1)/2,
        parameter int PR_ROWS     = 13,        // 只打印前 13 行
        parameter int N1          = 38,
        parameter int N2          = 11,
        parameter int N3          = 3,
        parameter int readModeNum = 3
    )(
        input  logic                     clk,
        input  logic                     rst_n,
    
        // 操作使能
        input  logic                     wr1_en,
        input  logic                     wr32_en,
        input  logic                     diag_shift_en,
        input  logic                     rd1_en,
        input  logic                     rdN1_en,
        input  logic                     rdN2_en,
        input  logic                     rdN3_en,
    
        input  logic         wr1_data,
        input  logic [31:0]  wr32_data,
    
        // DUT 内部寄存器（通过 bind 连接）
        input  logic [TOTAL_BITS-1:0]    tri_q
    );
    
        //------------------- idx 计算函数 ---------------------------------    
    //============================================================
    // 1.  工具函数：idx(row,col) → flat index
    //============================================================
        function automatic int idx (input int r, input int c);
            return ((r + 1) * r) / 2 + ((r + 1) - (c + 1));
        endfunction
        //============================================================
    // 2.  生成安全文件名 —— 不用 string.find/replace
    //     将非法字符(. $ / \ space) 替换成 "_"
    //============================================================
        function automatic string sanitize_filename (input string raw);
        automatic string out="" ;      // 结果
        automatic byte   ch  ;          // 当前字符 (8‑bit)
        automatic int    len ;
        len = raw.len();
        for (int j = 0; j < len; j++) begin
            ch = raw.getc(j);
            // 非法字符列表：'.' '$' '/' '\\' ' '
            if (ch == 8'd46 /* . */  ||
                ch == 8'd36 /* $ */  ||
                ch == 8'd47 /* / */  ||
                ch == 8'd92 /* \\ */ ||
                ch == 8'd32 /* space */) begin
                out = {out, "_"};
            end else begin
                out = {out, ch};
            end
        end
        return out;
    endfunction   
    //============================================================
    // 3.  打开输出文件（一次性）
    //============================================================
        integer fd;
        initial begin : GEN_DUMP_FILE
            // 取实例层次名并转义
            string raw_name      = $sformatf("%m");
            string safe_name     = sanitize_filename(raw_name);
            string file_name     = $sformatf("triangleSR_dump_%s.txt", safe_name);
            fd = $fopen(file_name, "w");
            if (fd == 0) $fatal(1, "无法创建 %s", file_name);
            $display("[triangleSR_sva] 打开 dump 文件: %s", file_name);
        end
    
    //============================================================
    // 4.  每周期打印 TriangleSR 状态
    //============================================================
        int cycle_cnt;
        string mode_s;
        int r, c, li;
        always_ff @(posedge clk or negedge rst_n) begin
            if (!rst_n) cycle_cnt <= 0;
            else begin
                //---------------- 模式判定 --------------------------------
                //unique case (1'b1)
                case (1'b1)
                    wr32_en:       mode_s = "WR32";
                    wr1_en:        mode_s = "WR1 ";
                    diag_shift_en: mode_s = "DIAG";
                    rd1_en:        mode_s = "RD1 ";
                    rdN1_en:       mode_s = $sformatf("RDN1_%0d", N1);
                    rdN2_en:       mode_s = $sformatf("RDN2_%0d", N2);
                    rdN3_en:       mode_s = $sformatf("RDN3_%0d", N3);
                    default:       mode_s = "HOLD";
                endcase
    
                //---------------- 文件输出 --------------------------------
                if(mode_s !="HOLD") begin
                    $fwrite(fd,
                            "\n=== Cycle %0d | Mode %-7s | wr1_data %x | wr32_data %x ,%b_%b_%b_%b__%b_%b_%b_%b | print_rows=%0d ===\n",
                            cycle_cnt, mode_s, wr1_data,wr32_data,wr32_data[31:28],wr32_data[27:24],wr32_data[23:20],wr32_data[19:16],wr32_data[15:12],wr32_data[11:8],wr32_data[7:4],wr32_data[3:0],PR_ROWS);
                    
                    for ( r = PR_ROWS; r>=0 ; r--) begin
                        
                        if(r==PR_ROWS)begin
                            $fwrite(fd, "rolN:");
                            for (int c = 0; c <= r; c++) begin
                                li = idx(r, c);
                                $fwrite(fd, " %3d", c );
                            end
                            $fwrite(fd, "\n");
                        end
                        else begin
                            $fwrite(fd, "r%03d:", r);
                            for (int c = 0; c <= r; c++) begin
                                li = idx(r, c);
                                $fwrite(fd, " %3d", tri_q[li]);
                            end
                            $fwrite(fd, "\n");
                        end

                    end
                    $fwrite(fd, "---------------------------------------------\n");
    
                    cycle_cnt <= cycle_cnt + 1;
                end
            end
        end
    endmodule
    
    
    //===================== bind 到所有 TriangleSR =========================
    bind triangleSR triangleSR_sva #(
            .SIDE        (128),
            .PR_ROWS     (90),
            .N1          (N1),
            .N2          (N2),
            .N3          (N3),
            .readModeNum (readModeNum)
        ) tri_sva_inst ( .* , .tri_q(tri_q) );
    
    `endif  // TRIANGLESR_SVA_SV
    