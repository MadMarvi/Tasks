# Лабораторная работа №13. Периферийные устройства

Индивидуальный вариант: **PS/2-клавиатура → семисегментные индикаторы**.

Реализованы контроллеры `ps2_sb_ctrl` (приём скан-кодов, прерывание по нажатию клавиши) и `hex_sb_ctrl` (регистры `hex0-hex7`, `bitmask`, вывод через `hex_digits`). Оба подключены в `processor_system` через единую системную шину с унитарным дешифратором адреса; добавлен `sys_clk_rst_gen` (10 МГц) и порты периферии верхнего уровня (в т.ч. незадействованные в этом варианте — sw/led/uart/vga).

PS/2 сидит на нулевой линии контроллера прерываний (`mie = 0x00010000`), реализованного `csr_controller` + `interrupt_controller`.

## Состав проекта

**Design Sources:**
```
memory_pkg.sv
peripheral_pkg.sv
decoder_pkg.sv
alu_opcodes_pkg.sv
csr_pkg.sv
fulladder.sv
fulladder32.sv
alu.sv
register_file.sv
decoder.sv
csr_controller.sv
interrupt_controller.sv
processor_core.sv
instr_mem.sv
data_mem.sv
lsu.sv
sys_clk_rst_gen.sv
PS2Receiver.sv
ps2_sb_ctrl.sv
hex_digits.sv
hex_sb_ctrl.sv
processor_system.sv
```

**Simulation Sources:** `lab_13_tb_processor_system.sv` (top для симуляции).

**Прошивка:** `lab_13_ps2_hex_instr.mem` — переименовать в `program.mem` и положить по пути `C:\Lab_Miet\program.mem` (путь жёстко зашит в `instr_mem.sv` через `$readmemh`, так как относительные пути нестабильно резолвятся между симуляторами).

