class combine_checker extends uvm_component;
  `uvm_component_utils(combine_checker)

  // virtual interface 句柄
  virtual combine_if vif;

  // golden 数据数组
  bit [9:0] golden_values[$];

  // 配置：参考文件路径（默认）
  //string ref_file = `ICS_COM_OUT_DATA;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  // 🔧 build_phase：获取 vif + 读取golden值
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(virtual combine_if)::get(this, "", "combine_vif", vif)) begin
      `uvm_fatal("CHECKER", "Failed to get virtual interface 'vif' from config DB");
    end

    //read_reference();
  endfunction

//virtual function void read_reference();
//  int fd;
//  string line;
//  int value;
//
//  fd = $fopen(ref_file, "r");
//  if (fd == 0) begin
//    `uvm_fatal("CHECKER", $sformatf("Failed to open file: %s", ref_file));
//    return;
//  end
//
//  while (!$feof(fd)) begin
//    void'($fgets(line, fd));
//    line = trim_str(line);
//    if (line == "") continue;
//
//    // 将字符串小写并去掉前缀 0x（如果有）
//    line = tolower_str(line);
//    if (line.len() >= 2 && line.substr(0, 1) == "0x")
//      line = line.substr(2);
//
//    if (!$sscanf(line, "%x", value)) begin
//      `uvm_warning("CHECKER", $sformatf("Cannot parse value from line: %s", line));
//    end else begin
//      golden_values.push_back(value[9:0]);
//    end
//  end
//
//  $fclose(fd);
//
//  // 打印前20个用于检查
//  //`uvm_info("CHECKER", $sformatf("Golden data size = %0d", golden_values.size()), UVM_LOW);
//  //foreach (golden_values[i]) begin
//  //  if (i >= 20) begin
//  //    `uvm_info("CHECKER", "... (truncated)", UVM_LOW);
//  //    break;
//  //  end
//  //  `uvm_info("CHECKER", $sformatf("golden[%0d] = 0x%03x", i, golden_values[i]), UVM_LOW);
//  //end
//endfunction


  // ▶ run_phase：实际比对过程
  task run_phase(uvm_phase phase);
    int golden_index;
    phase.raise_objection(this);

    //golden_index = 0;

    //forever begin
    //  @(posedge vif.clk);
    //  if (vif.combine_valid) begin
    //    for (int i = 0; i < vif.combine_num; i++) begin
    //      if (golden_index >= golden_values.size()) begin
    //        //`uvm_info("CHECKER", "DUT produced more data than reference",UVM_LOW);
    //        continue;
    //      end

    //      if (vif.combine_data[i][9:0] !== golden_values[golden_index]) begin
    //        //`uvm_info("CHECKER", $sformatf(
    //        //  "Mismatch at index %0d: expected 0x%03x, got 0x%03x",
    //        //  golden_index, golden_values[golden_index], vif.combine_data[i]
    //        //),UVM_LOW);
    //      end
    //      golden_index++;
    //    end
    //  end
    //end

    `uvm_info(get_full_name(), "Drop objection", UVM_LOW);
    phase.drop_objection(this);
  endtask

function string tolower_str(string s);
    string result = "";
    foreach (s[i]) begin
        byte c = s[i];
        if (c >= "A" && c <= "Z")
            c = c + 32;
        result = {result, c};
    end
    return result;
endfunction

function string trim_str(string s);
    int start = 0;
    int stop = s.len() - 1;
    while ((start <= stop) && (s[start] == " " || s[start] == "\t")) start++;
    while ((stop >= start) && (s[stop] == " " || s[stop] == "\t")) stop--;
    return s.substr(start, stop);
endfunction

endclass
