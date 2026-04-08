В данной лабораторной работе был реализован **"Тракт Данных"**. Были подключены уже созданные в предыдущих лабораторнх работах модули [АЛУ](https://github.com/MadMarvi/Tasks/tree/main/Miet/Alu), [декодер](https://github.com/MadMarvi/Tasks/tree/main/Miet/Main%20decoder), [регистровый файл](https://github.com/MadMarvi/Tasks/blob/main/Miet/Memory/register_file.sv), [память инструкций](https://github.com/MadMarvi/Tasks/blob/main/Miet/Memory/instr_mem.sv) и [память данных](https://github.com/MadMarvi/Tasks/blob/main/Miet/Data_memory/data_mem.sv).  
В файле [processor_core](https://github.com/MadMarvi/Tasks/blob/main/Miet/Datapath/processor_core.sv) реализована схема ниже 
![](https://raw.githubusercontent.com/MPSU/APS/7ebed1ded906b045d4da62139192230f624565c5/.pic/Labs/lab_07_dp/fig_01.drawio.svg) 
А в файле [processor_system](https://github.com/MadMarvi/Tasks/blob/main/Miet/Datapath/processor_system.sv) реализована данная схема   
![](https://github.com/MPSU/APS/blob/master/.pic/Labs/lab_07_dp/fig_02.drawio.svg)  
Подробнее о ходе выполнения и реализации в [репозитории  МИЭТа](https://github.com/MPSU/APS/tree/master/Labs/07.%20Datapath)
