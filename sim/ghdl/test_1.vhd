-----------------------------------------------------------------------------------
--!     @file    test_1.vhd
--!     @brief   TEST BENCH for PTTY_AXI4
--!     @version 0.1.0
--!     @date    2015/8/20
--!     @author  Ichiro Kawazome <ichiro_k@ca2.so-net.ne.jp>
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
entity  TEST_1 is
end     TEST_1;
architecture MODEL of TEST_1 is
    component TEST_BENCH is
        generic (
            NAME            : STRING;
            SCENARIO_FILE   : STRING
        );
    end component;
begin
    TB: TEST_BENCH generic map(NAME => "TEST_1", SCENARIO_FILE => "../../src/test/scenarios/test_1.snr");
end MODEL;

