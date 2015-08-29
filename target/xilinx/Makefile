VIVADO         = echo vivado
SRC_MAIN_PATH  = ../../src/main/vhdl
SRC_MAIN_FILES = $(SRC_MAIN_PATH)/ptty_txd_buf.vhd \
                 $(SRC_MAIN_PATH)/ptty_tx.vhd      \
                 $(SRC_MAIN_PATH)/ptty_rxd_buf.vhd \
                 $(SRC_MAIN_PATH)/ptty_rx.vhd      \
                 $(SRC_MAIN_PATH)/ptty_axi4.vhd    \
                 $(END_LIST)

.PHONY: ip-package

ip-package : sources
	$(VIVADO) -mode batch -source create_ip.tcl

sources : $(SRC_MAIN_FILES) 
	../../PipeWork/tools/vhdl-archiver.rb -v  \
                                                  \
            --library PipeWork                    \
            --use 'SDPRAM(XILINX_AUTO_SELECT)'    \
            --use 'QUEUE_ARBITER(INTEGER_ARCH)'   \
            --archive work/src/ptty_pipework.vhd  \
            ../../PipeWork/src/                   \
                                                  \
            --library WORK                        \
            --archive work/src/ptty_axi4.vhd      \
            --top    PTTY_AXI4                    \
            ../../src/main/vhdl/


