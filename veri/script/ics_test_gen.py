#!/usr/bin/env python3
"""
ICS Test‑case Generator & Verifier (改进版)
=========================================
* gen   : 从 case5 开始顺延生成随机用例。
* verify: 读取 define_golden / data_golden 下的 golden 文件，
          重新按照逻辑生成 case1~4 的文件到 define/ 与 data/，
          并逐一比对新旧文件差异，完全一致则 PASS。

用法示例
--------
# 生成 6 组 (case5‑case10)
python ics_testgen.py gen --count 6

# 验证 golden (case1‑case4)
python ics_testgen.py verify
"""
from __future__ import annotations
import argparse, random, itertools, pathlib, re, filecmp
from typing import List, Dict, Tuple
import math          # ← 新增
import os
import re
import filecmp
import pathlib
# ...

# ---------------- 目录常量 ------------------
BASE_DIR           = pathlib.Path(__file__).resolve().parent
DATA_DIR           = BASE_DIR / "data"
DEFINE_DIR         = BASE_DIR / "define"
DATA_GOLDEN_DIR    = BASE_DIR / "data_golden"
DEFINE_GOLDEN_DIR  = BASE_DIR / "define_golden"
# 确保生成目录存在
DATA_DIR.mkdir(exist_ok=True)
DEFINE_DIR.mkdir(exist_ok=True)

# ---------------- 随机参数 ------------------
RAND_N_CHOICES = [32, 64, 128, 256, 512, 1024]  # N 可选集合
RAND_Q_CHOICES = [1, 2, 4, 6, 8, 10]            # Q 可选集合
MAX_E          = 8192                           # E 最大值

import re

# -------------------------------------------------------------
# 统一解析宏里的数值：支持十六进制 / 二进制 / 十进制 / Verilog `'h 'd 'b` 写法
# -------------------------------------------------------------
def parse_val(token: str) -> int:
    """把 `14'd80` / `31'h0` / `0x1A3` / `123` 等转成 int"""
    tok = token.strip().rstrip(",")          # 去掉空格和多余逗号

    # 0xABCDEF 形式
    if tok.lower().startswith("0x"):
        return int(tok, 16)

    # Verilog 风格： 14'd80, 31'h0, 8'b1011
    if "'" in tok:
        _, base_val = tok.split("'", 1)      # "d80" / "h0" / "b1011"
        base, val  = base_val[0].lower(), base_val[1:]
        if base == "d":
            return int(val, 10)
        if base == "h":
            return int(val, 16)
        if base == "b":
            return int(val, 2)

    # 默认为十进制
    return int(tok, 10)

# ----------- bit 列表转十六进制 ------------

def bits_to_hex(bits: List[int]) -> str:
    """将低位在前的 bit 序列转 0x... 字符串。"""
    val = 0
    for i, b in enumerate(bits):
        val |= (b & 1) << i
    return f"0x{val:0{(len(bits)+3)//4}x}"

import math
from typing import List

# -------------------------------------------------------------
# 根据 E 求三角列有效长度数组
# -------------------------------------------------------------
def tri_cols(E: int) -> List[int]:
    """
    给定 E，返回 GROUP_WIDTH_ARRAY 列表。
    步骤：
        1. P = ceil( (-1 + sqrt(1+8E)) / 2 )
        2. area  = P*(P+1)/2
        3. bubble_num = area - E
        4. bubble_P   = ceil( (-1 + sqrt(1+8*bubble_num)) / 2 )
        5. b1 = bubble_num - (bubble_P-1)*bubble_P/2
        6. 列长度拼装见题述算法
    """
    # --- 1. P ---
    P = math.ceil((-1 + math.sqrt(1 + 8 * E)) / 2)

    area = P * (P + 1) // 2
    bubble_num = area - E
    if bubble_num == 0:
        return list(range(P, 0, -1))   # 完整三角，无空泡

    # --- 4. bubble_P ---
    bubble_P = math.ceil((-1 + math.sqrt(1 + 8 * bubble_num)) / 2)
    b1 = bubble_num - (bubble_P - 1) * bubble_P // 2

    cols: List[int] = []

    # 前 (bubble_P - b1) 列：长度 = P - (bubble_P - 1)
    cols.extend([P - (bubble_P - 1)] * (bubble_P - b1))

    # 接着 (b1 + 1) 列：长度 = P - bubble_P
    cols.extend([P - bubble_P] * (b1 + 1))

    # 其余列：从 P-(bubble_P+1) 递减到 1
    for k in range(bubble_P + 1 +1, P + 1):#py range左闭右
        #cols.append(P - k + 1)
        cols.append(P - k+1)

    # 校验
    #assert len(cols) == P, f"列数应为 P={P}, 实际 {len(cols)}"
    return cols


# ----------- 随机参数生成 ------------------

def generate_random_params() -> Dict:
    Q  = random.choice(RAND_Q_CHOICES)
    EN = [random.random() < 0.7 for _ in range(3)]
    if not any(EN):
        EN[random.randint(0, 2)] = True
    N, E, L, S = [], [], [], []
    for en in EN:
        if not en:
            N.append(0); E.append(0); L.append(0); S.append(0)
            continue
        n = random.choice(RAND_N_CHOICES)
        e = random.randint(n, MAX_E)
        maxL = (e // Q) * Q
        l = random.randint(1, maxL // Q) * Q
        s = random.randint(1, e - l + 1)
        N.append(n); E.append(e); L.append(l); S.append(s)
    return {
        "Cinit": random.randint(0, 2**31 - 1),
        "Q": Q,
        "EN": EN,
        "N": N,
        "E": E,
        "L": L,
        "S": S,
    }

# ----------- 交织算法 ----------------------

def _triangle_P(E: int) -> int:
    P = 1
    while P * (P + 1) // 2 < E:
        P += 1
    return P

def interleave_bits(bits: List[int], E: int, S: int, L: int) -> List[int]:
    """
    生成直角边在上/左的三角交织：
        第1行 P   个比特
        第2行 P-1 个比特
        ...
        第P行 1   个比特
    再按列（左→右，上→下）输出，最后截取 S..S+L-1。
    """
    if L == 0:
        return []

    # 取前 E 比特，循环补足
    seq = list(itertools.islice(itertools.cycle(bits), E))

    # 计算 P：满足 P*(P+1)/2 ≥ E 且最小
    P = _triangle_P(E)

    # ------------ 构建三角形 ------------
    tri = [[] for _ in range(P)]            # P 行
    idx = 0
    for r in range(P):                      # r = 0..P-1
        row_len = P - r                     # 第 r 行长度 = P-r
        for _ in range(row_len):
            tri[r].append(seq[idx] if idx < E else None)
            idx += 1

    # ------------ 按列读取 -------------
    col = []
    for c in range(P):                      # 列数同样 P→1
        for r in range(0, P - c):           # 这一列有 P-c 个元素
            v = tri[r][c]
            if v is not None:
                col.append(v)
   # print(f"[Case] inter col len={len(col)}  S={S}  L={L}")
    # 截取 S..S+L-1
    return col[S - 1 : S - 1 + L]


# ----------- 合并算法 ----------------------

def combine_parts(parts: List[List[int]], Q: int) -> List[List[int]]:
    Ls = [len(p) for p in parts]
    LL = sum(Ls)
    if LL == 0:
        return []
    rows = (LL + Q - 1) // Q
    mat = [[0] * 10 for _ in range(rows)]
    used = [False] * rows

    def alloc(bits: List[int]):
        if not bits:
            return
        need = (len(bits) + Q - 1) // Q
        step = rows / need
        row = 0
        chunks = [bits[i : i + Q] for i in range(0, len(bits), Q)]
        for idx, ch in enumerate(chunks):
            while row < rows and used[row]:
                row += 1
            if row >= rows:
                row = used.index(False)
            mat[row][: Q] = ch
            used[row] = True
            row = int(round((idx + 1) * step))

    for part in parts:  # 优先级 PART0 > PART1 > PART2
        alloc(part)
    return mat

# ----------- 扰码序列 ----------------------

def _lfsr_step(reg: List[int], taps: List[int]) -> int:
    out = reg[-1]
    fb = 0
    for t in taps:
        fb ^= reg[t]
    reg.pop()
    reg.insert(0, fb)
    return out

G1 = [27]
G2 = [27, 28, 29]

# -------------------------------------------------------------
# 伪随机序列 c(n) 生成：三条递推式 + NC = 16000
# -------------------------------------------------------------
from typing import List

def generate_scram_sequence(c_init: int, total_bits: int, NC: int = 16000) -> List[int]:
    """
    返回长度 = total_bits 的 c(n) 比特流（低位在前，LSB-first）
    公式：
        x1(n+31) = x1(n+3) ⊕ x1(n)
        x2(n+31) = x2(n+3) ⊕ x2(n+2) ⊕ x2(n+1) ⊕ x2(n)
        c(n)     = x1(n+NC) ⊕ x2(n+NC)
    初值：
        x1(0)=1, x1(1..30)=0
        x2(0..30) = bit_i(c_init)   (i = 0→30, 低位在前)
    """
    # ---------- 初始化 31 级移位寄存器 ----------
    x1 = [0]*31
    x2 = [(c_init >> i) & 1 for i in range(31)]
    x1[0] = 1

    # 我们需要 x1/x2 至少到 n = NC + total_bits + 30
    seq_len = NC + total_bits + 31

    # 预分配结果数组
    x1_seq, x2_seq = [0]*seq_len, [0]*seq_len
    # 写初始 31 位
    for i in range(31):
        x1_seq[i] = x1[i]
        x2_seq[i] = x2[i]

    # ---------- 迭代生成 ----------
    for n in range(31, seq_len):
        # 上一位索引 = n-31
        # x1: taps n-28 (=n-31+3) 与 n-31
        x1_new = x1_seq[n-28] ^ x1_seq[n-31]
        # x2: taps n-28, n-29, n-30, n-31
        x2_new = x2_seq[n-28] ^ x2_seq[n-29] ^ x2_seq[n-30] ^ x2_seq[n-31]

        x1_seq[n] = x1_new
        x2_seq[n] = x2_new

    # ---------- 计算 c(n) ----------
    c = [(x1_seq[n+NC] ^ x2_seq[n+NC]) for n in range(total_bits)]
    return c            # 低位 first

# -------------------------------------------------------------
import math
from typing import List

ROW_WIDTH   = 12          # 每行 12 bit
ROWS_IN_GRP = 10          # 10 行 = 120 bit = 30 hex

def merge_parts(parts: List[List[int]], Q: int, case: int) -> List[int]:
    """返回 row_owner 列表，并写 caseN_rowx_part.mem（行内仅 0/1/2）"""
    total_bits = sum(len(p) for p in parts)
    rows = math.ceil(total_bits / Q)

    owner = [-1] * rows          # -1 表示尚未分配
    taken = [False] * rows
    #print(parts)
    # for p_idx, bits in enumerate(parts):           # P0 > P1 > P2
    #     print(bits)
    #     need = math.ceil(len(bits) / Q)
    #     print(len(bits),Q,need)
    #     avail = [i for i, t in enumerate(taken) if not t]
    #     gap = max(1, math.floor(len(avail) / need))
    #     cur = 0
    #     for _ in range(need):
    #         r = avail[cur]
    #         owner[r] = p_idx
    #         taken[r] = True
    #         cur = min(cur + gap, len(avail) - 1)
    for p_idx, bits in enumerate(parts):
        need = math.ceil(len(bits) / Q)

        if need == 0:                 # 该 part 没有数据，直接跳过
            continue

        avail = [i for i, t in enumerate(taken) if not t]

        # 当 need == 1 时，gap 无意义，直接取第一个空行
        if need == 1:
            r = avail[0]
            owner[r] = p_idx
            taken[r] = True
            continue

        gap = max(1, math.floor(len(avail) / need))
        cur = 0
        for _ in range(need):
            r = avail[cur]
            owner[r] = p_idx
            taken[r] = True
            cur = min(cur + gap, len(avail) - 1)

    # 写 mem：每行一个数字，无行号
    mem_path = DATA_DIR / f"case{case}_rowx_part.mem"
    with mem_path.open("w", encoding="utf-8") as f:
        for p in owner:
            f.write(f"{p}\n")
    return owner


# -------------------------------------------------------------
def write_combine(case: int, mat: List[List[int]]):
    """
    把合并完成 (尚未 XOR scram) 的矩阵写成
        data/ics_combine_out_data{case}.txt
    · 每行 12 bit → 3 hex，带 0x 前缀
    · LSB-first：先反转再转十六进制
    """
    path = DATA_DIR / f"ics_combine_out_data{case}.txt"
    with path.open("w", encoding="utf-8") as f:
        for row in mat:
            val = int(''.join(map(str, reversed(row))), 2)
            f.write(f"0x{val:03x}\n")        # 12 bit = 3 hex

# # # ----------- 加扰 + 分组 -------------------

# def scramble_and_group(mat: List[List[int]], scram: List[int], Q: int) -> List[str]:
#     rows = len(mat)
#     idx = 0
#     for r in range(rows):
#         for c in range(Q):
#             mat[r][c] ^= scram[idx]
#             idx += 1
#     groups = []
#     for g in range(0, rows, 12):
#         bits = list(itertools.chain.from_iterable(mat[g : g + 12]))
#         if len(bits) < 120:
#             bits.extend([0] * (120 - len(bits)))
#         groups.append(bits_to_hex(bits))
#     return groups
# -------------------------------------------------------------
#  合并 + 加扰 + 分组（完全符合题面规则）
# -------------------------------------------------------------
# -------------------------------------------------------------
# -------------------------------------------------------------
#   合并 + 加扰 + 分组（符合题述最后版本）
# -------------------------------------------------------------
# 合并 + 行内加扰 + 分组   （每行 12 bit，低 q bit 有效）
# -------------------------------------------------------------
from typing import List
import itertools

ROW_W        = 12     # 一行固定 12 bit
ROWS_PER_GRP = 10     # 10 行 × 12 bit = 120 bit = 30 hex

def scramble_and_group(case:int,parts: List[List[int]],
                       row_owner: List[int],   # 如 [0,0,1,0,2,…]，长度 = rows
                       scram: List[int],       # 已按行切成 q bit×rows
                       Q: int) -> List[str]:
    """
    ① 合并：行号从 0 递增，不跳行  
       行 r 填入 part[row_owner[r]] 的连续 Q bit（不足 Q → 剩余行尾 0）  
    ② 加扰：对行 r 的 **低 Q bit** 与 scram 的对应 Q bit 逐位异或  
    ③ 分组：10 行(=120 bit) → 0x + 30 hex（LSB-first；末尾补 0）
    """
    rows = len(row_owner)
    mat  = [[0]*ROW_W for _ in range(rows)]
    curs = [0, 0, 0]                         # 每个 part 已取到的位置

    # ---------- ① 合并 ----------
    for r, p_idx in enumerate(row_owner):
        src  = parts[p_idx]
        take = min(Q, len(src) - curs[p_idx])
        mat[r][:take] = src[curs[p_idx]: curs[p_idx] + take]
        curs[p_idx]  += take                # 行尾 (12-Q) bit 留 0

    write_combine(case, mat)          # ⬅️ 写调试文件

    # ---------- ② 行内加扰 ----------
    # scram 已保证“刚好 rows 行 × Q bit”
    s_idx = 0
    sccnt=0
    for r in range(rows):
        for b in range(Q):                  # 仅低 Q bit
            mat[r][b] ^= scram[s_idx]
            if(case==3 and sccnt<=16):
                #print(s_idx,scram[s_idx])
                sccnt+=1
            s_idx += 1

    # ---------- ③ 12 行 × 10 bit → 120 bit → 30 hex ----------
    ROWS_IN_GRP       = 12
    VALID_BITS_PER_ROW = 10                # 低 10 位
    BITS_PER_GRP       = ROWS_IN_GRP * VALID_BITS_PER_ROW  # 120

    lines = []
    total_rows = len(mat)

    for g in range(0, total_rows, ROWS_IN_GRP):
        bits_chunk = []

        # 行顺序 0 → 11，不再翻转行，也不再翻转行内 bit
        for r in range(g, min(g + ROWS_IN_GRP, total_rows)):
            bits_chunk.extend(mat[r][:VALID_BITS_PER_ROW])  # 直接拿低 10 位

        # 末组不足 120 bit 补 0
        if len(bits_chunk) < BITS_PER_GRP:
            bits_chunk.extend([0] * (BITS_PER_GRP - len(bits_chunk)))

        # 将 LSB-first 的 bit 串整体反转，再转成 30 hex
        hex_val = int(''.join(str(b) for b in reversed(bits_chunk)), 2)
        lines.append(f"0x{hex_val:030x}")   # 120 bit = 30 hex
    return lines







def write_input(case: int,
                part_inputs: List[List[int]],
                layout: Optional[List[Tuple[int, int]]] = None):
    path = DATA_DIR / f"ics_input_data{case}.txt"
    with path.open("w", encoding="utf-8") as f:

        # 若未指定 layout，默认写 0-23 共 24 行（原先行为）
        if layout is None:
            layout = [(addr, 32) for addr in range(24)]   # 128 bit → 32 hex

        for addr, hex_width in layout:
            p   = addr // 8
            off = addr % 8
            bits = part_inputs[p][off * 128 : (off + 1) * 128]
            if len(bits) < 128:
                bits += [0] * (128 - len(bits))
            val_hex = f"0x{int(''.join(str(b) for b in reversed(bits)), 2):0{hex_width}x}"
            f.write(f"{addr} {val_hex}\n")



# def write_intlv(case: int, mat, out_dir: pathlib.Path = DATA_DIR):
#     with (out_dir / f"ics_intlv_out_data{case}.txt").open("w", encoding="utf-8") as f:
#         for row in mat:
#             f.write(bits_to_hex(row) + "\n")
# ------------------------------------------------------------------
# ------------------------------------------------------------------
def write_intlv(case: int, part_streams: List[List[int]]):
    """
    将 3 个 part 的交织结果写成 ics_intlv_out_dataN.txt
    要求：
        • 每 128 bit (=32 hex) 写 1 行
        • 不写地址，只写十六进制串
        • 行顺序：先全部 part0，再 part1，再 part2
    """
    path = DATA_DIR / f"ics_intlv_out_data{case}.txt"
    with path.open("w", encoding="utf-8") as f:
        for bits in part_streams:                 # part0, part1, part2
            # 补齐到 128 的整数倍
            if len(bits) % 128:
                bits += [0] * (128 - len(bits) % 128)

            for i in range(0, len(bits), 128):
                chunk = bits[i : i + 128]         # LSB-first
                hex32 = f"0x{int(''.join(map(str, reversed(chunk))), 2):032x}"
                f.write(f"{hex32}\n")



# def write_scram(case: int, scr, out_dir: pathlib.Path = DATA_DIR):
#     with (out_dir / f"ics_scram_code{case}.txt").open("w", encoding="utf-8") as f:
#         for i in range(0, len(scr), 32):
#             f.write(bits_to_hex(scr[i : i + 32]) + "\n")
# ------------------------------------------------------------------
def write_scram(case: int, bits: List[int], Q: int):
    """
    将 scramble 比特流写成 ics_scram_codeN.txt
    规则：
        · 每行 Q bit；若最后不足 Q，则高位补 0
        · 行写成 128bit 十六进制（32 字节），仅低 Q bit 有效
        · 不写地址，只写 0x……
    """
    path = DATA_DIR / f"ics_scram_code{case}.txt"
    with path.open("w", encoding="utf-8") as f:

        for i in range(0, len(bits), Q):
            chunk = bits[i : i + Q]

            # 补齐 Q 位
            if len(chunk) < Q:
                chunk += [0] * (Q - len(chunk))

            # 低位（chunk[0]） → 十六进制最低位
            val = int("".join(map(str, reversed(chunk))), 2)
            f.write(f"0x{val:03x}\n")


def write_output(case: int, groups, out_dir: pathlib.Path = DATA_DIR):
    with (out_dir / f"ics_output_data{case}.txt").open("w", encoding="utf-8") as f:
        for g in groups:
            f.write(g + "\n")



            
# ------------------------------------------------------------------
# 生成 caseN_define.vh
#   · 自动换行
#   · 若 GW / GL / SCR_NUM 缺失则自动推导或跳过写入
# ------------------------------------------------------------------
def write_define(case: int, params: Dict):
    path = DEFINE_DIR / f"case{case}_define.vh"
    with path.open("w", encoding="utf-8") as f:
        # 头注释
        f.write(f"// case{case}_define.vh  –  Auto-gen by ics_testgen.py\n\n")

        # ---------- 路径相关 4 个宏 ----------
        f.write(f"`define ICS_INPUT_DATA       \"../data/ics_input_data{case}.txt\"\n")
        f.write(f"`define ICS_INTLV_OUT_DATA   \"../data/ics_intlv_out_data{case}.txt\"\n")
        f.write(f"`define ICS_OUTPUT_DATA      \"../data/ics_output_data{case}.txt\"\n")
        f.write(f"`define ICS_SCRAMBLE_CODE    \"../data/ics_scram_code{case}.txt\"\n\n")

        # ---------- GROUP_WIDTH_ARRAY_i ----------
        gw_present = "GW" in params
        if gw_present:
            gw = params["GW"]                      # 用调用者给的
        else:
            # ★ 自动构造一个递减三角（最多 13 列，可按需改）
            max_col = min(sum(params["L"]) // params["Q"], 13)
            gw = [list(range(max_col, 0, -1)) for _ in range(3)]

        # ---------- GROUP_WIDTH_ARRAY_i ----------
        for i, arr in enumerate(params["GW"]):
            vals = ", ".join(map(str, arr))
            # 为了美观，这里和示例一样用续行 '\'
            f.write(f"`define GROUP_WIDTH_ARRAY_{i} \\\n  '{{ {vals} }}\n")

        # ---------- GOLDEN_LINES_PER_PART ----------
        gl_vals = ", ".join(map(str, params["GL"]))
        f.write(f"`define GOLDEN_LINES_PER_PART '{{{gl_vals}}}\n")

        # ---------- ICS_SCRAMBLE_OUTPUT_NUM ----------
        f.write(f"`define ICS_SCRAMBLE_OUTPUT_NUM {params['SCR_NUM']}\n\n")

        # ---------- ICS 输入相关 ----------
        def _w(name, val): f.write(f"`define {name:<22} {val}\n")

        _w("ICS_C_INIT", f"31'h{params['Cinit']:x}")
        _w("ICS_Q_SIZE", f"4'd{params['Q']}")

        for i in range(3):
            _w(f"ICS_PART{i}_EN",       f"1'b{int(params['EN'][i])}")
            _w(f"ICS_PART{i}_N_SIZE",   f"11'd{params['N'][i]}")   # ← 去掉斜杠
            _w(f"ICS_PART{i}_E_SIZE",   f"14'd{params['E'][i]}")   # ← 去掉斜杠
            _w(f"ICS_PART{i}_L_SIZE",   f"14'd{params['L'][i]}")   # ← 去掉斜杠
            _w(f"ICS_PART{i}_ST_IDX",   f"14'd{params['S'][i]}")   # ← 去掉斜杠


def load_params (case: int, dir_path: pathlib.Path = DEFINE_DIR) -> Dict:
    vh = dir_path / f"case{case}_define.vh"
    text = vh.read_text(encoding="utf-8", errors="ignore")

    def _val(name: str):
        m = re.search(rf"`define\s+{name}\s+(\S+)", text)
        return parse_val(m.group(1)) if m else 0

    return {
        "Cinit": _val("ICS_C_INIT"),
        "Q": _val("ICS_Q_SIZE"),
        "EN": [_val(f"ICS_PART{i}_EN") for i in range(3)],
        "N": [_val(f"ICS_PART{i}_N_SIZE") for i in range(3)],
        "E": [_val(f"ICS_PART{i}_E_SIZE") for i in range(3)],
        "L": [_val(f"ICS_PART{i}_L_SIZE") for i in range(3)],
        "S": [_val(f"ICS_PART{i}_ST_IDX") for i in range(3)],
    }

# ----------- 小工具 -------------------------

def read_bits_hexfile(path: pathlib.Path, bpl: int) -> List[int]:
    bits = []
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or not line.startswith("0x"):
            continue
        val = int(line, 16)
        bits.extend([(val >> i) & 1 for i in range(bpl)])
    return bits


def cmp_bits(a: List[int], b: List[int]) -> Tuple[bool, int]:
    for i, (x, y) in enumerate(zip(a, b)):
        if x != y:
            return False, i
    return (len(a) == len(b), -1)


def files_equal(p1: pathlib.Path, p2: pathlib.Path, ignore_comment: bool = True) -> bool:
    """灵活比较两个文件内容。对于 .vh
    * 去掉注释后 **按行排序** 再比较，避免顺序差异导致假阴性。
    * 强制使用 UTF‑8，失败时回退 latin‑1。"""
    if not p1.exists() or not p2.exists():
        return False

    if ignore_comment and p1.suffix == ".vh":
        def _clean_lines(path: pathlib.Path):
            try:
                txt = path.read_text(encoding="utf-8")
            except UnicodeDecodeError:
                txt = path.read_text(encoding="latin1", errors="ignore")
            return sorted(
                l.strip() for l in txt.splitlines()
                if l.strip() and not l.strip().startswith("//")
            )

        return _clean_lines(p1) == _clean_lines(p2)

    # 其他文件：二进制精确比较
   #return filecmp.cmp(p1, p2, shallow=False)(p1, p2, shallow=False)
    return filecmp.cmp(p1, p2, shallow=False)

# ----------- 生成 (case5 起) ----------------
def make_layout(params):
    """生成 input 布局：[(addr, hex_width)]，24 行 = 0..23"""
    return [(addr, 32) for addr in range(24)]      # 128 bit = 32hex
def gen_cases(cnt: int, start: int = 5):
    for case in range(start, start + cnt):
            # ---------- 1. 随机参数 ----------
        p = generate_random_params()
         # ---------- 2. 随机 input ----------
        inputs = [
            ([random.randint(0, 1) for _ in range(p["N"][i])] if p["EN"][i] else [])
            for i in range(3)
        ]
        layout = make_layout(p)
        # ---------- 3. 计算数组 / 行数 / scramble ---------------
        gw = [tri_cols(p["E"][i]) for i in range(3)]
        gl = [math.ceil(p["L"][i] / 128) for i in range(3)]
        inter = [
            interleave_bits(inputs[i], p["E"][i], p["S"][i], p["L"][i]) if p["EN"][i] else []
            for i in range(3)
        ]

        #print(inter)
        row_owner = merge_parts(inter, p["Q"], case)

        # 生成扰码
        scr_bits  = generate_scram_sequence(p["Cinit"], sum(p["L"]))

        # 合并 + 异或 + 分组（得到 0x… 行列表）
        out_lines = scramble_and_group(case,inter, row_owner, scr_bits, p["Q"])
 
        scr_lines= len(scr_bits) 
        print("scr_lines",scr_lines)
        #scr_num  = math.ceil(scr_cols / 12)
        scr_num  = math.ceil(scr_lines/ (12 * max(1, p["Q"])))
        print("scr_nums",scr_num)
        # ---------- 4. 把新字段塞回 params -----------
        p["GW"]       = gw
        p["GL"]       = gl
        p["SCR_NUM"]  = scr_num

        # ---------- 3. 处理流程 ----------
        inter = [
            interleave_bits(inputs[i], p["E"][i], p["S"][i], p["L"][i]) if p["EN"][i] else []
            for i in range(3)
        ]


        # 行分配：写 caseN_rowx_part.mem，并得到行→part 列表
        row_owner = merge_parts(inter, p["Q"], case)

        # 生成扰码
        scr_bits  = generate_scram_sequence(p["Cinit"], sum(p["L"]))

        # 合并 + 异或 + 分组（得到 0x… 行列表）
        out_lines = scramble_and_group(case,inter, row_owner, scr_bits, p["Q"])
        # ---------- 4. 写回普通目录 ----------
        
        write_define(case, p)                 # define
        write_input(case, inputs, layout)     # input —— 用 golden 布局

        write_intlv(case, inter)          # 仍写交织后 bit
        write_scram(case, scr_bits, p["Q"])   # 同上，只换变量名
        write_output(case, out_lines)     # 把 out_lines 原样写入
        # ⑨ 打印概览
        print(f"[GEN] Case{case}: Q={p['Q']}  P0={len(inputs[0])} "
              f"P1={len(inputs[1])} P2={len(inputs[2])}  "
              f"rows={len(row_owner)}  SCR_NUM={p['SCR_NUM']}")
        print(p)


import re
from typing import List, Tuple

# ---------------------------------------------------------------
def _regen_case_from_golden(case: int):
    """
    读取 golden 目录里的 define + input，
    重新跑一遍流程并把结果写到普通目录，再给 verify 去比对。
    """

    # ---------- 1. 读取 define ----------
    p = load_params(case, DEFINE_GOLDEN_DIR)

    print("DEBUG Case",case," Params:",
          "Q=", p["Q"],
          "S=", p["S"],
          "L=", p["L"],
          "E=", p["E"])
    # ---------- 2. 读取 golden input ----------
    inputs: List[List[int]] = [[], [], []]      # part0 / part1 / part2
    layout: List[Tuple[int, int]] = []          # [(addr, hex_width), ...]

    in_path = DATA_GOLDEN_DIR / f"ics_input_data{case}.txt"
    line_re = re.compile(
        r"^\s*(?P<addr>\d+)\s+"
        r"(?P<hex>(?:0[xX]|[xX])?[0-9a-fA-F]+)"
    )

    for line in in_path.read_text(errors="ignore").splitlines():
        m = line_re.match(line)
        if not m:
            continue                        # 跳过空行 / 非法行 / 注释

        addr    = int(m.group("addr"))
        hex_raw = m.group("hex").lower().strip()

        # 保存布局信息 —— 原始 hex 长度用于保持前导 0
        if hex_raw.startswith("0x"):
            width = len(hex_raw) - 2        # 去掉 0x
        elif hex_raw.startswith("x"):
            width = len(hex_raw) - 1        # 去掉 x
            hex_raw = "0" + hex_raw         # 补成 0x...
        else:
            width = len(hex_raw)
            hex_raw = "0x" + hex_raw

        layout.append((addr, width))

        val  = int(hex_raw, 16)
        bits = [(val >> i) & 1 for i in range(128)]
        # for i in range(3):
        #     print(i)
        #print("in_bits",bits)
        inputs[addr // 8].extend(bits)

    # 裁切到 N[i] 位
    for i in range(3):
        inputs[i] = inputs[i][: p["N"][i]]
    # ---------- 3. 计算数组 / 行数 / scramble ---------------
    gw = [tri_cols(p["E"][i]) for i in range(3)]
    gl = [math.ceil(p["L"][i] / 128) for i in range(3)]

    # interleave & combine
    inter = [
        interleave_bits(inputs[i], p["E"][i], p["S"][i], p["L"][i]) if p["EN"][i] else []
        for i in range(3)
    ]
    # mat  = combine_parts(inter, p["Q"])

    # # scramble
    # scr  = generate_scram_sequence(p["Cinit"], sum(p["L"]))
    # out  = scramble_and_group(mat, scr, p["Q"])
    # 行分配：写 caseN_rowx_part.mem，并得到行→part 列表
    row_owner = merge_parts(inter, p["Q"], case)

    # 生成扰码
    scr_bits  = generate_scram_sequence(p["Cinit"], sum(p["L"]))

    # 合并 + 异或 + 分组（得到 0x… 行列表）
    out_lines = scramble_and_group(case,inter, row_owner, scr_bits, p["Q"])

    # scramble_data 列数
    #scr_cols = len(mat[0]) if mat else 0
    #scr_lines= len(scr) 
    scr_lines= len(scr_bits) 
    print("scr_lines",scr_lines)
    #scr_num  = math.ceil(scr_cols / 12)
    scr_num  = math.ceil(scr_lines/ (12 * max(1, p["Q"])))
    print("scr_nums",scr_num)
    # ---------- 4. 把新字段塞回 params -----------
    p["GW"]       = gw
    p["GL"]       = gl
    p["SCR_NUM"]  = scr_num

    # ---------- 3. 处理流程 ----------
    inter = [
        interleave_bits(inputs[i], p["E"][i], p["S"][i], p["L"][i]) if p["EN"][i] else []
        for i in range(3)
    ]
    # mat  = combine_parts(inter, p["Q"])
    # scr  = generate_scram_sequence(p["Cinit"], sum(p["L"]))
    # out  = scramble_and_group(mat, scr, p["Q"])

     # 行分配：写 caseN_rowx_part.mem，并得到行→part 列表
    row_owner = merge_parts(inter, p["Q"], case)

    # 生成扰码
    scr_bits  = generate_scram_sequence(p["Cinit"], sum(p["L"]))

    # 合并 + 异或 + 分组（得到 0x… 行列表）
    out_lines = scramble_and_group(case,inter, row_owner, scr_bits, p["Q"])
    # ---------- 4. 写回普通目录 ----------
    
    write_define(case, p)                 # define
    write_input(case, inputs, layout)     # input —— 用 golden 布局

    write_intlv(case, inter)          # 仍写交织后 bit
    write_scram(case, scr_bits, p["Q"])   # 同上，只换变量名
    write_output(case, out_lines)     # 把 out_lines 原样写入

    # #write_intlv(case, mat)                # interleave
    # write_intlv(case, inter)                # interleave
    # #write_scram(case, scr)                # scramble code
    # write_scram(case, scr, p["Q"])
    # write_output(case, out)               # output


def verify_cases(cases=range(1, 5)):
    total_pass = True
    for case in cases:
        # 临时调试
        if case == 4 and "ics_output_data" in fname:
            with open(src) as a, open(gold) as b:
                print("filename",src, gold)
                # for i in range(10):
                #     print(f"{i:02}  gen : {a.readline().strip()}")
                #     print(f"    gold: {b.readline().strip()}")

        print(f"[VERIFY] Case{case} ...", end=" ")
        _regen_case_from_golden(case)
        diff_found = False
        # 仅比较 data 相关文件，省略 define 比对
        for fname in [
            f"ics_input_data{case}.txt",
            f"ics_intlv_out_data{case}.txt",
            f"ics_scram_code{case}.txt",
            f"ics_output_data{case}.txt",
        ]:
            src  = DATA_DIR / fname
            gold = DATA_GOLDEN_DIR / fname
            if not files_equal(src, gold, ignore_comment=False):
                diff_found = True
                print(f"    ✗ DIFF: {fname}")
        if diff_found:
            total_pass = False
            print("    ==> FAIL")
        else:
            print("PASS")
    if total_pass:
        print("[ALL PASS] Data files identical to golden.")
    else:
        print("[SOME FAIL] 请检查上面列出的差异文件。")

        # 仅比对 data 相关 4 个文件
        files = [
            (f"ics_input_data{case}.txt",      DATA_DIR, DATA_GOLDEN_DIR),
            (f"ics_intlv_out_data{case}.txt",  DATA_DIR, DATA_GOLDEN_DIR),
            (f"ics_scram_code{case}.txt",      DATA_DIR, DATA_GOLDEN_DIR),
            (f"ics_output_data{case}.txt",     DATA_DIR, DATA_GOLDEN_DIR),
        ]

        diff_found = False
        for fname, dstdir, gdir in files:
            src  = dstdir / fname
            gold = gdir   / fname
            if not files_equal(src, gold):
                diff_found = True
                print(f"\n    ✗ DIFF: {fname}")

        if diff_found:
            print("    ==> FAIL")
        else:
            print("    ==> PASS")

    if total_pass:
        print("\n[ALL PASS] Generated files identical to golden.")
    else:
        print("\n[SOME FAIL] 请检查上面列出的差异文件。")

# ----------- CLI ----------------------------

def main():
    ap = argparse.ArgumentParser("ICS testcase generator & verifier")
    sp = ap.add_subparsers(dest="mode", required=True)

    g = sp.add_parser("gen", help="generate cases >=5")
    g.add_argument("--count", type=int, default=1, help="生成 case 的数量 (从 case5 起)")

    sp.add_parser("verify", help="regenerate & compare golden cases 1‑4")

    args = ap.parse_args()
    if args.mode == "gen":
        gen_cases(args.count, start=5)
    else:  # verify
        verify_cases()

if __name__ == "__main__":
    main()
