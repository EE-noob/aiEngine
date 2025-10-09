import subprocess
import re
import os

LOG_DIR = "./logs"
MAKE_RUN_CMD = "make run CASE={case}"
MAKE_CLEAN_CMD = "make clean"

START_CASE = 1
END_CASE = 4

def run_make_clean():
    print("Running make clean ...")
    subprocess.run(MAKE_CLEAN_CMD, shell=True)

def run_case(case_id):
    print(f"\n[Case {case_id}] Running...")

    # 执行 make run
    proc = subprocess.run(MAKE_RUN_CMD.format(case=case_id), shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, universal_newlines=True)
    log_text = proc.stdout

    # 保存日志
    os.makedirs(LOG_DIR, exist_ok=True)
    log_path = os.path.join(LOG_DIR, f"case_{case_id}.log")
    # with open(log_path, "w") as f:
    #     f.write(log_text)

    # 判断结果并提取错误行
    status, error_lines = check_uvm_errors(log_text)

    # 如果失败，保存错误log
    if status == "FAIL":
        with open(os.path.join(LOG_DIR, f"fail_case_{case_id}.log"), "w") as f:
            f.write(log_text)

    return case_id, status, error_lines

def check_uvm_errors(log_text):
    # 提取 summary 部分
    summary_match = re.search(r"-+ UVM Report Summary -+(.+?)\n\n", log_text, re.DOTALL)
    if not summary_match:
        return "FAIL", ["无法找到 UVM Report Summary"]

    summary_text = summary_match.group(1)

    # 统计数量
    error_match = re.search(r"UVM_ERROR\s*:\s*(\d+)", summary_text)
    fatal_match = re.search(r"UVM_FATAL\s*:\s*(\d+)", summary_text)

    error_count = int(error_match.group(1)) if error_match else 0
    fatal_count = int(fatal_match.group(1)) if fatal_match else 0

    is_fail = (error_count > 0 or fatal_count > 0)

    # 提取错误所在行（排除 summary 和统计类文字）
    error_lines = []
    if is_fail:
        for line in log_text.splitlines():
            line = line.strip()
            if ("UVM_FATAL" in line or "UVM_ERROR" in line) \
               and not re.match(r"\s*UVM_(FATAL|ERROR)\s*:", line) \
               and "Number of" not in line:
                error_lines.append(line)

    return ("FAIL" if is_fail else "PASS"), error_lines

def main():
    run_make_clean()

    results = []
    for case_id in range(START_CASE, END_CASE + 1):
        case, status, error_lines = run_case(case_id)
        results.append((case, status, error_lines))
        print(f"[Case {case}] Result: {status}")
        if status == "FAIL" and error_lines:
            print("  Error details:")
            for line in error_lines:
                print(f"    {line}")

    # 汇总报告
    print("\n=== Regression Summary ===")
    pass_count = sum(1 for _, s, _ in results if s == "PASS")
    fail_cases = [(c, errs) for c, s, errs in results if s == "FAIL"]

    print(f"Total cases: {len(results)}")
    print(f"PASS: {pass_count}")
    print(f"FAIL: {len(fail_cases)}")

    if fail_cases:
        summary_path = os.path.join(LOG_DIR, "fail_summary.txt")
        with open(summary_path, "w") as f:
            f.write("--- Failed Cases Summary ---\n\n")
            for case_id, errors in fail_cases:
                f.write(f"Case {case_id}:\n")
                for err in errors:
                    f.write(f"  {err}\n")
                f.write("\n")
        print(f"\nFail summary written to: {summary_path}")
    else:
        print("All cases PASS 🎉")

if __name__ == "__main__":
    main()