
# Setting simulation configurations to generate database & probe signals
database -open fround_tb -shm -event -into wave_database/fround_tb.shm
probe -create fround_tb -depth all -all -memories -all -variables -tasks -functions -shm -database fround_tb
run
database -close fround_tb
finish 2
