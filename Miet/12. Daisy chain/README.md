# Лабораторная работа №12. Блок приоритетных прерываний (daisy chain)

Реализован блок приоритетных прерываний `daisy_chain`, расширяющий контроллер прерываний до 16 источников со статическим приоритетом (0 — наивысший).

Модуль встроен в `interrupt_controller`, разрядность сигналов `irq_req_i`, `mie_i`, `irq_ret_o` увеличена до 16 бит, изменения отражены в `processor_core` и `processor_system`.

**Файлы:** `daisy_chain.sv`, `interrupt_controller.sv`, `processor_core.sv`, `processor_system.sv`.

**Проверено:** `lab_12.tb_daisy_chain.sv` (все ассерты), `lab_11.tb_processor_system.sv` (регресс).

