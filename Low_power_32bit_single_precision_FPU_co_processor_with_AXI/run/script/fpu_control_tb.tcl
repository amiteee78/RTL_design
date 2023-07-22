
# Setting simulation configurations to generate database & probe signals
database -open fpu_control_tb -shm -event -into wave_database/fpu_control_tb.shm
probe -create fpu_control_tb -depth all -all -memories -all -variables -tasks -functions -shm -database fpu_control_tb
run
database -close fpu_control_tb
finish 2
