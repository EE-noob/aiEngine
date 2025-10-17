#************parameter input*************
#※prepare the source list file  and then make add the soucefile name 
#for example ,the Verilog source file's name is vlog_list.f then :make norsim rtl_list=file_list>>>
rtl_list =  rtl_list
sim_list =  sim_list
simv_name = simv
vpdpluse_name = vcdpluse
cov_file_name = coverage
vdb_name = vdbfl
nm=defaultp4
CASE=0
#$(simv_name)
my_incdir=../ssy_tb/tb
export dut_top=top_with_bridge # axi_crossbar_top## #tb_withbrige.axi_crossbar_top_inst
cov_dir=./cov_withbrige
plus=1
ifeq ($(plus),1)
	plusargs=+dump_fsdb
else
	plusargs=
endif
#+dump_vcd

#cdc
export CDC_DIR=../cdc
#<<<
#************constant command************
  #  -debug_all                               \
   #'-debug_acc+all -debug_region+cell+encrypt' instead.
#compile>>>#
NOR_VCS = vcs -full64 -sverilog +v2k -timescale=1ns/1ns            \
      +notimingcheck                                   \
      +nospecify                                       \
      +vcs+flush+all                                   \
      -o $(simv_name)   \
      -l compile.log	\
	  -f $(rtl_list).f  \
		-f $(sim_list).f \
		+incdir+$(my_incdir) \
		+delay_mode_path \
		$(plusargs)
POST_VCS = vcs -full64 -sverilog +v2k -timescale=1ns/1ns            \
      -debug_all                               \
      +vcs+flush+all                                   \
      -o $(simv_name)   \
      -l compile.log	\
	  -f $(rtl_list).f  \
		-f $(sim_list).f \
		+incdir+$(my_incdir) \
		+delay_mode_path \
		$(plusargs)

#coverage compile switch 
COV_SW =-cm line+branchu   
#-cm line+cond+fsm+branch+tgl 
#verdi dump wave compile option 
VERDI_SW = -P \
${VERDI_HOME}/share/PLI/VCS/LINUX64/novas.tab  \
${VERDI_HOME}/share/PLI/VCS/LINUX64/pli.a
 
#run option
RUN_GUI = -R -gui -l run.log
RUN_VPD = -R +vpdfile+$(vpdpluse_name).vpd -l run.log
RUN_COV = -R  $(COV_SW) -cm_name $(vdb_name) -cm_dir $(cov_dir)/$(cov_file_name) -l run.log  -cm_hier  ./covfl  
RUN_VER = -R +fsdb+autoflush -l run.log 
RUN_DEBUG_VER = -R +fsdb+functions -l run.log 
#./cov_withbrige/
#./cov_intl
#./cov_xbar

#compile<<<
#************command************
#post_sim>>>
intl:intlfl run 
2:2fl run 
xbar:fl run
#none-lowpower
nlp:nlpfl run

post2:
	make 2fl 
	make postfl  
	make run plusargs=+dump_fsdb+sdf

verintl:intlfl run vd
ver2:2fl run vd
versim:fl run vd
sedbca:
	   sed -i '/..\/..\/bca\/SRAM_512x32.v/d'  rtl_list.f;
postfl:
	echo ../../icc/output/top_with_bridge.output1.v > rtl_list.f
	echo ../../tsmc_verilog/tcbn65lp.v >> rtl_list.f 

fl:
	rm -rf rtl_list.f;  rm -rf sim_list.f;  find ../rtl -maxdepth 1 -type f -name "*v" > rtl_list.f;find ../tc -maxdepth 1 -type f -name "*v" > sim_list.f;
iafl:
	rm -rf rtl_list.f;  rm -rf sim_list.f;   find ../rtl -maxdepth 1 -type f -name "*v" > rtl_list.f;find ../tb -maxdepth 1 -type f -name "*v" > sim_list.f;echo "../tc/tb_ia_loader.sv" >> sim_list.f;
icbfl:
	rm -rf rtl_list.f;  rm -rf sim_list.f;  echo "../rtl/icb_unalign_bridge.sv" > rtl_list.f;echo "../tc/tb_unalign.sv" > sim_list.f;
calfl:
	rm -rf rtl_list.f;  rm -rf sim_list.f;  echo "../rtl_combine_scramble/cal_top.sv" > rtl_list.f; echo "../rtl_combine_scramble/serial_divider.v" >> rtl_list.f; echo "../rtl_combine_scramble/cal.sv" >> rtl_list.f;echo "../tc/tb_cal_top.sv" > sim_list.f;
srfl:
	rm -rf rtl_list.f;  rm -rf sim_list.f;  echo "../rtl/triangleSR.sv" > rtl_list.f;echo "../tc/tb_triangleSR_param.sv" > sim_list.f;echo "../tc/triangleSR_sva.sv" >> sim_list.f;echo "../tc/sr_tb_top.sv" >> sim_list.f;
filofl:
	rm -rf rtl_list.f;  rm -rf sim_list.f;  echo "../rtl/filo.sv" > rtl_list.f;echo "../tc/tb_filo.sv" > sim_list.f;
vfl:
	rm -rf rtl_list.f;  rm -rf sim_list.f;  find ../rtl  -maxdepth 1 -type f -name "*v" > rtl_list.f;echo > sim_list.f;
icsfl:
	rm -rf rtl_list.f;  rm -rf sim_list.f;  find ../rtl  ../rtl_combine_scramble -maxdepth 1 -type f -name "*v" > rtl_list.f;echo > sim_list.f;
mbfl:
	rm -rf rtl_list.f;  rm -rf sim_list.f;  find ../rtl_combine_scramble  -maxdepth 1 -type f -name "*v" > rtl_list.f;echo > sim_list.f;
cfl:
	rm -rf rtl_list.f;  rm -rf sim_list.f;  find ../rtl ./bca -maxdepth 1 -type f -name "*v" > rtl_list.f;sed -i '/..\/rtl\/top_with_bridge.sv/d'  rtl_list.f;find ../ssy_tb/tb -maxdepth 1 -type f -name "*v" > sim_list.f;echo ../ssy_tb/tc/tb_top_nlp.sv >> sim_list.f;
intlfl:
	rm -rf rtl_list.f;  rm -rf sim_list.f;  find ../rtl ./bca -maxdepth 1 -type f -name "*v" > rtl_list.f;find ../ssy_tb/tb -maxdepth 1 -type f -name "*v" > sim_list.f;echo ../ssy_tb/tc/tb_interleaving.sv >> sim_list.f;

2fl:
	rm -rf rtl_list.f;  rm -rf sim_list.f;  find ../rtl  ./bca  -maxdepth 1 -type f -name "*v" > rtl_list.f;find ../ssy_tb/tb -maxdepth 1 -type f -name "*v" > sim_list.f;echo ../ssy_tb/tc/tb_withbrige.sv >> sim_list.f;

run:
	$(NOR_VCS) -debug_all $(VERDI_SW) $(RUN_VER)
debug_vcs: debug_comp debug_sim
debug_comp:
	export FSDB_ENABLE_EXPAND_CLASS=1;
	export FSDB_ENABLE_CLASS;
	export FSDB_ENABLE_EXPAND_CLASS=1;
	export VERDI_ENHANCE_DYNAMIC_OBJECT;
	vcs -full64 -sverilog +v2k -timescale=1ns/1ps -debug_access+class+dmptf+all -kdb -lca -ntb_opts uvm-1.2 +define+UVM_VERDI_COMPWAVE-full64 -f $(rtl_list).f 	-f $(sim_list).f +incdir+$(my_incdir) +dump_fsdb 

debug_sim:
	./simv -l run.log +fsdb+variant_size_array +UVM_VERDI_TRACE=" HIER+COMPWAVE" +fsdbfile+wave$(CASE).fsdb


#debug_vcs:
#	$(NOR_VCS) -debug_access+all -kdb -lca -full64  +fsdb+variant_size_array $(VERDI_SW) $(RUN_DEBUG_VER) 


# debug_vcs:
# 	$(NOR_VCS) -debug_access+dmptf   $(VERDI_SW) $(RUN_DEBUG_VER) 
vd:
	verdi -sv -f $(rtl_list).f -f $(sim_list).f -ssf *.fsdb -rcFile ~/dark.rc -nologo  & 
#post_sim<<<	
##coverage >>>
# moduletree/tree/node 前面的+表示查看，-表示不查看
# lvl_num表示层级：0表示处理当前层级及其所属的所有层级；1表示处理当前层级；2表示处理当前层级及其下一层级。默认是0
# moduletree：表示某个模块及其例化的子模块。单独某个模块也可以使用module
# tree：表示某一层级的处理，tree后面也可以添加lvl_num；
# node： 表示某一层级信号的处理。
cov:
	make xbar;make covsim dut_top=axi_crossbar_top cov_dir=./cov_xbar;
	make intl;make covsim dut_top=axi_crossbar_top cov_dir=./cov_intl;
	make 2;make covsim dut_top=top_with_bridge cov_dir=./withbrige;

urg:
	urg -dir ./cov_xbar/$(cov_file_name).vdb \
		-dir  ./cov_intl/$(cov_file_name).vdb \
		-dir  ./cov_withbrige/$(cov_file_name).vdb \
		-map axi_crossbar_top \
		-dbname ./cov_urg.vdb
	dve -covdir ./cov_urg.vdb &
covsim:
	echo +moduletree $(dut_top) > covfl 
	echo -moduletree round_arbiter >> covfl 
	$(NOR_VCS) $(VERDI_SW) $(COV _SW) \
	$(RUN_COV) 
	dve -covdir $(cov_dir)/$(cov_file_name).vdb &
dve:
	dve -covdir $(cov_dir)/$(cov_file_name).vdb &

##coverage <<<
syn:
	cd ../syn/work && \
	dc_shell -f ../script/SynFlow.tcl -output_log_file ../log/top_syn.log;
cdc:
	@cd ${CDC_DIR} &&  pwd && csh -c 'sg_shell < ../script/sg_cdc.tcl | & tee cdc_screen.log';
sdc2sgdc:
#@cd ${CDC_DIR} &&  pwd && csh -c 'sg_shell < ../script/sdc2sgdc.tcl | & tee cdc_screen.log';
	@cd ${CDC_DIR} &&  pwd  && csh -c 'sg_shell < ../script/sdc2sgdc.tcl';
# cp ./生成的sgdc路径 ./in/cdc.sgdc
# 生成的sgdc路径在gui的SDC2SGDC_INFO信息中。我生成的文件后缀不是.sgdc,所以我cp命令是重新命名了。
sg:
	spyglass -project ../cdc/sg_cdc.prj &
clrsg:
	rm -rf ../cdc/*
vcd2saif:
	vcd2saif -i vcd.dump -o vcd2.saif
#normally sim>>>
norsim: 
	$(NOR_VCS) $(RUN_GUI) 
  
#post-process
postsim:
	$(NOR_VCS)  $(RUN_VPD) 
	dve -vpd $(vpdpluse_name).vpd
#normally sim<<< 
#rm & mkdir
clr:
	rm -rf *csrc ./*.daidir $(simv_name) *simv* DVE* ucli* *.vpd *.vdb *.log *.fsdb *novas* *.dat *Log  *conf
 
dir:
	cd ../;mkdir rtl;mkdir sg;mkdir syn;mkdir tc;cd sim;


#git 
gitp4:
	git add ../*;git commit -m "$(nm)";git push jcs master;

p4tb:
	cd ../ssy_tb;git add .;git commit -m "$(nm)";git push origin master;cd ../sim;

pltb:
	cd ../ssy_tb;git pull;cd ../sim;
 
gitpl:
	git fetch jcs;git merge  master jcs/master;	

plrtl:
	cd ../rtl;git pull;cd ../sim;
p4rtl:
	cd ../rtl;add .;git commit -m "$(nm)";git push;cd ../sim;
#help
help:

	@echo "  ########## makefile Info ##########"
	@echo "  This Makefile is the entrance of the whole simulation environment"
	@echo "  Usage: make [target] [arguments]";
	@echo "  Available targets(部分):";

	@echo "    dir                             : make a simulation environment";
	@echo "    gitp4                           : push all the repo to github";
	@echo "    p4tb                            : push the ssy_tb to github";
	@echo "    pltb                            : pull the ssy_tb from github";

	@echo "    gitpl                           : pull the repo from github";
	@echo "    plrtl                           : pull the rtl(with bridge) from github";
	@echo "    p4rtl                           : push the rtl(with bridge) to github";

	@echo "    xbar                            : 进行crossbar的基础仿真(using vcs )";
	@echo "    intl                            : 进行xbar写乱序和写交织的仿真(using vcs )";
	@echo "    2                               : 将axi2ahb、apb桥联到xbar上进行仿真(using vcs )"; 

	@echo "    versim                          : 进行其他测试用例的仿真并查看波形(using vcs & verdi )";
	@echo "    verintl                         : 进行写乱序和写交织的仿真并查看波形(using vcs & verdi)";
	@echo "    ver2                            : 进行axi2ahb bridge仿真并查看波形(using vcs & verdi )";
	@echo "    vd                              : open testname.fsdb with verdi";
	@echo "    covsim                          : 统计验证覆盖率(先修改rtllist和simlist和cov_dir参数)";
	@echo "    示例                            :make intl;make covsim dut_top=axi_crossbar_top cov_dir=./cov_intl";
	@echo "    示例                            :make xbar;make covsim dut_top=axi_crossbar_top cov_dir=./cov_xbar";
	@echo "    cov                             : 统计全部三个target的验证覆盖率";
	@echo "    urg                             : 合并三个target的验证覆盖率";

	@echo "    syn                             : 进行逻辑综合(using design compiler )";
	@echo "    sdc2sgdc                        : 将dc生成的sdc转换为sgdc在constraints下,注意sdc版本(using spyglass)";
	@echo "    verintl                         : 进行写乱序和写交织的仿真并查看波形(using vcs & verdi)";
	@echo "    ver2                            : 进行axi2ahb bridge仿真并查看波形(using vcs & verdi )";

# 	merge_saif #合并SAIF文件

# read_saif #读backward SAIF文件

# report_saif #报告开关行为的信息

# rtl2saif #产生RTL forward SAIF文件

# write_ saif #写出一个backward SAIF文件

# lib2saif #产生library forward SAIF文件

# propagate_switching_activity #传输功耗清除

# reset_switching_activity #清除开关行为和/或翻转率

# set_switching_activity #在指定的物体上设置开关行为
