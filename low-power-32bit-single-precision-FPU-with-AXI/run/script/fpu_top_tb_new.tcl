
# Setting simulation configurations to generate database & probe signals
database -open fpu_top_tb_new -shm -event -into wave_database/fpu_top_tb_new.shm
probe -create fpu_top_tb_new -depth all -all -memories -all -variables -tasks -functions -shm -database fpu_top_tb_new
run
database -close fpu_top_tb_new
finish 2
