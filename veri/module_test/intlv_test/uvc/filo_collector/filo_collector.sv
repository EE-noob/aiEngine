// -------------------------
// filo_collector.sv
// -------------------------
class filo_collector extends uvm_component;
  `uvm_component_utils(filo_collector)

  virtual filo_env_if vif;

  typedef uvm_queue#(logic [9:0]) data_q_10_t;
  typedef uvm_queue#(logic [3:0]) data_q_4_t;
  typedef uvm_queue#(logic)       data_q_1_t;
  typedef struct packed {
  bit [9:0] data;
  int       width; // 可为 10, 4, 1
  } data_unit_t;
  
  typedef uvm_queue#(data_unit_t) data_q_all_t;
  // 单独的队列，不分 fifo0 和 fifo1 了
  data_q_all_t data_q_all[3]; // 每个 part 一个队列

  function new(string name, uvm_component parent);
    super.new(name,parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(virtual filo_env_if)::get(this, "", "filo_vif", vif))
      `uvm_fatal("NOVIF","Cannot get vif from config DB");

    for (int part = 0; part < 3; part++) begin
        data_q_all[part] = new(); // 👈 新增初始化
    end

  endfunction

function void compare_with_reference(string ref_file);
  int fd;
  int shift_pos;
  string line;
  bit [255:0] golden_data [3];
  bit [255:0] dut_data [3];

  fd = $fopen(ref_file, "r");
  if (fd == 0) begin
    `uvm_fatal("COMPARE", $sformatf("Cannot open reference file: %s", ref_file));
    return;
  end

  for (int i = 0; i < 3; i++) begin
    void'($fgets(line, fd));
    if (line.len() < 1) begin
      `uvm_fatal("COMPARE", $sformatf("Line %0d in reference file is empty", i));
      return;
    end

    // 处理0x前缀（可选）
    if (line.len() >= 2 && line.substr(0,1) == "0x") begin
      line = line.substr(2); // 去掉0x
    end

    // 转为bit vector，假设line是16进制格式
    if (!$sscanf(line, "%h", golden_data[i])) begin
      `uvm_fatal("COMPARE", $sformatf("Failed to parse line %0d: %s", i, line));
    end
  end

  $fclose(fd);

  for (int part = 0; part < 3; part++) begin
  bit total_bits[$];  // 动态数组，收集所有 bit

  // Step 1: 收集 data_q_all 中所有 bit（按 push 顺序，低位在前）
    for (int j = 0; j < data_q_all[part].size(); j++) begin
      data_unit_t d = data_q_all[part].get(j);
      // 提取每一位（高位在前）
      for (int b = d.width - 1; b >= 0; b--) begin
        total_bits.push_back(d.data[b]);
      end
    end
  // Step 2: 按 total_bits 的逆序拼成 dut_data（先 push 的 bit 放低位）
  dut_data[part] = 0;
  for (int i = total_bits.size() - 1; i >= 0; i--) begin
    dut_data[part] = (dut_data[part] << 1) | total_bits[i];
  end

  // 比较逻辑
  if (dut_data[part] !== golden_data[part]) begin
    `uvm_info("COMPARE", $sformatf("\n\n********** MISMATCH in part%0d DETECTED!!!! **********\n", part), UVM_LOW)
    //TODO: use below for debug use
    //`uvm_error("COMPARE", $sformatf("Mismatch in part%0d!\nExpect: %h\nActual: %h", part, golden_data[part], dut_data[part]))
  end else begin
    `uvm_info("COMPARE", $sformatf("\n\n********** MATCH in part%0d !!!! ********** \n: dut_data is:%h", part, dut_data[part]), UVM_LOW)
  end
end

endfunction

int group_widths_0[] = `GROUP_WIDTH_ARRAY_0;
int group_widths_1[] = `GROUP_WIDTH_ARRAY_1;
int group_widths_2[] = `GROUP_WIDTH_ARRAY_2;
int part_line_counts[3] = `GOLDEN_LINES_PER_PART;

task run_phase(uvm_phase phase);
  phase.raise_objection(this);
  extract_golden_lines(`ICS_INTLV_OUT_DATA,part_line_counts); 
    fork
      begin
        for (int part = 0; part < 3; part++) begin
          for (int fifo = 0; fifo < 2; fifo++) begin
            int _part = part;
            int _fifo = fifo;
            fork
              monitor_fifo(_part, _fifo);
            join_none
          end
        end 
      end
      begin
        wait(vif.combine_eof === 1'b1);
        `uvm_info("TRIGGER", "compare_trigger asserted, starting comparison", UVM_MEDIUM)
        compare_with_reference(`ICS_INTLV_OUT_DATA); 
        compare_to_golden(0,group_widths_0);
        compare_to_golden(1,group_widths_1);
        compare_to_golden(2,group_widths_2);

        `uvm_info(get_full_name(), "Drop objection", UVM_LOW);
        phase.drop_objection(this); 
      end
    join_none
  endtask

task monitor_fifo(int part, int fifo);
  const int RDW_A = 10;
  const int RDW_B = 4;

  logic rdy;
  logic rdy_reg;
  logic [$clog2(128+1)-1:0] cnt;
  logic 
  logic [9:0] data_A;
  logic [9:0] rev_data_A;
  logic [3:0] data_B;
  logic [3:0] rev_data_B;    
  logic data_1;
  logic rev_data_1;
  data_unit_t d;

  `uvm_info("MONITOR_START", $sformatf("monitor_fifo started for part%0d fifo%0d", part, fifo), UVM_LOW)

  forever begin
    @(posedge vif.clk);
    rdy = vif.get_rdy4rd(part, fifo);
    @(posedge clk);
    rdy_reg = rdy;

    if (rdy_reg) begin
      cnt = get_cnt(part, fifo);
      if (cnt >= RDW_A) begin
        

      end
      
    end

  end

endtask
      if (vif.get_rdA_en(part, fifo)) begin
        data_A = vif.get_rdA_data(part, fifo);
        rev_data_A = {<<{data_A}};

        d.data = data_A;
        d.width = 10;
        data_q_all[part].push_back(d);

        `uvm_info("FIFO_MON", $sformatf("part%0d fifo%0d rdA_data = %h fifo_in_data = %b", part, fifo, data_A, rev_data_A), UVM_MEDIUM)

      end else if (vif.get_rdB_en(part, fifo)) begin
        data_B = vif.get_rdB_data(part, fifo);
        rev_data_B = {<<{data_B}};

        d.data = data_B;
        d.width = 4;
        data_q_all[part].push_back(d);

        `uvm_info("FIFO_MON", $sformatf("part%0d fifo%0d rdB_data = %h fifo_in_data = %b", part, fifo, data_B, rev_data_B), UVM_MEDIUM)

      end else if (vif.get_rd1_en(part, fifo)) begin
        data_1 = vif.get_rd1_data(part, fifo);
        rev_data_1 = {<<{data_1}};

        d.data = data_1;
        d.width = 1;
        data_q_all[part].push_back(d);

        `uvm_info("FIFO_MON", $sformatf("part%0d fifo%0d rd1_data = %h fifo_in_data = %b", part, fifo, data_1, rev_data_1), UVM_MEDIUM)
      end
      //TODO:open these for tb debug
      //print_data_q_part(part);
      //compare_to_golden(part);
    end
  end
endtask

function string bin_str(bit [9:0] data, int width);
  string result = "";
  for (int i = width-1; i >= 0; i--) begin
    result = {result, (data[i] ? "1" : "0")};
  end
  return result;
endfunction

function void print_data_q_part(int part);
  string line = $sformatf("part%0d: ", part);
  data_unit_t item;
  string bit_str = "";

  // 收集所有 bit（按 push 顺序，从高位到低位）
  bit all_bits[$];
    for (int i = 0; i < data_q_all[part].size(); i++) begin
      item = data_q_all[part].get(i);
      for (int b = item.width - 1; b >= 0; b--) begin
        all_bits.push_back(item.data[b]);
      end
    end
  // 逆序拼接 bit_str
  for (int i = all_bits.size() - 1; i >= 0; i--) begin
    bit_str = {bit_str, all_bits[i] ? "1" : "0"};
  end

  `uvm_info("DATA_Q", {line, bit_str}, UVM_MEDIUM)
endfunction

typedef string string_q_t[$];
string_q_t golden_lines[3];

function void extract_golden_lines(string file_path, int part_lines[3]);
  int fd = $fopen(file_path, "r");
  int part_idx;
  string line;
  string all_lines[$];
  int total_lines;
  int lines_per_part ;  // 向上取整划分3组
  int idx;
  if (fd == 0) begin
    `uvm_fatal("COMPARE", $sformatf("Failed to open golden file: %s", file_path));
  end

  // 读取所有行
  while (!$feof(fd)) begin
    if ($fgets(line, fd)) begin
      if (line.len() > 0) begin
        all_lines.push_back(line);
      end
    end
  end
  $fclose(fd);

  total_lines = all_lines.size();

  // 检查总行数是否匹配
  if ((part_lines[0] + part_lines[1] + part_lines[2]) != total_lines) begin
    `uvm_fatal("COMPARE", $sformatf("Line count mismatch: expected %0d, got %0d",
                                    part_lines[0] + part_lines[1] + part_lines[2],
                                    total_lines));
  end

  // 清空之前的数据，防止重复调用时数据累积
  for (int i = 0; i < 3; i++) begin
    golden_lines[i].delete();
  end

  // 分配数据到各个 part
  idx = 0;
  for (int part = 0; part < 3; part++) begin
    for (int i = 0; i < part_lines[part]; i++) begin
      golden_lines[part].push_back(all_lines[idx]);
      idx++;
    end
  end

  `uvm_info("COMPARE", $sformatf("Loaded %0d lines from %s: part0=%0d, part1=%0d, part2=%0d",
    total_lines, file_path, golden_lines[0].size(), golden_lines[1].size(), golden_lines[2].size()), UVM_LOW);
    foreach (golden_lines[part_idx]) begin
      for (int part_idx = 0; part_idx < 3; part_idx++) begin
        `uvm_info("GOLDEN_DUMP", $sformatf("------ GOLDEN PART %0d ------", part_idx), UVM_LOW);
        foreach (golden_lines[part_idx][line_idx]) begin
          string line_str = golden_lines[part_idx][line_idx];
          `uvm_info("GOLDEN_DUMP", $sformatf("part%0d line %0d: %s", part_idx, line_idx, line_str), UVM_MEDIUM);
        end
      end
    end

endfunction

function void compare_to_golden(int part, int group_widths[$]);
  bit dut_bits[$];        // DUT数据位数组，高位在前
  bit dut_bits_rev[$];
  bit golden_bits[$];     // golden数据位数组，低位在前（整体顺序）
  bit [255:0] temp_data;
  int bit_len;
  int dut_idx;
  int golden_idx;
  int mismatch_idx;
  int group_size;
  int i, b;
  bit db, gb;
  string hex_str;
  string dut_bin, golden_bin, marker_line;
  string dut_hex, golden_hex;
  string line;
  string dut_bits_str;
  data_unit_t item;
  bit [255:0] dut_val;
  bit [255:0] golden_val;
  string temp_data_bin;
  int mismatch_from_right;
  int drop_bits;

  // 1. 收集 DUT bits（高位在前）
  dut_bits.delete();
  for (i = 0; i < data_q_all[part].size(); i++) begin
    item = data_q_all[part].get(i);
    for (b = item.width - 1; b >= 0; b--) begin
      dut_bits.push_back(item.data[b]);
    end
  end
  for (i = dut_bits.size() - 1; i >= 0; i--) begin
    dut_bits_rev.push_back(dut_bits[i]);
  end
  `uvm_info("DEBUG", $sformatf("DUT bits size=%0d for part%0d", dut_bits.size(), part), UVM_LOW);

  dut_bits_str = "";
  for (i = 0; i < dut_bits.size(); i++) begin
    dut_bits_str = {dut_bits_str, $sformatf("%0b", dut_bits[i])};
  end
  `uvm_info("DUT_BITS", $sformatf("part%0d: DUT bits (high bit first): %s", part, dut_bits_str), UVM_MEDIUM)
  // 2. 收集 golden bits（低位在前，push_front）
  golden_bits.delete();
  for (i = 0; i < golden_lines[part].size(); i++) begin
    line = trim_string(golden_lines[part][i]);
    if (line.len() >= 2 && (line.substr(0,1) == "0x" || line.substr(0,1) == "0X"))
      hex_str = trim_string(line.substr(2));
    else
      hex_str = line;
      `uvm_info("DEBUG", $sformatf("Raw line[%0d]: '%s'", i, golden_lines[part][i]), UVM_MEDIUM);
      `uvm_info("DEBUG", $sformatf("Trimmed line[%0d]: '%s'", i, line), UVM_MEDIUM);


    temp_data = 0;
    if (!$sscanf(hex_str, "%h", temp_data)) begin
      `uvm_info("GOLDEN_PARSE", $sformatf("Cannot parse golden hex string at part%0d, line %0d: %s", part, i, line), UVM_LOW)
      continue;
    end

    bit_len = hex_str.len() * 4;

    `uvm_info("GOLDEN_INFO", $sformatf(
  "line %0d: hex_str.len()=%0d, bit_len=%0d, hex_str=%s", 
  i, hex_str.len(), bit_len, hex_str), UVM_MEDIUM)
    temp_data_bin = "";
    for (b = bit_len - 1; b >= 0; b--) temp_data_bin = {temp_data_bin, $sformatf("%0b", temp_data[b])};
    `uvm_info("TEMP_DATA_BIN", $sformatf("part%0d line %0d temp_data bits (MSB->LSB): %s", part, i, temp_data_bin), UVM_MEDIUM);

    // 低位放前面
    for (b = 0; b < bit_len; b++) begin
      golden_bits.push_front(temp_data[b]);  // 低位优先，从前插入
    end
  end

  `uvm_info("DEBUG", $sformatf("Golden bits size=%0d for part%0d", golden_bits.size(), part), UVM_MEDIUM);

  // 1. 获取 e_size 和 l_size
  case (part)
    0: drop_bits = vif.ics_part0_e_size - vif.ics_part0_l_size;
    1: drop_bits = vif.ics_part1_e_size - vif.ics_part1_l_size;
    2: drop_bits = vif.ics_part2_e_size - vif.ics_part2_l_size;
    default: begin
      `uvm_fatal("INVALID_PART", $sformatf("Unsupported part: %0d", part));
    end
  endcase

  `uvm_info("DEBUG", $sformatf("Dropping last %0d bits for part%0d", drop_bits, part), UVM_LOW);

  // 2. 从尾部删除 drop_bits 个比特
  for (int i = 0; i < drop_bits; i++) begin
    if (!golden_bits.empty())
      golden_bits.pop_back();
    if (!dut_bits_rev.empty())
      dut_bits_rev.pop_back();
  end

  // 3. 校验长度
  if (dut_bits_rev.size() != golden_bits.size()) begin
    `uvm_info("BITLEN_MISMATCH", $sformatf(
      "DUT bit count (%0d) != golden bit count (%0d) for part%0d",
      dut_bits_rev.size(), golden_bits.size(), part), UVM_LOW)
  end

  // 4. 分组比较，从低位开始（即从尾部采集）
  dut_idx = dut_bits_rev.size() - 1;
  golden_idx = golden_bits.size() - 1;

  for (i = 0; i < group_widths.size(); i++) begin
    group_size = group_widths[i];
    mismatch_idx = -1;

    if ((dut_idx - group_size + 1 < 0) || (golden_idx - group_size + 1 < 0)) begin
      `uvm_warning("GROUP_SIZE", $sformatf(
        "Not enough bits for part%0d group %0d (size %0d)", part, i, group_size))
    end

    dut_bin = "";
    golden_bin = "";
    marker_line = "";

    dut_val = 0;
    golden_val = 0;

    // 从低位往高位收集并构建 binary string 和 hex 值
    for (b = group_size - 1; b >= 0; b--) begin
      db = dut_bits_rev[dut_idx - b];
      gb = golden_bits[golden_idx - b];

      dut_bin = {dut_bin, $sformatf("%0b", db)};
      golden_bin = {golden_bin, $sformatf("%0b", gb)};
      dut_val = (dut_val << 1) | db;
      golden_val = (golden_val << 1) | gb;
    end

    // mismatch 检查从低位到高位
    for (b = group_size - 1; b >= 0; b--) begin
      db = dut_bits_rev[dut_idx - (group_size - 1) + b];
      gb = golden_bits[golden_idx - (group_size - 1) + b];
      if (mismatch_idx == -1 && db !== gb)
        mismatch_idx = b;  // 从右边开始查找到的那个索引，仍是高位起的偏移
    end
    mismatch_from_right = group_size - 1 - mismatch_idx;
    dut_hex    = $sformatf("0x%0h", dut_val);
    golden_hex = $sformatf("0x%0h", golden_val);

    if (mismatch_idx != -1) begin
      for (b = 0; b < group_size; b++) begin
         if (b == mismatch_idx)
           marker_line = {marker_line, "^"};
         else
           marker_line = {marker_line, " "};
       end

      `uvm_info("BIT_GROUP_COMPARE", $sformatf(
        "part%0d Group %0d (%0d bits):\n  MISMATCH at bit %0d (from right)\n  exp: %s\n  act: %s\n       %s\n  exp: %s\n  act: %s",
        part, i, group_size, mismatch_from_right,
        golden_bin, dut_bin, marker_line,
        golden_hex, dut_hex), UVM_LOW)
    end else begin
      `uvm_info("BIT_GROUP_COMPARE", $sformatf(
        "part%0d Group %0d (%0d bits):\n  exp: %s\n  act: %s\n  exp: %s\n  act: %s",
        part, i, group_size,
        golden_bin, dut_bin,
        golden_hex, dut_hex), UVM_LOW)
    end

    // 向高位推进
    dut_idx    -= group_size;
    golden_idx -= group_size;
  end
endfunction



function string right_align(string s, int target_len);
    int pad_len;
    string padded;
    pad_len = target_len - s.len();
    if (pad_len > 0)
        padded = {repeat_space(pad_len), s};
    else
        padded = s;
    return padded;
endfunction


function string repeat_space(int n);
    string s = "";
    for (int i = 0; i < n; i++) begin
        s = {s, " "};
    end
    return s;
endfunction

function string trim_string(string str);
  int start_idx = 0;
  int end_idx = str.len() - 1;
  // 从左侧跳过空白字符
  while (start_idx <= end_idx && (str[start_idx] == " " || str[start_idx] == "\t" || str[start_idx] == "\n" || str[start_idx] == "\r")) begin
    start_idx++;
  end
  // 从右侧跳过空白字符
  while (end_idx >= start_idx && (str[end_idx] == " " || str[end_idx] == "\t" || str[end_idx] == "\n" || str[end_idx] == "\r")) begin
    end_idx--;
  end
  if (start_idx > end_idx) return "";
  return str.substr(start_idx, end_idx);
endfunction

endclass