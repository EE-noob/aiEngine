// ============================================================
// Memory Model Class
// ============================================================
class memory_model #(parameter ADDR_W=32, DATA_W=32);//>>>
  bit [7:0] mem[bit[ADDR_W-1:0]];  // Sparse memory array
  string name;
  
  function new(string n="memory");
    name = n;
  endfunction
  
  // Write byte
  function void write_byte(bit [ADDR_W-1:0] addr, bit [7:0] data);
    mem[addr] = data;
    `ifdef DEBUG_MEM
    $display("[%s] Write: addr=0x%08h, data=0x%02h", name, addr, data);
    `endif
  endfunction
  
  // Read byte
  function bit [7:0] read_byte(bit [ADDR_W-1:0] addr);
    if (!mem.exists(addr)) begin
      mem[addr] = 8'hxx;  // Uninitialized memory
    end
    `ifdef DEBUG_MEM
    $display("[%s] Read: addr=0x%08h, data=0x%02h", name, addr, mem[addr]);
    `endif
    return mem[addr];
  endfunction
  
  // Write word with mask
  function void write_word(bit [ADDR_W-1:0] addr, bit [DATA_W-1:0] data, bit [DATA_W/8-1:0] mask);
    for (int i = 0; i < DATA_W/8; i++) begin
      if (mask[i]) begin
        write_byte(addr + i, data[i*8 +: 8]);
      end
    end
  endfunction
  
  // Read word
  function bit [DATA_W-1:0] read_word(bit [ADDR_W-1:0] addr);
    bit [DATA_W-1:0] data;
    for (int i = 0; i < DATA_W/8; i++) begin
      data[i*8 +: 8] = read_byte(addr + i);
    end
    return data;
  endfunction
  
  // Write halfword (16-bit)
  function void write_halfword(bit [ADDR_W-1:0] addr, bit [15:0] data);
    write_byte(addr, data[7:0]);
    write_byte(addr + 1, data[15:8]);
  endfunction
  
  // Read halfword (16-bit)
  function bit [15:0] read_halfword(bit [ADDR_W-1:0] addr);
    bit [15:0] data;
    data[7:0] = read_byte(addr);
    data[15:8] = read_byte(addr + 1);
    return data;
  endfunction
  
  // Compare with another memory
  function int compare(memory_model #(ADDR_W, DATA_W) other);
    int mismatches = 0;
    bit [ADDR_W-1:0] addr_list[$];
    
    // Collect all addresses from both memories
    foreach(this.mem[addr])
      if (!(addr inside {addr_list}))
        addr_list.push_back(addr);
    
    foreach(other.mem[addr])
      if (!(addr inside {addr_list}))
        addr_list.push_back(addr);
    
    // Compare each address
    foreach(addr_list[i]) begin
      bit [7:0] data1, data2;
      data1 = this.mem.exists(addr_list[i]) ? this.mem[addr_list[i]] : 8'hxx;
      data2 = other.mem.exists(addr_list[i]) ? other.mem[addr_list[i]] : 8'hxx;
      
      if (data1 !== data2 && data1 !== 8'hxx && data2 !== 8'hxx) begin
        $display("[MEM_COMPARE] Mismatch at 0x%08h: %s=0x%02h, %s=0x%02h", 
                 addr_list[i], this.name, data1, other.name, data2);
        mismatches++;
      end
    end
    
    return mismatches;
  endfunction
  
  // Clear memory
  function void clear();
    mem.delete();
  endfunction
  
  // Display memory contents
  function void display_contents();
    bit [ADDR_W-1:0] addr_list[$];
    
    foreach(mem[addr])
      addr_list.push_back(addr);
    
    addr_list.sort();
    
    $display("[%s] Memory Contents:", name);
    foreach(addr_list[i]) begin
      $display("  0x%08h: 0x%02h", addr_list[i], mem[addr_list[i]]);
    end
  endfunction
endclass
//<<<