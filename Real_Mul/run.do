# run.do - сборка и запуск проекта real_mul (все файлы в одной папке)
quit -sim -force

if {[file exists work]} {
    vdel -all -lib work
}
vlib work
vmap work work

vlog -reportprogress 300 -work work \
    Op_Analyzer.v \
    Pre_res.v \
    rounding_module.v \
    Exp_corr.v \
    real_mul.v \
    tb_real_mul.v

vsim -voptargs=+acc work.tb_real_mul

add wave -radix hex sim:/tb_real_mul/dut_single/*
add wave -radix hex sim:/tb_real_mul/dut_double/*

run -all

quit -sim
