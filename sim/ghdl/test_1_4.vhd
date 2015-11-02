-----------------------------------------------------------------------------------
--!     @file    test_1_4.vhd
--!     @brief   TEST BENCH for PTTY_AXI4
--!     @version 0.2.0
--!     @date    2015/11/2
--!     @author  Ichiro Kawazome <ichiro_k@ca2.so-net.ne.jp>
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
entity  TEST_1_4 is
end     TEST_1_4;
architecture MODEL of TEST_1_4 is
    component TEST_BENCH is
        generic (
            NAME            : STRING;
            SCENARIO_FILE   : STRING;
            RXD_BYTES       : positive;
            TXD_BYTES       : positive
        );
    end component;
begin
    TB: TEST_BENCH generic map(NAME => "TEST_1_4", SCENARIO_FILE => "../../src/test/scenarios/test_1_4.snr", RXD_BYTES => 4, TXD_BYTES => 4);
end MODEL;

