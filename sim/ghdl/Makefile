GHDL=ghdl
GHDLFLAGS=--mb-comments -P../../PipeWork/sim/ghdl -P../../Dummy_Plug/sim/ghdl/dummy_plug

SRC_MAIN_PATH = ../../src/main/vhdl
SRC_TEST_PATH = ../../src/test/vhdl

TEST_BENCH    = test_bench \
                $(END_LIST)

all: $(TEST_BENCH)

clean:
	rm -f *.o *.cf $(TEST_BENCH)

$(TEST_BENCH) : $(addsuffix .o,$(TEST_BENCH)) ptty_axi4.o ptty_send.o ptty_recv.o recv_buf.o send_buf.o
	 $(GHDL) -e $(GHDLFLAGS) --work=work $@
	-$(GHDL) -r $(GHDLFLAGS) --work=work $@

test_bench.o : $(SRC_TEST_PATH)/test_bench.vhd
	 $(GHDL) -a $(GHDLFLAGS) --work=work $<

ptty_axi4.o  : $(SRC_MAIN_PATH)/ptty_axi4.vhd
	 $(GHDL) -a $(GHDLFLAGS) --work=work $<

ptty_send.o  : $(SRC_MAIN_PATH)/ptty_send.vhd
	 $(GHDL) -a $(GHDLFLAGS) --work=work $<

ptty_recv.o  : $(SRC_MAIN_PATH)/ptty_recv.vhd
	 $(GHDL) -a $(GHDLFLAGS) --work=work $<

send_buf.o   : $(SRC_MAIN_PATH)/send_buf.vhd
	 $(GHDL) -a $(GHDLFLAGS) --work=work $<

recv_buf.o   : $(SRC_MAIN_PATH)/recv_buf.vhd
	 $(GHDL) -a $(GHDLFLAGS) --work=work $<

