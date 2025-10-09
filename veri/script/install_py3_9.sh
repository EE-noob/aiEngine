#!/bin/bash

set -e

# 安装依赖
sudo yum groupinstall -y "Development Tools"
sudo yum install -y gcc openssl-devel bzip2-devel libffi-devel zlib-devel wget make

# 下载并编译 Python 3.9.19
cd /usr/src
sudo wget https://www.python.org/ftp/python/3.9.19/Python-3.9.19.tgz
sudo tar xzf Python-3.9.19.tgz
cd Python-3.9.19
sudo ./configure --enable-optimizations --prefix=/usr/local/python3.9
sudo make -j$(nproc)
sudo make altinstall  # ← 用 altinstall 避免替换系统 python

# 建立软链接
sudo ln -sf /usr/local/python3.9/bin/python3.9 /usr/bin/python3.9
sudo ln -sf /usr/local/python3.9/bin/pip3.9 /usr/bin/pip3.9

# 测试安装
echo
echo "✅ Python3.9 安装完成，版本如下："
python3.9 --version
