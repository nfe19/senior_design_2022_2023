transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -vlog01compat -work work +incdir+C:/Users/aleja/Desktop/ControlModule_TestSim {C:/Users/aleja/Desktop/ControlModule_TestSim/bimpy.v}
vlog -vlog01compat -work work +incdir+C:/Users/aleja/Desktop/ControlModule_TestSim {C:/Users/aleja/Desktop/ControlModule_TestSim/bitreverse.v}
vlog -vlog01compat -work work +incdir+C:/Users/aleja/Desktop/ControlModule_TestSim {C:/Users/aleja/Desktop/ControlModule_TestSim/butterfly.v}
vlog -vlog01compat -work work +incdir+C:/Users/aleja/Desktop/ControlModule_TestSim {C:/Users/aleja/Desktop/ControlModule_TestSim/convround.v}
vlog -vlog01compat -work work +incdir+C:/Users/aleja/Desktop/ControlModule_TestSim {C:/Users/aleja/Desktop/ControlModule_TestSim/fftstage.v}
vlog -vlog01compat -work work +incdir+C:/Users/aleja/Desktop/ControlModule_TestSim {C:/Users/aleja/Desktop/ControlModule_TestSim/laststage.v}
vlog -vlog01compat -work work +incdir+C:/Users/aleja/Desktop/ControlModule_TestSim {C:/Users/aleja/Desktop/ControlModule_TestSim/longbimpy.v}
vlog -vlog01compat -work work +incdir+C:/Users/aleja/Desktop/ControlModule_TestSim {C:/Users/aleja/Desktop/ControlModule_TestSim/qtrstage.v}
vlog -vlog01compat -work work +incdir+C:/Users/aleja/Desktop/ControlModule_TestSim {C:/Users/aleja/Desktop/ControlModule_TestSim/FFT_Module.v}
vlog -vlog01compat -work work +incdir+C:/Users/aleja/Desktop/ControlModule_TestSim {C:/Users/aleja/Desktop/ControlModule_TestSim/ToneDetector_Module.v}
vlog -vlog01compat -work work +incdir+C:/Users/aleja/Desktop/ControlModule_TestSim {C:/Users/aleja/Desktop/ControlModule_TestSim/Control_Module.v}
vlog -vlog01compat -work work +incdir+C:/Users/aleja/Desktop/ControlModule_TestSim {C:/Users/aleja/Desktop/ControlModule_TestSim/ToneLUT.v}
vlog -vlog01compat -work work +incdir+C:/Users/aleja/Desktop/ControlModule_TestSim {C:/Users/aleja/Desktop/ControlModule_TestSim/Magnitude.v}

vlog -sv -work work +incdir+C:/Users/aleja/Desktop/ControlModule_TestSim {C:/Users/aleja/Desktop/ControlModule_TestSim/Control_ModuleTB.sv}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L cyclonev_ver -L cyclonev_hssi_ver -L cyclonev_pcie_hip_ver -L rtl_work -L work -voptargs="+acc"  Control_ModuleTB

add wave *
view structure
view signals
run -all
