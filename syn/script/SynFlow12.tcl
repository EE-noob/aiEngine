#--------------------------Specify Libraries--------------------------
#set DESIGN_PATH  /home/ic_libs/TSMC.90/aci/sc-x/syn_qmhopsys
set DESIGN_PATH /mnt/hgfs/vmshare/Tech_Lib/TSMC12nm/T12/lib
#/opt/PDKs/smic_180/SM00LB501-FE-00000-r0p0-00rel0/aci/sc-m/syn_qmhopsys 
set search_path "$search_path $DESIGN_PATH"
#set target_library "typical.db"
set target_library   "tcbn12ffcllbwp16p90cpdffgnp0p6v0c_ccs.db"
set link_library "tcbn12ffcllbwp16p90cpdffgnp0p6v0c_ccs.db"
#set link_library "* $target_library /home/ic_libs/TSMC.90/aci/sram_dp_adv/bin/SRAM_512x32_tt_syn_qmh.db"
#link_library是链接库，它是DC在解释综合后网表时用来参考的库。一般情况下，它和目标库相同；当使用综合库时，需要将该综合库加入链接库列表中。　设置时，需要加“*”，表示内存中的所有库。**“表示 DC 在引用实例化模块 或者单元电路时首先搜索已经调进DC memory的模块和单元电路，如果在link library 中不包含” * "，DC 就不会使用 DC memory 中已有的模块，因此，会出现无法匹配的模块或单元电路的警告信息(unresolved design reference)。
echo "\n\nSettings:"
echo "search_path: $search_path"
echo "link_library: $link_library"
echo "target_library: $target_library"
echo "\n\n***Specify libraries Ready***"
#set search_path "$TAR_PATH $MEM_LINK_PATH"

#--------------------------Prepare Filelist---------------------------
set FILE_LIST "rtl_list.f"

#!/usr/bin/tclsh

# 文件路径
set source_file "../../sim/rtl_list.f"
set dest_file "rtl_list.f"

# 复制文件到当前目录
if {[catch {
    set in_fd [open $source_file r]
    set out_fd [open $dest_file w]
    
    # 逐行读取源文件
    while {[gets $in_fd line] >= 0} {
        # 跳过空行，对非空行添加前缀
        if {[string trim $line] != ""} {
            puts $out_fd "../$line"
        } else {
            puts $out_fd $line
        }
    }
    
    # 关闭文件
    close $in_fd
    close $out_fd
    
    puts "成功复制并修改了文件。结果保存在 $dest_file"
} error_msg]} {
    puts "发生错误: $error_msg"
}

#--------------------------Read Designs------------------------------
set hdlin_for_loop_iterations   1200000
set hdlin_while_loop_iterations 1200000
#resto 在解析 常量循环（for/while/repeat）时，会把它们全部迭代完才能生成硬件；为防止死循环，syn_qmhopsys 在变量 hdlin_for_loop_iterations 和 hdlin_while_loop_iterations 中放了一个默认值（旧版本 256，新版 8191），超过就直接报 “Loop exceeded maximum iteration limit (ELAB-900)” 

#set TOP_DESIGN crc_64p
#set TOP_DESIGN triangleSR
#set TOP_DESIGN ics_top 
set TOP_DESIGN combine_top 
#set TOP_DESIGN intlv_top 
#set TOP_DESIGN calcP
analyze -format sverilog -vcs "-f $FILE_LIST"
#file list 是vcs格式的
elaborate $TOP_DESIGN


#------------------------Set Current Design&&Link Designs--------------------------
current_design $TOP_DESIGN
link
uniquify
#对于被多次实例化的同一子设计，由于其例化后的工作环境各不相同，因此，需要用 uniquify 命令为每个实例在内存中创建一份副本，以便区分开每个实例。DC可以根据不同的应用环境进行合适的优化。

#确定wire load mode


#set_wire_load_model -name "tsmc090_wl20" -library "typical"


#set auto_wire_load_selection true
#auto_wire_load_selection = false
#-------------------------------SDC----------------------------------
source ../script/Sdc.tcl
#--------------------- Pre-Optimization Checks --------------------
# 建议在读入设计后立即执行基础检查
check_design -summary > ../../syn_qmh/report/pre_opt_check_design.rpt
check_timing > ../../syn_qmh/report/pre_opt_check_timing.rpt
#--------------------Map and Optimize the Design---------------------
compile_ultra -no_autoungroup -incremental -no_boundary_optimization
#----------------------Save Design Database--------------------------
change_names -rules verilog -hierarchy
set_fix_multiple_port_nets -all -buffer_constants
#---------------Check the syn_qmhthesized Design for Consistency---------
check_design -summary > ../../syn_qmh/report/check_design.rpt
check_timing > ../../syn_qmh/report/check_timing.rpt
#---------------------Report Timing and Area-------------------------
report_qor                  > ../../syn_qmh/report/$TOP_DESIGN.qor_rpt
report_timing -max_paths 1000 > ../../syn_qmh/report/$TOP_DESIGN.timing_rpt
report_timing -path full    > ../../syn_qmh/report/$TOP_DESIGN.full_timing_rpt
report_timing -delay max    > ../../syn_qmh/report/$TOP_DESIGN.setup_timing_rpt
report_timing -delay min    > ../../syn_qmh/report/$TOP_DESIGN.hold_timing_rpt
report_reference            > ../../syn_qmh/report/$TOP_DESIGN.ref_rpt
report_area                 > ../../syn_qmh/report/$TOP_DESIGN.area_rpt
report_constraints          > ../../syn_qmh/report/$TOP_DESIGN.const_rpt
report_constraint -all_violators > ../../syn_qmh/report/$TOP_DESIGN.violators_rpt
report_power > ../../syn_qmh/report/$TOP_DESIGN.power_rpt
check_timing > ../../syn_qmh/log/last_check_timing.log
#---------------------Generate Files -------------------------
write -f verilog -hierarchy -output ../../syn_qmh/mapped/$TOP_DESIGN.sv
write_sdc ../../syn_qmh/mapped/$TOP_DESIGN.sdc
write_sdf -context verilog ../../syn_qmh/mapped/$TOP_DESIGN.sdf
