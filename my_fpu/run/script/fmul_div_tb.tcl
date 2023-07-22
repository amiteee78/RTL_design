
# Setting simulation configurations to generate database & probe signals
database -open fmul_div_tb -shm -event -into wave_database/fmul_div_tb.shm
probe -create fmul_div_tb -depth all -all -memories -all -variables -tasks -functions -shm -database fmul_div_tb
run
database -close fmul_div_tb
finish 2
