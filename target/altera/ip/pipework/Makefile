.PHONY: pipework_altera.vhd

pipework_altera.vhd : 
	../../../../PipeWork/tools/vhdl-archiver.rb -v  \
            --library PipeWork                    \
            --use 'SDPRAM(ALTERA_AUTO_SELECT)'    \
            --use 'QUEUE_ARBITER(INTEGER_ARCH)'   \
            --archive pipework_altera.vhd         \
            ../../../../PipeWork/src/             \
