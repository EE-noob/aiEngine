`ifndef i2c_mon_COVERAGE__SV
`define i2c_mon_COVERAGE__SV
class i2c_mon_coverage extends uvm_object;

    i2c_mon_tr              tr;

    //todo: add covergroup to get function coverage
    //covergroup i2c_mon_tr_cg;
    //    option.per_instance=1;
    //    cov_full_addr: coverpoint tr.address
    //    {
    //        bins lo = {0};
    //        bins hi = {255};
    //    }
    //endgroup

    //function new(string name);
    //    i2c_mon_tr_cg=new();
    //    i2c_mon_tr_cg.set_inst_name("i2c_mon_tr_cg");
    //endfunction

    //virtual function void sample_tr(i2c_mon_tr tr);
    //    this.tr = tr;
    //    i2c_mon_tr_cg.sample();
    //endfunction
    
endclass
`endif
