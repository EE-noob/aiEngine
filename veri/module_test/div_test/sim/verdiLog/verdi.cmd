simSetSimulator "-vcssv" -exec \
           "/home/ICer/ic_prjs/HW_ICS/veri/module_test/div_test/sim/simv" \
           -args \
           "-cm line+cond+tgl+fsm +ntb_random_seed_automatic +UVM_TESTNAME=ics_base_test +UVM_VERBOSITY=UVM_LOW +UVM_TREE"
debImport "-dbdir" \
          "/home/ICer/ic_prjs/HW_ICS/veri/module_test/div_test/sim/simv.daidir"
debLoadSimResult \
           /home/ICer/ic_prjs/HW_ICS/veri/module_test/div_test/sim/wave1.fsdb
wvCreateWindow
srcHBSelect "tb_serial_divider.uut" -win $_nTrace1
srcSetScope -win $_nTrace1 "tb_serial_divider.uut" -delim "."
srcHBSelect "tb_serial_divider.uut" -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -win $_nTrace1 -range {2 10 2 1 4 1} -backward
srcAddSelectedToWave -clipboard -win $_nTrace1
wvDrop -win $_nWave2
wvZoomIn -win $_nWave2
wvZoomIn -win $_nWave2
wvZoomIn -win $_nWave2
wvZoomIn -win $_nWave2
wvZoomIn -win $_nWave2
wvZoomIn -win $_nWave2
wvZoomIn -win $_nWave2
wvZoomIn -win $_nWave2
wvZoomIn -win $_nWave2
wvZoomIn -win $_nWave2
wvZoomIn -win $_nWave2
wvZoomIn -win $_nWave2
wvCenterCursor -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvSelectSignal -win $_nWave2 {( "G1" 6 )} 
wvZoomIn -win $_nWave2
wvZoomIn -win $_nWave2
wvCenterCursor -win $_nWave2
wvSetCursor -win $_nWave2 187744.108711 -snap {("G1" 6)}
wvSetCursor -win $_nWave2 372664.997743 -snap {("G1" 6)}
wvSetCursor -win $_nWave2 396662.365021 -snap {("G1" 3)}
wvZoomIn -win $_nWave2
wvCenterCursor -win $_nWave2
wvCenterCursor -win $_nWave2
