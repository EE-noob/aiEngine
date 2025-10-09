// -------------------------
// filo_env_if.sv
// -------------------------
interface filo_env_if(input logic clk);

  // DUT 信号定义（保持原命名风格）
  logic part0_filoA_rdA_en, part0_filoB_rdA_en;
  logic part1_filoA_rdA_en, part1_filoB_rdA_en;
  logic part2_filoA_rdA_en, part2_filoB_rdA_en;

  logic part0_filoA_rdB_en, part0_filoB_rdB_en;
  logic part1_filoA_rdB_en, part1_filoB_rdB_en;
  logic part2_filoA_rdB_en, part2_filoB_rdB_en;

  logic part0_filoA_rd1_en, part0_filoB_rd1_en;
  logic part1_filoA_rd1_en, part1_filoB_rd1_en;
  logic part2_filoA_rd1_en, part2_filoB_rd1_en;

  logic [9:0] part0_filoA_rdA_data, part0_filoB_rdA_data;
  logic [9:0] part1_filoA_rdA_data, part1_filoB_rdA_data;
  logic [9:0] part2_filoA_rdA_data, part2_filoB_rdA_data;

  logic [3:0] part0_filoA_rdB_data, part0_filoB_rdB_data;
  logic [3:0] part1_filoA_rdB_data, part1_filoB_rdB_data;
  logic [3:0] part2_filoA_rdB_data, part2_filoB_rdB_data;

  logic part0_filoA_rd1_data, part0_filoB_rd1_data;
  logic part1_filoA_rd1_data, part1_filoB_rd1_data;
  logic part2_filoA_rd1_data, part2_filoB_rd1_data;

  logic part0_filoA_rdy4rd, part0_filoB_rdy4rd;
  logic part1_filoA_rdy4rd, part1_filoB_rdy4rd;
  logic part2_filoA_rdy4rd, part2_filoB_rdy4rd;

  logic [$clog2(128+1)-1:0] part0_filoA_cnt;
  logic [$clog2(128+1)-1:0] part0_filoB_cnt;
  logic [$clog2(128+1)-1:0] part1_filoA_cnt;
  logic [$clog2(128+1)-1:0] part1_filoB_cnt;
  logic [$clog2(128+1)-1:0] part2_filoA_cnt;
  logic [$clog2(128+1)-1:0] part2_filoB_cnt;
  //Wait this signal for compare
  logic combine_eof;

  //support E-L operation
  logic [13:0] ics_part0_e_size;
  logic [13:0] ics_part0_l_size;
  logic [13:0] ics_part1_e_size;
  logic [13:0] ics_part1_l_size;
  logic [13:0] ics_part2_e_size;
  logic [13:0] ics_part2_l_size;

  // 封装访问方法
  function logic get_cnt(int part, int fifo);
    case (part*2 + fifo)
      0: return part0_filoA_cnt;
      1: return part0_filoB_cnt;
      2: return part1_filoA_cnt;
      3: return part1_filoB_cnt;
      4: return part2_filoA_cnt;
      5: return part2_filoB_cnt;
      default: return 1'b0;
    endcase
  endfunction

  function logic get_rdy4rd(int part, int fifo);
    case (part*2 + fifo)
      0: return part0_filoA_rdy4rd;
      1: return part0_filoB_rdy4rd;
      2: return part1_filoA_rdy4rd;
      3: return part1_filoB_rdy4rd;
      4: return part2_filoA_rdy4rd;
      5: return part2_filoB_rdy4rd;
      default: return 1'b0;
    endcase
  endfunction

  task set_rdA_en(int part, int fifo, logic val);
    case (part*2 + fifo)
      0: part0_filoA_rdA_en = val;
      1: part0_filoB_rdA_en = val;
      2: part1_filoA_rdA_en = val;
      3: part1_filoB_rdA_en = val;
      4: part2_filoA_rdA_en = val;
      5: part2_filoB_rdA_en = val;
    endcase
  endtask

  task set_rdB_en(int part, int fifo, logic val);
    case (part*2 + fifo)
      0: part0_filoA_rdB_en = val;
      1: part0_filoB_rdB_en = val;
      2: part1_filoA_rdB_en = val;
      3: part1_filoB_rdB_en = val;
      4: part2_filoA_rdB_en = val;
      5: part2_filoB_rdB_en = val;
    endcase
  endtask

  task set_rd1_en(int part, int fifo, logic val);
    case (part*2 + fifo)
      0: part0_filoA_rd1_en = val;
      1: part0_filoB_rd1_en = val;
      2: part1_filoA_rd1_en = val;
      3: part1_filoB_rd1_en = val;
      4: part2_filoA_rd1_en = val;
      5: part2_filoB_rd1_en = val;
    endcase
  endtask

  function logic [9:0] get_rdA_data(int part, int fifo);
    case (part*2 + fifo)
      0: return part0_filoA_rdA_data;
      1: return part0_filoB_rdA_data;
      2: return part1_filoA_rdA_data;
      3: return part1_filoB_rdA_data;
      4: return part2_filoA_rdA_data;
      5: return part2_filoB_rdA_data;
      default: return '0;
    endcase
  endfunction

  function logic [3:0] get_rdB_data(int part, int fifo);
    case (part*2 + fifo)
      0: return part0_filoA_rdB_data;
      1: return part0_filoB_rdB_data;
      2: return part1_filoA_rdB_data;
      3: return part1_filoB_rdB_data;
      4: return part2_filoA_rdB_data;
      5: return part2_filoB_rdB_data;
      default: return '0;
    endcase
  endfunction

  function logic get_rd1_data(int part, int fifo);
    case (part*2 + fifo)
      0: return part0_filoA_rd1_data;
      1: return part0_filoB_rd1_data;
      2: return part1_filoA_rd1_data;
      3: return part1_filoB_rd1_data;
      4: return part2_filoA_rd1_data;
      5: return part2_filoB_rd1_data;
      default: return '0;
    endcase
  endfunction

endinterface