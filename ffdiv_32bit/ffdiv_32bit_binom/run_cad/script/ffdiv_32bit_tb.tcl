
# Setting simulation configurations to generate database & probe signals
database -open ffdiv_32bit_tb -shm -event -into wave_database/ffdiv_32bit_tb.shm
probe -create ffdiv_32bit_tb -depth all -all -memories -all -variables -tasks -functions -shm -database ffdiv_32bit_tb
run
database -close ffdiv_32bit_tb
finish 2
