`ifndef ICB_ENV__SV
`define ICB_ENV__SV

class icb_env extends uvm_env;

    // -------------------------------------------------------
    // Agent & scoreboard 声明
    // -------------------------------------------------------
    icb_sa_agent      sa_agt;   // 上游 SA agent
    icb_m_agent       m_agt;    // 下游 M  agent
    icb_scb           scb;      // Scoreboard

    // -------------------------------------------------------
    // Analysis fifos
    // -------------------------------------------------------
    uvm_tlm_analysis_fifo #(icb_mon_tr) sa_scb_fifo;  // SA → SCB
    uvm_tlm_analysis_fifo #(icb_mon_tr) m_scb_fifo;   // M  → SCB

    // -------------------------------------------------------
    // 构造函数
    // -------------------------------------------------------
    function new(string name = "icb_env", uvm_component parent);
        super.new(name, parent);
    endfunction

    // -------------------------------------------------------
    // build_phase
    // -------------------------------------------------------
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        sa_agt   = icb_sa_agent ::type_id::create("sa_agt", this);
        m_agt    = icb_m_agent  ::type_id::create("m_agt" , this);
        scb      = icb_scb      ::type_id::create("scb"   , this);

        sa_scb_fifo = new("sa_scb_fifo", this);
        m_scb_fifo  = new("m_scb_fifo" , this);
    endfunction

    // -------------------------------------------------------
    // connect_phase
    // -------------------------------------------------------
    extern virtual function void connect_phase(uvm_phase phase);

    `uvm_component_utils(icb_env)
endclass : icb_env

// -----------------------------------------------------------
// connect_phase 定义
// -----------------------------------------------------------
function void icb_env::connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    uvm_root::get().print_topology();

    // SA monitor → sa_scb_fifo
    sa_agt.monitor.ap.connect(sa_scb_fifo.analysis_export);
    // M  monitor → m_scb_fifo
    m_agt.monitor.ap.connect(m_scb_fifo.analysis_export);

    // SCB: exp = SA, act = M
    scb.exp_port.connect(sa_scb_fifo.blocking_get_export);
    scb.act_port.connect(m_scb_fifo.blocking_get_export);
endfunction

`endif
