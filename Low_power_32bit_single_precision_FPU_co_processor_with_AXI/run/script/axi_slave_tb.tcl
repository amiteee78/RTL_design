
# Setting simulation configurations to generate database & probe signals
database -open axi_slave_tb -shm -event -into wave_database/axi_slave_tb.shm
probe -create axi_slave_tb -depth all -all -memories -all -variables -tasks -functions -shm -database axi_slave_tb
run
database -close axi_slave_tb
finish 2
