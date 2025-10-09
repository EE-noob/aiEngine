module scramble_tb;

  // >>>>> DUT 接口信号 <<<<<
  logic clk;
  logic rst_n;
  logic scramble_en;
  logic [30:0] ics_c_init;
  logic [3:0]  ics_q_size;
  logic [9:0] scramble_data [0:11];
  logic scramble_ready;
  logic ics_start;

  scramble dut (
    .clk(clk),
    .rst_n(rst_n),
    .ics_c_init(ics_c_init),
    .ics_q_size(ics_q_size),
    .scramble_en(scramble_en),
    .scramble_data(scramble_data),
    .scramble_ready(scramble_ready),
    .ics_start(ics_start)
  );

  // >>>>> 时钟生成 <<<<<
  always #5 clk = ~clk;

  // >>>>> 存储参考数据和DUT输出 <<<<<
  int ref_data[$];                              // 展平后的参考数据
  logic [`ICS_Q_SIZE-1:0] captured_data[$];     // 展平后的 DUT 输出数据

  // >>>>> 读取参考文件 <<<<<
  task read_reference_data(string filename, int bit_width);
    int fd;
    int val;
    string line;
    fd = $fopen(filename, "r");
    if (fd == 0) begin
      $fatal("无法打开参考数据文件：%s", filename);
    end
    while (!$feof(fd)) begin
      line = "";
      void'($fgets(line, fd));
      if (line.len() > 0) begin
        $sscanf(line, "0x%x", val);
        ref_data.push_back(val & ((1 << bit_width) - 1));
      end
    end
    $fclose(fd);
    $display("参考数据读取完成，共 %0d 行", ref_data.size());
  endtask

  // >>>>> 波形转储 <<<<<
  initial begin
    $fsdbDumpfile("scramble_tb.fsdb");
    $fsdbDumpvars(0, scramble_tb, "+all");
    $fsdbDumpMDA(0, scramble_tb);
  end
    
  // >>>>> 主测试流程 <<<<<
  initial begin
   int sample_count;
   int errors;
   int total;
    clk = 0;
    rst_n = 0;
    scramble_en = 0;
    ics_start = 0;
    ics_c_init = 31'h0;
    ics_q_size = 4'h0;

    read_reference_data(`ICS_SCRAMBLE_CODE, `ICS_Q_SIZE);

    // 复位
    #20;
    rst_n = 1;
    #10;
    ics_start = 1;
    ics_c_init = `ICS_C_INIT;
    ics_q_size = `ICS_Q_SIZE;
    #10;
    ics_start = 0;
    #10;
    scramble_en = 1;

    // 等待并采集 scramble_data ICS_SCRAMBLE_OUTPUT_NUM 次
    sample_count = 0;

    while (sample_count < `ICS_SCRAMBLE_OUTPUT_NUM) begin
      @(posedge clk);
      if (scramble_ready) begin
        for (int i = 0; i < 12; i++) begin
          captured_data.push_back(scramble_data[i]);
        end
        sample_count++;
        $display("采集第 %0d 次 scramble_data", sample_count);
      end
    end

    // >>>>> 比对参考数据 <<<<<
    errors = 0;
    total = ref_data.size() < captured_data.size() ? ref_data.size() : captured_data.size();

    for (int i = 0; i < total; i++) begin
      if (captured_data[i] !== ref_data[i]) begin
        $display("Mismatch at index %0d: DUT = %0h, REF = %0h", i, captured_data[i], ref_data[i]);
        errors++;
      end
    end

    if (errors == 0) begin
      $display("[PASS] 所有 %0d 项输出均正确匹配", total);
    end else begin
      $display("[FAIL] 发现 %0d 项 mismatch，在 %0d 项中", errors, total);
    end

    $finish;
  end

endmodule
