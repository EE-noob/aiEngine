def generate_verilog_case_defines(total_cases=30, output_file=None):
    lines = []
    for i in range(1, total_cases + 1):
        directive = "`ifdef" if i == 1 else "`elsif"
        lines.append(f"{directive} ICS_CASE{i}")
        lines.append(f'  `include "define/case{i}_define.vh"')
    lines.append("`else")
    lines.append('`include "define/default_define.vh"')
    lines.append("`endif")

    result = "\n".join(lines)

    if output_file:
        with open(output_file, "w") as f:
            f.write(result)
        print(f"Verilog case defines written to: {output_file}")
    else:
        print(result)


if __name__ == "__main__":
    # 你可以改成其他数量或输出文件名
    generate_verilog_case_defines(total_cases=10, output_file="define_selector.sv")