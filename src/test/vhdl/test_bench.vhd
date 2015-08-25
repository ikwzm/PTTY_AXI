-----------------------------------------------------------------------------------
--!     @file    test_bench.vhd
--!     @brief   TEST BENCH for PTTY_AXI4
--!     @version 0.1.0
--!     @date    2015/8/20
--!     @author  Ichiro Kawazome <ichiro_k@ca2.so-net.ne.jp>
-----------------------------------------------------------------------------------
--
--      Copyright (C) 2015 Ichiro Kawazome
--      All rights reserved.
--
--      Redistribution and use in source and binary forms, with or without
--      modification, are permitted provided that the following conditions
--      are met:
--
--        1. Redistributions of source code must retain the above copyright
--           notice, this list of conditions and the following disclaimer.
--
--        2. Redistributions in binary form must reproduce the above copyright
--           notice, this list of conditions and the following disclaimer in
--           the documentation and/or other materials provided with the
--           distribution.
--
--      THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
--      "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
--      LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
--      A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT
--      OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
--      SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
--      LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
--      DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
--      THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
--      (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
--      OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
use     std.textio.all;
library DUMMY_PLUG;
use     DUMMY_PLUG.AXI4_TYPES.all;
use     DUMMY_PLUG.AXI4_MODELS.AXI4_MASTER_PLAYER;
use     DUMMY_PLUG.AXI4_MODELS.AXI4_STREAM_MASTER_PLAYER;
use     DUMMY_PLUG.AXI4_MODELS.AXI4_STREAM_SLAVE_PLAYER;
use     DUMMY_PLUG.AXI4_MODELS.AXI4_SIGNAL_PRINTER;
use     DUMMY_PLUG.SYNC.all;
use     DUMMY_PLUG.CORE.MARCHAL;
use     DUMMY_PLUG.CORE.REPORT_STATUS_TYPE;
use     DUMMY_PLUG.CORE.REPORT_STATUS_VECTOR;
use     DUMMY_PLUG.CORE.MARGE_REPORT_STATUS;
-----------------------------------------------------------------------------------
--
-----------------------------------------------------------------------------------
entity  TEST_BENCH is
    generic (
        NAME            : STRING := "TEST";
        SCENARIO_FILE   : STRING := "test_1.snr"
    );
end     TEST_BENCH;
-----------------------------------------------------------------------------------
--
-----------------------------------------------------------------------------------
architecture MODEL of TEST_BENCH is
    -------------------------------------------------------------------------------
    -- 各種定数
    -------------------------------------------------------------------------------
    constant C_CLK_PERIOD    : time    := 10 ns;
    constant I_CLK_PERIOD    : time    := 10 ns;
    constant O_CLK_PERIOD    : time    := 10 ns;
    constant DELAY           : time    :=  1 ns;
    constant AXI4_ADDR_WIDTH : integer := 32;
    constant AXI4_DATA_WIDTH : integer := 32;
    constant C_WIDTH         : AXI4_SIGNAL_WIDTH_TYPE := (
                                 ID          => 4,
                                 AWADDR      => AXI4_ADDR_WIDTH,
                                 ARADDR      => AXI4_ADDR_WIDTH,
                                 WDATA       => AXI4_DATA_WIDTH,
                                 RDATA       => AXI4_DATA_WIDTH,
                                 ALEN        => AXI4_ALEN_WIDTH,
                                 ALOCK       => AXI4_ALOCK_WIDTH,
                                 ARUSER      => 1,
                                 AWUSER      => 1,
                                 WUSER       => 1,
                                 RUSER       => 1,
                                 BUSER       => 1);
    constant I_BYTES         : integer :=  1;
    constant I_WIDTH         : AXI4_STREAM_SIGNAL_WIDTH_TYPE := (
                                 ID          => 4,
                                 USER        => 4,
                                 DEST        => 4,
                                 DATA        => 8*I_BYTES);
    constant O_BYTES         : integer :=  1;
    constant O_WIDTH         : AXI4_STREAM_SIGNAL_WIDTH_TYPE := (
                                 ID          => 4,
                                 USER        => 4,
                                 DEST        => 4,
                                 DATA        => 8*O_BYTES);
    constant SYNC_WIDTH      : integer :=  2;
    constant GPO_WIDTH       : integer :=  8;
    constant GPI_WIDTH       : integer :=  GPO_WIDTH;
    constant SBUF_DEPTH      : integer :=  8;
    constant RBUF_DEPTH      : integer :=  8;
    -------------------------------------------------------------------------------
    -- グローバルシグナル.
    -------------------------------------------------------------------------------
    signal   C_CLK           : std_logic;
    signal   ARESETn         : std_logic;
    signal   RESET           : std_logic;
    signal   C_IRQ           : std_logic;
    ------------------------------------------------------------------------------
    -- リードアドレスチャネルシグナル.
    ------------------------------------------------------------------------------
    signal   C_ARADDR        : std_logic_vector(C_WIDTH.ARADDR -1 downto 0);
    signal   C_ARWRITE       : std_logic;
    signal   C_ARLEN         : std_logic_vector(C_WIDTH.ALEN   -1 downto 0);
    signal   C_ARSIZE        : AXI4_ASIZE_TYPE;
    signal   C_ARBURST       : AXI4_ABURST_TYPE;
    signal   C_ARLOCK        : std_logic_vector(C_WIDTH.ALOCK  -1 downto 0);
    signal   C_ARCACHE       : AXI4_ACACHE_TYPE;
    signal   C_ARPROT        : AXI4_APROT_TYPE;
    signal   C_ARQOS         : AXI4_AQOS_TYPE;
    signal   C_ARREGION      : AXI4_AREGION_TYPE;
    signal   C_ARUSER        : std_logic_vector(C_WIDTH.ARUSER -1 downto 0);
    signal   C_ARID          : std_logic_vector(C_WIDTH.ID     -1 downto 0);
    signal   C_ARVALID       : std_logic;
    signal   C_ARREADY       : std_logic;
    -------------------------------------------------------------------------------
    -- リードデータチャネルシグナル.
    -------------------------------------------------------------------------------
    signal   C_RVALID        : std_logic;
    signal   C_RLAST         : std_logic;
    signal   C_RDATA         : std_logic_vector(C_WIDTH.RDATA  -1 downto 0);
    signal   C_RRESP         : AXI4_RESP_TYPE;
    signal   C_RUSER         : std_logic_vector(C_WIDTH.RUSER  -1 downto 0);
    signal   C_RID           : std_logic_vector(C_WIDTH.ID     -1 downto 0);
    signal   C_RREADY        : std_logic;
    -------------------------------------------------------------------------------
    -- ライトアドレスチャネルシグナル.
    -------------------------------------------------------------------------------
    signal   C_AWADDR        : std_logic_vector(C_WIDTH.AWADDR -1 downto 0);
    signal   C_AWLEN         : std_logic_vector(C_WIDTH.ALEN   -1 downto 0);
    signal   C_AWSIZE        : AXI4_ASIZE_TYPE;
    signal   C_AWBURST       : AXI4_ABURST_TYPE;
    signal   C_AWLOCK        : std_logic_vector(C_WIDTH.ALOCK  -1 downto 0);
    signal   C_AWCACHE       : AXI4_ACACHE_TYPE;
    signal   C_AWPROT        : AXI4_APROT_TYPE;
    signal   C_AWQOS         : AXI4_AQOS_TYPE;
    signal   C_AWREGION      : AXI4_AREGION_TYPE;
    signal   C_AWUSER        : std_logic_vector(C_WIDTH.AWUSER -1 downto 0);
    signal   C_AWID          : std_logic_vector(C_WIDTH.ID     -1 downto 0);
    signal   C_AWVALID       : std_logic;
    signal   C_AWREADY       : std_logic;
    -------------------------------------------------------------------------------
    -- ライトデータチャネルシグナル.
    -------------------------------------------------------------------------------
    signal   C_WLAST         : std_logic;
    signal   C_WDATA         : std_logic_vector(C_WIDTH.WDATA  -1 downto 0);
    signal   C_WSTRB         : std_logic_vector(C_WIDTH.WDATA/8-1 downto 0);
    signal   C_WUSER         : std_logic_vector(C_WIDTH.WUSER  -1 downto 0);
    signal   C_WID           : std_logic_vector(C_WIDTH.ID     -1 downto 0);
    signal   C_WVALID        : std_logic;
    signal   C_WREADY        : std_logic;
    -------------------------------------------------------------------------------
    -- ライト応答チャネルシグナル.
    -------------------------------------------------------------------------------
    signal   C_BRESP         : AXI4_RESP_TYPE;
    signal   C_BUSER         : std_logic_vector(C_WIDTH.BUSER  -1 downto 0);
    signal   C_BID           : std_logic_vector(C_WIDTH.ID     -1 downto 0);
    signal   C_BVALID        : std_logic;
    signal   C_BREADY        : std_logic;
    -------------------------------------------------------------------------------
    -- シンクロ用信号
    -------------------------------------------------------------------------------
    signal   SYNC            : SYNC_SIG_VECTOR (SYNC_WIDTH     -1 downto 0);
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    signal   I_CLK           : std_logic;
    signal   I_DATA          : std_logic_vector(I_WIDTH.DATA   -1 downto 0);
    signal   I_STRB          : std_logic_vector(I_WIDTH.DATA/8 -1 downto 0);
    signal   I_LAST          : std_logic;
    signal   I_VALID         : std_logic;
    signal   I_READY         : std_logic;
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    signal   O_CLK           : std_logic;
    signal   O_DATA          : std_logic_vector(O_WIDTH.DATA   -1 downto 0);
    signal   O_STRB          : std_logic_vector(O_WIDTH.DATA/8 -1 downto 0);
    constant O_KEEP          : std_logic_vector(O_WIDTH.DATA/8 -1 downto 0) := (others => '1');
    constant O_USER          : std_logic_vector(O_WIDTH.USER   -1 downto 0) := (others => '0');
    constant O_DEST          : std_logic_vector(O_WIDTH.DEST   -1 downto 0) := (others => '0');
    constant O_ID            : std_logic_vector(O_WIDTH.ID     -1 downto 0) := (others => '0');
    signal   O_LAST          : std_logic;
    signal   O_VALID         : std_logic;
    signal   O_READY         : std_logic;
    -------------------------------------------------------------------------------
    -- GPIO(General Purpose Input/Output)
    -------------------------------------------------------------------------------
    signal   C_GPI           : std_logic_vector(GPI_WIDTH      -1 downto 0);
    signal   C_GPO           : std_logic_vector(GPO_WIDTH      -1 downto 0);
    signal   I_GPI           : std_logic_vector(GPI_WIDTH      -1 downto 0);
    signal   I_GPO           : std_logic_vector(GPO_WIDTH      -1 downto 0);
    signal   O_GPI           : std_logic_vector(GPI_WIDTH      -1 downto 0);
    signal   O_GPO           : std_logic_vector(GPO_WIDTH      -1 downto 0);
    -------------------------------------------------------------------------------
    -- 各種状態出力.
    -------------------------------------------------------------------------------
    signal   N_REPORT        : REPORT_STATUS_TYPE;
    signal   C_REPORT        : REPORT_STATUS_TYPE;
    signal   I_REPORT        : REPORT_STATUS_TYPE;
    signal   O_REPORT        : REPORT_STATUS_TYPE;
    signal   N_FINISH        : std_logic;
    signal   C_FINISH        : std_logic;
    signal   I_FINISH        : std_logic;
    signal   O_FINISH        : std_logic;
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    component PTTY_AXI4
        generic (
            SBUF_DEPTH      : integer range  4 to    9 :=  7;
            RBUF_DEPTH      : integer range  4 to    9 :=  7;
            C_ADDR_WIDTH    : integer range 12 to   64 := 12;
            C_DATA_WIDTH    : integer range  8 to 1024 := 32;
            C_ID_WIDTH      : integer                  :=  8;
            I_BYTES         : integer range  1 to    1 :=  1;
            O_BYTES         : integer range  1 to    1 :=  1
        );
        port (
            ARESETn         : in    std_logic;
            C_CLK           : in    std_logic;
            C_ARID          : in    std_logic_vector(C_ID_WIDTH    -1 downto 0);
            C_ARADDR        : in    std_logic_vector(C_ADDR_WIDTH  -1 downto 0);
            C_ARLEN         : in    std_logic_vector(7 downto 0);
            C_ARSIZE        : in    std_logic_vector(2 downto 0);
            C_ARBURST       : in    std_logic_vector(1 downto 0);
            C_ARVALID       : in    std_logic;
            C_ARREADY       : out   std_logic;
            C_RID           : out   std_logic_vector(C_ID_WIDTH    -1 downto 0);
            C_RDATA         : out   std_logic_vector(C_DATA_WIDTH  -1 downto 0);
            C_RRESP         : out   std_logic_vector(1 downto 0);
            C_RLAST         : out   std_logic;
            C_RVALID        : out   std_logic;
            C_RREADY        : in    std_logic;
            C_AWID          : in    std_logic_vector(C_ID_WIDTH    -1 downto 0);
            C_AWADDR        : in    std_logic_vector(C_ADDR_WIDTH  -1 downto 0);
            C_AWLEN         : in    std_logic_vector(7 downto 0);
            C_AWSIZE        : in    std_logic_vector(2 downto 0);
            C_AWBURST       : in    std_logic_vector(1 downto 0);
            C_AWVALID       : in    std_logic;
            C_AWREADY       : out   std_logic;
            C_WDATA         : in    std_logic_vector(C_DATA_WIDTH  -1 downto 0);
            C_WSTRB         : in    std_logic_vector(C_DATA_WIDTH/8-1 downto 0);
            C_WLAST         : in    std_logic;
            C_WVALID        : in    std_logic;
            C_WREADY        : out   std_logic;
            C_BID           : out   std_logic_vector(C_ID_WIDTH    -1 downto 0);
            C_BRESP         : out   std_logic_vector(1 downto 0);
            C_BVALID        : out   std_logic;
            C_BREADY        : in    std_logic;
            C_IRQ           : out   std_logic;
            I_CLK           : in    std_logic;
            I_DATA          : in    std_logic_vector(8*I_BYTES-1 downto 0);
            I_STRB          : in    std_logic_vector(  I_BYTES-1 downto 0);
            I_LAST          : in    std_logic;
            I_VALID         : in    std_logic;
            I_READY         : out   std_logic;
            O_CLK           : in    std_logic;
            O_DATA          : out   std_logic_vector(8*O_BYTES-1 downto 0);
            O_STRB          : out   std_logic_vector(  O_BYTES-1 downto 0);
            O_LAST          : out   std_logic;
            O_VALID         : out   std_logic;
            O_READY         : in    std_logic
        );
    end component;
begin
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    N: MARCHAL
        generic map(
            SCENARIO_FILE   => SCENARIO_FILE,
            NAME            => "MARCHAL",
            SYNC_PLUG_NUM   => 1,
            SYNC_WIDTH      => SYNC_WIDTH,
            FINISH_ABORT    => FALSE
        )
        port map(
            CLK             => C_CLK           , -- In  :
            RESET           => RESET           , -- In  :
            SYNC(0)         => SYNC(0)         , -- I/O :
            SYNC(1)         => SYNC(1)         , -- I/O :
            REPORT_STATUS   => N_REPORT        , -- Out :
            FINISH          => N_FINISH          -- Out :
        );
    ------------------------------------------------------------------------------
    -- AXI4_MASTER_PLAYER
    ------------------------------------------------------------------------------
    M: AXI4_MASTER_PLAYER
        generic map (
            SCENARIO_FILE   => SCENARIO_FILE   ,
            NAME            => "CSR"           ,
            READ_ENABLE     => TRUE            ,
            WRITE_ENABLE    => TRUE            ,
            OUTPUT_DELAY    => DELAY           ,
            WIDTH           => C_WIDTH         ,
            SYNC_PLUG_NUM   => 2               ,
            SYNC_WIDTH      => SYNC_WIDTH      ,
            GPI_WIDTH       => GPI_WIDTH       ,
            GPO_WIDTH       => GPO_WIDTH       ,
            FINISH_ABORT    => FALSE
        )
        port map(
        ---------------------------------------------------------------------------
        -- グローバルシグナル.
        ---------------------------------------------------------------------------
            ACLK            => C_CLK           , -- In  :
            ARESETn         => ARESETn         , -- In  :
        ---------------------------------------------------------------------------
        -- リードアドレスチャネルシグナル.
        ---------------------------------------------------------------------------
            ARADDR          => C_ARADDR        , -- I/O : 
            ARLEN           => C_ARLEN         , -- I/O : 
            ARSIZE          => C_ARSIZE        , -- I/O : 
            ARBURST         => C_ARBURST       , -- I/O : 
            ARLOCK          => C_ARLOCK        , -- I/O : 
            ARCACHE         => C_ARCACHE       , -- I/O : 
            ARPROT          => C_ARPROT        , -- I/O : 
            ARQOS           => C_ARQOS         , -- I/O : 
            ARREGION        => C_ARREGION      , -- I/O : 
            ARUSER          => C_ARUSER        , -- I/O : 
            ARID            => C_ARID          , -- I/O : 
            ARVALID         => C_ARVALID       , -- I/O : 
            ARREADY         => C_ARREADY       , -- In  :    
        ---------------------------------------------------------------------------
        -- リードデータチャネルシグナル.
        ---------------------------------------------------------------------------
            RLAST           => C_RLAST         , -- In  :    
            RDATA           => C_RDATA         , -- In  :    
            RRESP           => C_RRESP         , -- In  :    
            RUSER           => C_RUSER         , -- In  :    
            RID             => C_RID           , -- In  :    
            RVALID          => C_RVALID        , -- In  :    
            RREADY          => C_RREADY        , -- I/O : 
        --------------------------------------------------------------------------
        -- ライトアドレスチャネルシグナル.
        --------------------------------------------------------------------------
            AWADDR          => C_AWADDR        , -- I/O : 
            AWLEN           => C_AWLEN         , -- I/O : 
            AWSIZE          => C_AWSIZE        , -- I/O : 
            AWBURST         => C_AWBURST       , -- I/O : 
            AWLOCK          => C_AWLOCK        , -- I/O : 
            AWCACHE         => C_AWCACHE       , -- I/O : 
            AWPROT          => C_AWPROT        , -- I/O : 
            AWQOS           => C_AWQOS         , -- I/O : 
            AWREGION        => C_AWREGION      , -- I/O : 
            AWUSER          => C_AWUSER        , -- I/O : 
            AWID            => C_AWID          , -- I/O : 
            AWVALID         => C_AWVALID       , -- I/O : 
            AWREADY         => C_AWREADY       , -- In  :    
        --------------------------------------------------------------------------
        -- ライトデータチャネルシグナル.
        --------------------------------------------------------------------------
            WLAST           => C_WLAST         , -- I/O : 
            WDATA           => C_WDATA         , -- I/O : 
            WSTRB           => C_WSTRB         , -- I/O : 
            WUSER           => C_WUSER         , -- I/O : 
            WID             => C_WID           , -- I/O : 
            WVALID          => C_WVALID        , -- I/O : 
            WREADY          => C_WREADY        , -- In  :    
        --------------------------------------------------------------------------
        -- ライト応答チャネルシグナル.
        --------------------------------------------------------------------------
            BRESP           => C_BRESP         , -- In  :    
            BUSER           => C_BUSER         , -- In  :    
            BID             => C_BID           , -- In  :    
            BVALID          => C_BVALID        , -- In  :    
            BREADY          => C_BREADY        , -- I/O : 
        --------------------------------------------------------------------------
        -- シンクロ用信号
        --------------------------------------------------------------------------
            SYNC(0)         => SYNC(0)         , -- I/O :
            SYNC(1)         => SYNC(1)         , -- I/O :
        --------------------------------------------------------------------------
        -- GPIO
        --------------------------------------------------------------------------
            GPI             => C_GPI           , -- In  :
            GPO             => C_GPO           , -- Out :
        --------------------------------------------------------------------------
        -- 各種状態出力.
        --------------------------------------------------------------------------
            REPORT_STATUS   => C_REPORT        , -- Out :
            FINISH          => C_FINISH          -- Out :
        );
    -------------------------------------------------------------------------------
    -- AXI4_SIGNAL_PRINTER
    -------------------------------------------------------------------------------
    PRINT: AXI4_SIGNAL_PRINTER                   -- 
        generic map (                            -- 
            NAME            => NAME            , -- 
            TAG             => NAME            , --
            TAG_WIDTH       => 0               , -- 
            TIME_WIDTH      => 13              , --
            WIDTH           => C_WIDTH         , -- 
            READ_ENABLE     => TRUE            , -- 
            WRITE_ENABLE    => TRUE              --
        )                                        -- 
        port map (                               -- 
        ---------------------------------------------------------------------------
        -- グローバルシグナル.
        ---------------------------------------------------------------------------
            ACLK            => C_CLK           , -- In  :
            ARESETn         => ARESETn         , -- In  :
        ---------------------------------------------------------------------------
        -- リードアドレスチャネルシグナル.
        ---------------------------------------------------------------------------
            ARADDR          => C_ARADDR        , -- In  :
            ARLEN           => C_ARLEN         , -- In  :
            ARSIZE          => C_ARSIZE        , -- In  :
            ARBURST         => C_ARBURST       , -- In  :
            ARLOCK          => C_ARLOCK        , -- In  :
            ARCACHE         => C_ARCACHE       , -- In  :
            ARPROT          => C_ARPROT        , -- In  :
            ARQOS           => C_ARQOS         , -- In  :
            ARREGION        => C_ARREGION      , -- In  :
            ARUSER          => C_ARUSER        , -- In  :
            ARID            => C_ARID          , -- In  :
            ARVALID         => C_ARVALID       , -- In  :
            ARREADY         => C_ARREADY       , -- In  :
        ---------------------------------------------------------------------------
        -- リードチャネルシグナル.
        ---------------------------------------------------------------------------
            RLAST           => C_RLAST         , -- In  :
            RDATA           => C_RDATA         , -- In  :
            RRESP           => C_RRESP         , -- In  :
            RUSER           => C_RUSER         , -- In  :
            RID             => C_RID           , -- In  :
            RVALID          => C_RVALID        , -- In  :
            RREADY          => C_RREADY        , -- In  :
        ---------------------------------------------------------------------------
        -- ライトアドレスチャネルシグナル.
        ---------------------------------------------------------------------------
            AWADDR          => C_AWADDR        , -- In  :
            AWLEN           => C_AWLEN         , -- In  :
            AWSIZE          => C_AWSIZE        , -- In  :
            AWBURST         => C_AWBURST       , -- In  :
            AWLOCK          => C_AWLOCK        , -- In  :
            AWCACHE         => C_AWCACHE       , -- In  :
            AWPROT          => C_AWPROT        , -- In  :
            AWQOS           => C_AWQOS         , -- In  :
            AWREGION        => C_AWREGION      , -- In  :
            AWUSER          => C_AWUSER        , -- In  :
            AWID            => C_AWID          , -- In  :
            AWVALID         => C_AWVALID       , -- In  :
            AWREADY         => C_AWREADY       , -- In  :
        ---------------------------------------------------------------------------
        -- ライトデータチャネルシグナル.
        ---------------------------------------------------------------------------
            WLAST           => C_WLAST         , -- In  :
            WDATA           => C_WDATA         , -- In  :
            WSTRB           => C_WSTRB         , -- In  :
            WUSER           => C_WUSER         , -- In  :
            WID             => C_WID           , -- In  :
            WVALID          => C_WVALID        , -- In  :
            WREADY          => C_WREADY        , -- In  :
        ---------------------------------------------------------------------------
        -- ライト応答チャネルシグナル.
        ---------------------------------------------------------------------------
            BRESP           => C_BRESP         , -- In  :
            BUSER           => C_BUSER         , -- In  :
            BID             => C_BID           , -- In  :
            BVALID          => C_BVALID        , -- In  :
            BREADY          => C_BREADY          -- In  :
    );
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    I: AXI4_STREAM_MASTER_PLAYER                 -- 
        generic map (                            -- 
            SCENARIO_FILE   => SCENARIO_FILE   , --
            NAME            => "I"             , --
            OUTPUT_DELAY    => DELAY           , --
            SYNC_PLUG_NUM   => 3               , --
            WIDTH           => I_WIDTH         , --
            SYNC_WIDTH      => SYNC_WIDTH      , --
            GPI_WIDTH       => GPI_WIDTH       , --
            GPO_WIDTH       => GPO_WIDTH       , --
            FINISH_ABORT    => FALSE             --
        )                                        -- 
        port map (                               -- 
            ACLK            => I_CLK           , -- In  :
            ARESETn         => ARESETn         , -- In  :
            TDATA           => I_DATA          , -- Out :
            TSTRB           => I_STRB          , -- Out :
            TKEEP           => open            , -- Out :
            TUSER           => open            , -- Out :
            TDEST           => open            , -- Out :
            TID             => open            , -- Out :
            TLAST           => I_LAST          , -- Out :
            TVALID          => I_VALID         , -- Out :
            TREADY          => I_READY         , -- In  :
            SYNC            => SYNC            , -- I/O :
            GPI             => I_GPI           , -- In  :
            GPO             => I_GPO           , -- Out :
            REPORT_STATUS   => I_REPORT        , -- Out :
            FINISH          => I_FINISH          -- Out :
        );                                       -- 
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    O: AXI4_STREAM_SLAVE_PLAYER                  -- 
        generic map (                            -- 
            SCENARIO_FILE   => SCENARIO_FILE   , --
            NAME            => "O"             , --
            OUTPUT_DELAY    => DELAY           , --
            SYNC_PLUG_NUM   => 5               , --
            WIDTH           => O_WIDTH         , --
            SYNC_WIDTH      => SYNC_WIDTH      , --
            GPI_WIDTH       => GPI_WIDTH       , --
            GPO_WIDTH       => GPO_WIDTH       , --
            FINISH_ABORT    => FALSE             --
        )                                        -- 
        port map(                                -- 
            ACLK            => O_CLK           , -- In  :
            ARESETn         => ARESETn         , -- In  :
            TDATA           => O_DATA          , -- In  :
            TSTRB           => O_STRB          , -- In  :
            TKEEP           => O_KEEP          , -- In  :
            TUSER           => O_USER          , -- In  :
            TDEST           => O_DEST          , -- In  :
            TID             => O_ID            , -- In  :
            TLAST           => O_LAST          , -- In  :
            TVALID          => O_VALID         , -- In  :
            TREADY          => O_READY         , -- Out :
            SYNC            => SYNC            , -- Inou:
            GPI             => O_GPI           , -- In  :
            GPO             => O_GPO           , -- Out :
            REPORT_STATUS   => O_REPORT        , -- Out :
            FINISH          => O_FINISH          -- Out :
        );                                       -- 
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    DUT: PTTY_AXI4                               -- 
        generic map (                            -- 
            SBUF_DEPTH      => SBUF_DEPTH      , --
            RBUF_DEPTH      => RBUF_DEPTH      , --
            C_ADDR_WIDTH    => AXI4_ADDR_WIDTH , --
            C_DATA_WIDTH    => AXI4_DATA_WIDTH , --
            C_ID_WIDTH      => C_WIDTH.ID      , --
            I_BYTES         => I_BYTES         , --
            O_BYTES         => O_BYTES           --
        )                                        -- 
        port map (                               -- 
            ARESETn         => ARESETn         , -- In  :
            C_CLK           => C_CLK           , -- In  :
            C_ARID          => C_ARID          , -- In  :
            C_ARADDR        => C_ARADDR        , -- In  :
            C_ARLEN         => C_ARLEN         , -- In  :
            C_ARSIZE        => C_ARSIZE        , -- In  :
            C_ARBURST       => C_ARBURST       , -- In  :
            C_ARVALID       => C_ARVALID       , -- In  :
            C_ARREADY       => C_ARREADY       , -- Out :
            C_RID           => C_RID           , -- Out :
            C_RDATA         => C_RDATA         , -- Out :
            C_RRESP         => C_RRESP         , -- Out :
            C_RLAST         => C_RLAST         , -- Out :
            C_RVALID        => C_RVALID        , -- Out :
            C_RREADY        => C_RREADY        , -- In  :
            C_AWID          => C_AWID          , -- In  :
            C_AWADDR        => C_AWADDR        , -- In  :
            C_AWLEN         => C_AWLEN         , -- In  :
            C_AWSIZE        => C_AWSIZE        , -- In  :
            C_AWBURST       => C_AWBURST       , -- In  :
            C_AWVALID       => C_AWVALID       , -- In  :
            C_AWREADY       => C_AWREADY       , -- Out :
            C_WDATA         => C_WDATA         , -- In  :
            C_WSTRB         => C_WSTRB         , -- In  :
            C_WLAST         => C_WLAST         , -- In  :
            C_WVALID        => C_WVALID        , -- In  :
            C_WREADY        => C_WREADY        , -- Out :
            C_BID           => C_BID           , -- Out :
            C_BRESP         => C_BRESP         , -- Out :
            C_BVALID        => C_BVALID        , -- Out :
            C_BREADY        => C_BREADY        , -- In  :
            C_IRQ           => C_IRQ           , -- Out :
            I_CLK           => I_CLK           , -- In  :
            I_DATA          => I_DATA          , -- In  :
            I_STRB          => I_STRB          , -- In  :
            I_LAST          => I_LAST          , -- In  :
            I_VALID         => I_VALID         , -- In  :
            I_READY         => I_READY         , -- Out :
            O_CLK           => O_CLK           , -- In  :
            O_DATA          => O_DATA          , -- Out :
            O_STRB          => O_STRB          , -- Out :
            O_LAST          => O_LAST          , -- Out :
            O_VALID         => O_VALID         , -- Out :
            O_READY         => O_READY           -- In  :
        );
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    process begin
        C_CLK <= '0';
        wait for C_CLK_PERIOD / 2;
        C_CLK <= '1';
        wait for C_CLK_PERIOD / 2;
    end process;
    process begin
        I_CLK <= '0';
        wait for I_CLK_PERIOD / 2;
        I_CLK <= '1';
        wait for I_CLK_PERIOD / 2;
    end process;
    process begin
        O_CLK <= '0';
        wait for O_CLK_PERIOD / 2;
        O_CLK <= '1';
        wait for O_CLK_PERIOD / 2;
    end process;

    ARESETn <= '1' when (RESET = '0') else '0';
    C_GPI(0)<= C_IRQ;
    C_GPI(C_GPI'high downto 1) <= C_GPO(C_GPI'high downto 1);
    I_GPI   <= C_GPO;
    I_GPI   <= C_GPO;
    process
        variable L   : LINE;
        constant T   : STRING(1 to 7) := "  ***  ";
    begin
        wait until (C_FINISH'event and C_FINISH = '1');
        wait for DELAY;
        WRITE(L,T);                                                   WRITELINE(OUTPUT,L);
        WRITE(L,T & "ERROR REPORT " & NAME);                          WRITELINE(OUTPUT,L);
        WRITE(L,T & "[ CSR ]");                                       WRITELINE(OUTPUT,L);
        WRITE(L,T & "  Error    : ");WRITE(L,C_REPORT.error_count   );WRITELINE(OUTPUT,L);
        WRITE(L,T & "  Mismatch : ");WRITE(L,C_REPORT.mismatch_count);WRITELINE(OUTPUT,L);
        WRITE(L,T & "  Warning  : ");WRITE(L,C_REPORT.warning_count );WRITELINE(OUTPUT,L);
        WRITE(L,T & "[ O ]");                                         WRITELINE(OUTPUT,L);
        WRITE(L,T & "  Error    : ");WRITE(L,O_REPORT.error_count   );WRITELINE(OUTPUT,L);
        WRITE(L,T & "  Mismatch : ");WRITE(L,O_REPORT.mismatch_count);WRITELINE(OUTPUT,L);
        WRITE(L,T & "  Warning  : ");WRITE(L,O_REPORT.warning_count );WRITELINE(OUTPUT,L);
        WRITE(L,T & "[ I ]");                                         WRITELINE(OUTPUT,L);
        WRITE(L,T & "  Error    : ");WRITE(L,I_REPORT.error_count   );WRITELINE(OUTPUT,L);
        WRITE(L,T & "  Mismatch : ");WRITE(L,I_REPORT.mismatch_count);WRITELINE(OUTPUT,L);
        WRITE(L,T & "  Warning  : ");WRITE(L,I_REPORT.warning_count );WRITELINE(OUTPUT,L);
        WRITE(L,T);                                                   WRITELINE(OUTPUT,L);
        assert FALSE report "Simulation complete." severity FAILURE;
        wait;
    end process;
    
 -- SYNC_PRINT_0: SYNC_PRINT generic map(string'("AXI4_TEST_1:SYNC(0)")) port map (SYNC(0));
 -- SYNC_PRINT_1: SYNC_PRINT generic map(string'("AXI4_TEST_1:SYNC(1)")) port map (SYNC(1));
end MODEL;
-----------------------------------------------------------------------------------
--
-----------------------------------------------------------------------------------
