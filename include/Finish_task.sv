 // ============================================================
  // Result Display Task
  // ============================================================
  task Finish(err_count,test_count);
  static string GREEN = "\033[1;32m";
  static string RED = "\033[1;31m";
  static string NC = "\033[0m";
  static string PASS_ASCII[$] = '{
    "██████╗  █████╗ ███████╗███████╗",
    "██╔══██╗██╔══██╗██╔════╝██╔════╝",
    "██████╔╝███████║███████╗███████╗",
    "██╔═══╝ ██╔══██║╚════██║╚════██║",
    "██║     ██║  ██║███████║███████║",
    "╚═╝     ╚═╝  ╚═╝╚══════╝╚══════╝"
  };
  static string FAIL_ASCII[$] = '{
    "███████╗ █████╗ ██╗██╗     ",
    "██╔════╝██╔══██╗██║██║     ",
    "█████╗  ███████║██║██║     ",
    "██╔══╝  ██╔══██║██║██║     ",
    "██║     ██║  ██║██║███████╗",
    "╚═╝     ╚═╝  ╚═╝╚═╝╚══════╝"
  };
  
  $display("\n////////////////////////////////////////////////////////////////////////////");
$display("%0t: Simulation ended, ERROR count: %0d, case: %d", $time, err_count, test_count);
  $display("////////////////////////////////////////////////////////////////////////////\n");
  
  if (err_count == 0) begin
    foreach (PASS_ASCII[i])
      $display("%s%s%s", GREEN, PASS_ASCII[i], NC);
  end else begin
    foreach (FAIL_ASCII[i])
      $display("%s%s%s", RED, FAIL_ASCII[i], NC);
  end
  
  $finish;
endtask