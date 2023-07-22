
# Setting simulation configurations to generate database & probe signals
database -open run_fpu_top.sh -shm -event -into wave_database/run_fpu_top.sh.shm
probe -create run_fpu_top.sh -depth all -all -memories -all -variables -tasks -functions -shm -database run_fpu_top.sh
run
database -close run_fpu_top.sh
finish 2
