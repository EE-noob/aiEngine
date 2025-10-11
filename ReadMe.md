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
    cd sim;
    make fl;//生成flist
    make run;//编译、仿真
    make vd;//查看波形