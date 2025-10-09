class ics_monitor extends uvm_component;
  `uvm_component_utils(ics_monitor)

  // 接口句柄
  virtual ics_if vif;

  // golden 数据
  string golden_file = `ICS_OUTPUT_DATA;
  bit [119:0] golden_data[$];  // 动态数组保存所有golden值

  // 当前采集的index
  int data_idx = 0;

  covergroup ics_cov;
    option.per_instance = 1;

    coverpoint {vif.ics_part2_en, vif.ics_part1_en, vif.ics_part0_en} {
      bins part0_only = {3'b001};
      bins part1_only = {3'b010};
      bins part2_only = {3'b100};
      bins part0_1    = {3'b011};
      bins part0_2    = {3'b101};
      bins part1_2    = {3'b110};
      bins all_parts  = {3'b111};
    }

    coverpoint vif.ics_part0_n_size {
      bins n_vals[] = {32, 64, 128, 256, 512, 1024};
    }

    coverpoint vif.ics_part1_n_size {
      bins n_vals[] = {32, 64, 128, 256, 512, 1024};
    }

    coverpoint vif.ics_part2_n_size {
      bins n_vals[] = {32, 64, 128, 256, 512, 1024};
    }

    coverpoint vif.ics_q_size {
      bins q_vals[] = {1, 2, 4, 6, 8, 10};
    }

    // 交叉覆盖：每个 n_size 与 q_size（分别）
    cross vif.ics_part0_n_size, vif.ics_q_size;
    cross vif.ics_part1_n_size, vif.ics_q_size;
    cross vif.ics_part2_n_size, vif.ics_q_size;
  endgroup

  // 构造函数
  function new(string name, uvm_component parent);
    super.new(name, parent);
    ics_cov = new();
  endfunction

  // 读取 golden 文件内容
  function void read_golden_file();
    int fd;
    string line;
    bit [119:0] value;
    fd = $fopen(golden_file, "r");
    if (fd == 0) begin
      `uvm_fatal("ICS_MON", $sformatf("Cannot open golden file: %s", golden_file))
    end
    while (!$feof(fd)) begin
      line = "";
      void'($fgets(line, fd));
      if (line.len() > 0) begin
        void'($sscanf(line, "%h", value));
        golden_data.push_back(value);
      end
    end
    $fclose(fd);
    `uvm_info("ICS_MON", $sformatf("Loaded %0d golden entries", golden_data.size()), UVM_MEDIUM)
  endfunction

  // build_phase：读取golden文件
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual ics_if)::get(this, "", "ics_vif", vif)) begin
      `uvm_fatal("ICS_MON", "Failed to get vif")
    end
    read_golden_file();
  endfunction

  // run_phase：每拍采集 DUT 输出并比对
  task run_phase(uvm_phase phase);
    bit all_match = 1;
    int cycle_counter = 0;
    bit start_count = 0;
    int mon_timeout_ns;

    phase.raise_objection(this);
    @(posedge vif.clk);  // 等待第一个时钟上升沿

    fork
      begin
          mon_timeout_ns = 100000000;
          #(mon_timeout_ns);
          print_fail_ascii();
          `uvm_fatal(get_full_name(), $sformatf("Simulation Time too long for %0dns", mon_timeout_ns))
      end
    join_none

    // 收集覆盖率
    fork
      begin
        forever begin
          @(posedge vif.clk);
          if (vif.ics_start) begin
            ics_cov.sample();  // 采样所有 coverpoint & cross
          end
        end
      end
    join_none

    forever begin
      @(posedge vif.clk);

      // 启动后开始计数
      if (vif.ics_start && !start_count) begin
        start_count = 1;
        cycle_counter = 0;
        `uvm_info("ICS_MON", "Start signal detected. Begin counting cycles.", UVM_MEDIUM)
      end

      if (start_count)
        cycle_counter++;

      if (vif.ics_out_vld) begin
        bit [119:0] dut_data = vif.ics_out_data;

        if (data_idx >= golden_data.size()) begin
          `uvm_info("ICS_MON", $sformatf("Extra DUT output: %h", dut_data), UVM_LOW)
          all_match = 0;
        end else begin
          if (dut_data !== golden_data[data_idx]) begin
            `uvm_info("ICS_MON", $sformatf("Mismatch at index %0d: \nDUT=%h, \nGLD=%h", 
                  data_idx, dut_data, golden_data[data_idx]), UVM_LOW)
            all_match = 0;
          end else begin
            `uvm_info("ICS_MON", $sformatf("Match at index %0d: %h", data_idx, dut_data), UVM_LOW)
          end
        end
        data_idx++;
      end
      `uvm_info("ICS_MON", $sformatf("ics_out_eof is %b, data_idx is %d, golden_data_size is %d", 
          vif.ics_out_eof, data_idx, golden_data.size()), UVM_MEDIUM)

      //if (vif.ics_out_eof && data_idx >= golden_data.size()) begin //有时候data收不满，导致data_idx收不够，使得无法Drop Objection
      if (vif.ics_out_eof) begin
        if (data_idx < golden_data.size() || cycle_counter > 2500) begin
            all_match = 0;
        end
        `uvm_info("ICS_MON", $sformatf("Total cycles from ics_start to eof: %0d", cycle_counter), UVM_LOW)
        if (all_match) begin
          `uvm_info("ICS_MON", "All data compared successfully.", UVM_LOW)
          print_pass_ascii();
        end else begin
          if (data_idx < golden_data.size()) begin 
            `uvm_error("ICS_MON", $sformatf("Collect Data is not enough, Collect:%d, Exp:%d",data_idx, golden_data.size()))
          end else if (cycle_counter > 2500) begin
            `uvm_error("ICS_MON", $sformatf("The Counter value is too long, Counter Value:%d",cycle_counter))            
          end else begin
            `uvm_error("ICS_MON", "Data mismatch detected. Test FAILED.")
          end
          print_fail_ascii();
        end
        break;
      end
    end

    `uvm_info(get_full_name(), "Drop objection", UVM_LOW);
    phase.drop_objection(this);
  endtask

task print_pass_ascii();
    static string PASS_ASCII[$] = '{
        "██████╗  █████╗ ███████╗███████╗",
        "██╔══██╗██╔══██╗██╔════╝██╔════╝",
        "██████╔╝███████║███████╗███████╗",
        "██╔═══╝ ██╔══██║╚════██║╚════██║",
        "██║     ██║  ██║███████║███████║",
        "╚═╝     ╚═╝  ╚═╝╚══════╝╚══════╝"
    };

    foreach (PASS_ASCII[i]) begin
        `uvm_info("ICS_PASS", PASS_ASCII[i], UVM_LOW)
    end
endtask

    static string FAIL_ASCII[$]= '{
        "███████╗ █████╗ ██╗██╗     ",
        "██╔════╝██╔══██╗██║██║     ",
        "███████╗███████║██║██║     ",
        "██╔════╝██╔══██║██║██║     ",
        "██║     ██║  ██║██║███████╗",
        "╚═╝     ╚═╝  ╚═╝╚══════╝"
    };

function void print_fail_ascii();
    foreach (FAIL_ASCII[i])
        `uvm_info("ASCII_FAIL", FAIL_ASCII[i], UVM_NONE)
endfunction

endclass