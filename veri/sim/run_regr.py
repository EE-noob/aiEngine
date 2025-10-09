import subprocess
import re
import os
import concurrent.futures
import time

LOG_DIR = "./logs"
MAKE_RUN_CMD = "make run CASE={case}"
MAKE_CLEAN_CMD = "make clean"

START_CASE = 1
END_CASE = 10
MAX_WORKERS = 10  # 可调：根据 CPU 核心数/仿真资源限制设定

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

def normalize_block(block_text):
    """
    可选：归一化 error block，使去重更稳健。
    去除时间戳、路径中的数字等（视情况可删减）
    """
    # 去掉时间戳或数值（根据你实际情况微调）
    return re.sub(r"@\s*\d+", "@ TIME", block_text)

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

    error_blocks = []
    filtered_fail = False  # 真正判断是否 FAIL 的标志
    seen_blocks = set()    # 去重用的 set

    if is_fail:
        lines = log_text.splitlines()
        n = len(lines)
        i = 0
        while i < n:
            line = lines[i]
            if ("UVM_ERROR" in line or "UVM_FATAL" in line) \
               and not re.match(r"\s*UVM_(FATAL|ERROR)\s*:", line) \
               and "Number of" not in line:

                block_lines = [lines[i]]
                i += 1
                while i < n and (lines[i].startswith(" ") or lines[i].startswith("\t")):
                    block_lines.append(lines[i])
                    i += 1

                block_text = "\n".join(block_lines)
                norm_block = normalize_block(block_text)

                if norm_block not in seen_blocks:
                    seen_blocks.add(norm_block)
                    error_blocks.append(block_text)

                # 只要不是 INTLV_FILO_PASS_RATE，就算真正 FAIL
                if "[INTLV_FILO_PASS_RATE]" not in line:
                    filtered_fail = True
            else:
                i += 1

    final_status = "FAIL" if (fatal_count > 0 or filtered_fail) else "PASS"
    return final_status, error_blocks

def main():
    start_time = time.time()  # ✅ 记录起始时间
    run_make_clean()

    case_ids = range(START_CASE, END_CASE + 1)
    results = []

    with concurrent.futures.ThreadPoolExecutor(max_workers=MAX_WORKERS) as executor:
        future_to_case = {executor.submit(run_case, case_id): case_id for case_id in case_ids}

        for future in concurrent.futures.as_completed(future_to_case):
            case_id = future_to_case[future]
            try:
                case, status, error_lines = future.result()
                results.append((case, status, error_lines))
                print(f"[Case {case}] Result: {status}")
                if status == "FAIL" and error_lines:
                    print("  Error details:")
                    for line in error_lines:
                        print(f"    {line}")
            except Exception as exc:
                print(f"[Case {case_id}] Exception occurred: {exc}")
                results.append((case_id, "FAIL", [str(exc)]))

    end_time = time.time()  # ✅ 记录结束时间
    duration = end_time - start_time

    # 汇总报告
    print("\n=== Regression Summary ===")
    total_cases = len(results)
    pass_count = sum(1 for _, s, _ in results if s == "PASS")
    fail_cases = [(c, errs) for c, s, errs in results if s == "FAIL"]

    print(f"Total cases: {total_cases}")
    print(f"PASS: {pass_count}")
    print(f"FAIL: {len(fail_cases)}")
    print(f"PASS rate: {pass_count / total_cases * 100:.2f}%")  # ✅ PASS率输出
    print(f"Total time: {duration:.2f} seconds")                # ✅ 总时间输出

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
