
# Setting simulation configurations to generate database & probe signals
database -open fpu_enc_tb -shm -event -into wave_database/fpu_enc_tb.shm
probe -create fpu_enc_tb -depth all -all -memories -all -variables -tasks -functions -shm -database fpu_enc_tb
run
database -close fpu_enc_tb
finish 2
