
# Setting simulation configurations to generate database & probe signals
database -open fpu_dec_tb -shm -event -into wave_database/fpu_dec_tb.shm
probe -create fpu_dec_tb -depth all -all -memories -all -variables -tasks -functions -shm -database fpu_dec_tb
run
database -close fpu_dec_tb
finish 2
