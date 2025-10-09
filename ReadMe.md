## 文件层次        
├── picture        绘制的架构图等
├── randomcase     随机case数据
├── ReadMe.md      文件介绍
├── rtl            rtl代码
├── sim            模块级仿真的目录
├── syn            综合的目录
├── tc             模块级仿真的tb
├── trash          垃圾箱
└── veri           整体ip级的uvm仿真目录


## How2run:
    cd veri/sim;
    make run CASE=numer;//number=[1,10]，运行仿真
    make wave CASE=numer;//number=[1,10]，打开verdi查看波形