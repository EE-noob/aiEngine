
// ============================================================
// Transaction Class Definition
// ============================================================
class icb_transaction;//>>>
parameter ICB_LEN_W = 4;
// Fields
rand bit [31:0] addr;
rand bit        read;        // 1=read, 0=write
rand bit [ICB_LEN_W-1:0]  len;         // actual beats = len + 1
rand bit [31:0] wdata[];     // write data array
rand bit [3:0]  wmask[];     // write mask array, one per beat

// Response fields
bit [31:0] rdata[];           // read data array
bit        err;               // error flag

// Constraints
// constraint c_len_range { 
//   len inside {[0:2**ICB_LEN_W-1]}; 
// }

constraint c_wdata_size {
  if (read) { 
    wdata.size() == 0;
    wmask.size() == 0;
  } else {
    wdata.size() == (len + 1);
    wmask.size() == (len + 1);
  }
}

constraint c_wmask_non_zero {
  if (!read) {
    foreach(wmask[i])
      wmask[i] != 4'b0000;
  }
}

// Soft constraint for various alignments
constraint c_addr_align { 
  soft addr[1:0] inside {2'b00, 2'b01, 2'b10, 2'b11}; 
}

// Constructor
function new(string name="icb_transaction");
endfunction

// Display function
function void display(string prefix="");
  $display("%s[%0t] %s Transaction:", prefix, $time, read ? "READ" : "WRITE");
  $display("%s  addr=0x%08h, len=%0d (beats=%0d)", prefix, addr, len, len+1);
  if (!read) begin
    foreach (wdata[i])
      $display("%s  wdata[%0d]=0x%08h, wmask[%0d]=%04b", prefix, i, wdata[i], i, wmask[i]);
  end 
  // else if (rdata.size() > 0) begin
  //   foreach (rdata[i])
  //     $display("%s  rdata[%0d]=0x%08h", prefix, i, rdata[i]);
  // end
endfunction

// Copy function
function icb_transaction copy();
  icb_transaction tr = new();
  tr.addr = this.addr;
  tr.read = this.read;
  tr.len = this.len;
  tr.wdata = new[this.wdata.size()];
  tr.wmask = new[this.wmask.size()];
  foreach(this.wdata[i])
    tr.wdata[i] = this.wdata[i];
  foreach(this.wmask[i])
    tr.wmask[i] = this.wmask[i];
  return tr;
endfunction
endclass
//<<<