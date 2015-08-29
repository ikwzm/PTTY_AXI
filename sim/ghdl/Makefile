GHDL=ghdl
GHDLFLAGS=--mb-comments -P../../PipeWork/sim/ghdl -P../../Dummy_Plug/sim/ghdl/dummy_plug

SRC_MAIN_PATH = ../../src/main/vhdl
SRC_TEST_PATH = ../../src/test/vhdl

TEST_BENCH    = test_1 \
                test_2 \
                $(END_LIST)

all: $(TEST_BENCH)

.PHONY : clean $(TEST_BENCH)

clean:
	rm -f *.o *.cf $(TEST_BENCH)

test_1       : test_1.o ../../src/test/scenarios/test_1.snr
	 $(GHDL) -e $(GHDLFLAGS) --work=work $@
	-$(GHDL) -r $(GHDLFLAGS) --work=work $@

test_2       : test_2.o ../../src/test/scenarios/test_2.snr
	 $(GHDL) -e $(GHDLFLAGS) --work=work $@
	-$(GHDL) -r $(GHDLFLAGS) --work=work $@

test_1.o       : test_1.vhd test_bench.o ptty_axi4.o ptty_tx.o ptty_rx.o ptty_rxd_buf.o ptty_txd_buf.o
	 $(GHDL) -a $(GHDLFLAGS) --work=work $<

test_2.o       : test_2.vhd test_bench.o ptty_axi4.o ptty_tx.o ptty_rx.o ptty_rxd_buf.o ptty_txd_buf.o
	 $(GHDL) -a $(GHDLFLAGS) --work=work $<

test_bench.o   : $(SRC_TEST_PATH)/test_bench.vhd
	 $(GHDL) -a $(GHDLFLAGS) --work=work $<

ptty_axi4.o    : $(SRC_MAIN_PATH)/ptty_axi4.vhd
	 $(GHDL) -a $(GHDLFLAGS) --work=work $<

ptty_tx.o      : $(SRC_MAIN_PATH)/ptty_tx.vhd
	 $(GHDL) -a $(GHDLFLAGS) --work=work $<

ptty_rx.o      : $(SRC_MAIN_PATH)/ptty_rx.vhd
	 $(GHDL) -a $(GHDLFLAGS) --work=work $<

ptty_txd_buf.o : $(SRC_MAIN_PATH)/ptty_txd_buf.vhd
	 $(GHDL) -a $(GHDLFLAGS) --work=work $<

ptty_rxd_buf.o : $(SRC_MAIN_PATH)/ptty_rxd_buf.vhd
	 $(GHDL) -a $(GHDLFLAGS) --work=work $<

