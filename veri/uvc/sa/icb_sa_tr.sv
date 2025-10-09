`include "uvm_macros.svh"
import uvm_pkg::*;
class icb_cmd_tr extends uvm_sequence_item;

  // -------- Fields --------
  rand bit [31:0] addr;
  rand bit        read;        // 1=读, 0=写
  rand bit [2:0]  len;         // 实际拍数 = len + 1, 范围 0..7
  rand bit [31:0] wdata[];     // 仅写事务使用（拍数 = len+1）
  rand bit [3:0]  wmask;       // 若需要每拍不同掩码可改为数组

  // -------- Factory & automation --------
  `uvm_object_utils_begin(icb_cmd_tr)
    `uvm_field_int       (addr , UVM_ALL_ON)
    `uvm_field_int       (read , UVM_ALL_ON)
    `uvm_field_int       (len  , UVM_ALL_ON)
    `uvm_field_array_int (wdata, UVM_ALL_ON)   // 动态数组用这个宏
    `uvm_field_int       (wmask, UVM_ALL_ON)
  `uvm_object_utils_end

  // -------- Constraints --------
  // len ∈ [0..7]（3bit自然满足，这里写明白语义）
  constraint c_len_range { len inside {[0:7]}; }

  // 写：wdata.size = len + 1；读：不需要 wdata（size=0）
  constraint c_wdata_size {
    if (read) wdata.size() == 0;
    else      wdata.size() == (len + 1);
  }

  // 写时掩码非0，避免无效写
  constraint c_wmask_non_zero {
    if (!read) wmask != 4'b0000;
  }

  // （可选）引导产生各种非对齐
  constraint c_addr_soft { soft addr[1:0] inside {2'b00,2'b01,2'b10,2'b11}; }

  function new(string name="icb_cmd_tr");
    super.new(name);
  endfunction

  // -------- Pretty print --------
  virtual function void do_print (uvm_printer printer);
    super.do_print(printer);
    printer.print_field_int("addr" , addr , 32, UVM_HEX);
    printer.print_field_int("read" , read , 1 ,  UVM_DEC);
    printer.print_field_int("len"  , len  , 3 ,  UVM_DEC);
    printer.print_field_int("beats", (len+1), 4, UVM_DEC);
    printer.print_field_int("wmask", wmask, 4 ,  UVM_BIN);
    if (!read) begin
      foreach (wdata[i])
        printer.print_field_int($sformatf("wdata[%0d]", i), wdata[i], 32, UVM_HEX);
    end
  endfunction

endclass : icb_cmd_tr
