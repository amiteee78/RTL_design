irun 	-access +rwc  \
			+fsmdebug 		\
			-disable_sem2009 \
			-timescale 1ns/1ns \
			-incdir ../rtl/ \
			-incdir ../tb/ \
			-sv ../rtl/*.v \
			-sysv ../tb/$1_tb.sv \
			-covfile $1_cov.ccf \
			-coverage A \
			-covdut $1_tb \
			-covoverwrite	\
			-covtest $1_test

chmod 775 * -R
