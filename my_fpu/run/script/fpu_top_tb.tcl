
# Setting simulation configurations to generate database & probe signals
database -open fpu_top_tb -shm -event -into wave_database/fpu_top_tb.shm
probe -create fpu_top_tb -depth all -all -memories -all -variables -tasks -functions -shm -database fpu_top_tb
run
database -close fpu_top_tb
finish 2
