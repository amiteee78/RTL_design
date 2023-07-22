
# Setting simulation configurations to generate database & probe signals
database -open fcast_tb -shm -event -into wave_database/fcast_tb.shm
probe -create fcast_tb -depth all -all -memories -all -variables -tasks -functions -shm -database fcast_tb
run
database -close fcast_tb
finish 2
