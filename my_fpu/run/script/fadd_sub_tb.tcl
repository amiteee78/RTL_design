
# Setting simulation configurations to generate database & probe signals
database -open fadd_sub_tb -shm -event -into wave_database/fadd_sub_tb.shm
probe -create fadd_sub_tb -depth all -all -memories -all -variables -tasks -functions -shm -database fadd_sub_tb
run
database -close fadd_sub_tb
finish 2
