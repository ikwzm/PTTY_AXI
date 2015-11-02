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
        NAME            : STRING   := "TEST";
        SCENARIO_FILE   : STRING   := "test_1.snr";
        RXD_BYTES       : positive := 1;
        TXD_BYTES       : positive := 1
    );
end     TEST_BENCH;
-----------------------------------------------------------------------------------
--
-----------------------------------------------------------------------------------
architecture MODEL of TEST_BENCH is
    -------------------------------------------------------------------------------
    -- 各種定数
    -------------------------------------------------------------------------------
    constant CSR_CLK_PERIOD  : time    := 10 ns;
    constant RXD_CLK_PERIOD  : time    := 10 ns;
    constant TXD_CLK_PERIOD  : time    := 10 ns;
    constant DELAY           : time    :=  1 ns;
    constant AXI4_ADDR_WIDTH : integer := 32;
    constant AXI4_DATA_WIDTH : integer := 32;
    constant CSR_WIDTH       : AXI4_SIGNAL_WIDTH_TYPE := (
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
    constant RXD_WIDTH       : AXI4_STREAM_SIGNAL_WIDTH_TYPE := (
                                 ID          => 4,
                                 USER        => 4,
                                 DEST        => 4,
                                 DATA        => 8*RXD_BYTES);
    constant TXD_WIDTH       : AXI4_STREAM_SIGNAL_WIDTH_TYPE := (
                                 ID          => 4,
                                 USER        => 4,
                                 DEST        => 4,
                                 DATA        => 8*TXD_BYTES);
    constant SYNC_WIDTH      : integer :=  2;
    constant GPO_WIDTH       : integer :=  8;
    constant GPI_WIDTH       : integer :=  GPO_WIDTH;
    constant TXD_BUF_DEPTH   : integer :=  8;
    constant RXD_BUF_DEPTH   : integer :=  8;
    -------------------------------------------------------------------------------
    -- グローバルシグナル.
    -------------------------------------------------------------------------------
    signal   CSR_CLK         : std_logic;
    signal   ARESETn         : std_logic;
    signal   RESET           : std_logic;
    signal   CSR_IRQ         : std_logic;
    ------------------------------------------------------------------------------
    -- リードアドレスチャネルシグナル.
    ------------------------------------------------------------------------------
    signal   CSR_ARADDR      : std_logic_vector(CSR_WIDTH.ARADDR -1 downto 0);
    signal   CSR_ARWRITE     : std_logic;
    signal   CSR_ARLEN       : std_logic_vector(CSR_WIDTH.ALEN   -1 downto 0);
    signal   CSR_ARSIZE      : AXI4_ASIZE_TYPE;
    signal   CSR_ARBURST     : AXI4_ABURST_TYPE;
    signal   CSR_ARLOCK      : std_logic_vector(CSR_WIDTH.ALOCK  -1 downto 0);
    signal   CSR_ARCACHE     : AXI4_ACACHE_TYPE;
    signal   CSR_ARPROT      : AXI4_APROT_TYPE;
    signal   CSR_ARQOS       : AXI4_AQOS_TYPE;
    signal   CSR_ARREGION    : AXI4_AREGION_TYPE;
    signal   CSR_ARUSER      : std_logic_vector(CSR_WIDTH.ARUSER -1 downto 0);
    signal   CSR_ARID        : std_logic_vector(CSR_WIDTH.ID     -1 downto 0);
    signal   CSR_ARVALID     : std_logic;
    signal   CSR_ARREADY     : std_logic;
    -------------------------------------------------------------------------------
    -- リードデータチャネルシグナル.
    -------------------------------------------------------------------------------
    signal   CSR_RVALID      : std_logic;
    signal   CSR_RLAST       : std_logic;
    signal   CSR_RDATA       : std_logic_vector(CSR_WIDTH.RDATA  -1 downto 0);
    signal   CSR_RRESP       : AXI4_RESP_TYPE;
    signal   CSR_RUSER       : std_logic_vector(CSR_WIDTH.RUSER  -1 downto 0);
    signal   CSR_RID         : std_logic_vector(CSR_WIDTH.ID     -1 downto 0);
    signal   CSR_RREADY      : std_logic;
    -------------------------------------------------------------------------------
    -- ライトアドレスチャネルシグナル.
    -------------------------------------------------------------------------------
    signal   CSR_AWADDR      : std_logic_vector(CSR_WIDTH.AWADDR -1 downto 0);
    signal   CSR_AWLEN       : std_logic_vector(CSR_WIDTH.ALEN   -1 downto 0);
    signal   CSR_AWSIZE      : AXI4_ASIZE_TYPE;
    signal   CSR_AWBURST     : AXI4_ABURST_TYPE;
    signal   CSR_AWLOCK      : std_logic_vector(CSR_WIDTH.ALOCK  -1 downto 0);
    signal   CSR_AWCACHE     : AXI4_ACACHE_TYPE;
    signal   CSR_AWPROT      : AXI4_APROT_TYPE;
    signal   CSR_AWQOS       : AXI4_AQOS_TYPE;
    signal   CSR_AWREGION    : AXI4_AREGION_TYPE;
    signal   CSR_AWUSER      : std_logic_vector(CSR_WIDTH.AWUSER -1 downto 0);
    signal   CSR_AWID        : std_logic_vector(CSR_WIDTH.ID     -1 downto 0);
    signal   CSR_AWVALID     : std_logic;
    signal   CSR_AWREADY     : std_logic;
    -------------------------------------------------------------------------------
    -- ライトデータチャネルシグナル.
    -------------------------------------------------------------------------------
    signal   CSR_WLAST       : std_logic;
    signal   CSR_WDATA       : std_logic_vector(CSR_WIDTH.WDATA  -1 downto 0);
    signal   CSR_WSTRB       : std_logic_vector(CSR_WIDTH.WDATA/8-1 downto 0);
    signal   CSR_WUSER       : std_logic_vector(CSR_WIDTH.WUSER  -1 downto 0);
    signal   CSR_WID         : std_logic_vector(CSR_WIDTH.ID     -1 downto 0);
    signal   CSR_WVALID      : std_logic;
    signal   CSR_WREADY      : std_logic;
    -------------------------------------------------------------------------------
    -- ライト応答チャネルシグナル.
    -------------------------------------------------------------------------------
    signal   CSR_BRESP       : AXI4_RESP_TYPE;
    signal   CSR_BUSER       : std_logic_vector(CSR_WIDTH.BUSER  -1 downto 0);
    signal   CSR_BID         : std_logic_vector(CSR_WIDTH.ID     -1 downto 0);
    signal   CSR_BVALID      : std_logic;
    signal   CSR_BREADY      : std_logic;
    -------------------------------------------------------------------------------
    -- シンクロ用信号
    -------------------------------------------------------------------------------
    signal   SYNC            : SYNC_SIG_VECTOR (SYNC_WIDTH     -1 downto 0);
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    signal   RXD_CLK         : std_logic;
    signal   RXD_TDATA       : std_logic_vector(RXD_WIDTH.DATA   -1 downto 0);
    signal   RXD_TSTRB       : std_logic_vector(RXD_WIDTH.DATA/8 -1 downto 0);
    signal   RXD_TKEEP       : std_logic_vector(RXD_WIDTH.DATA/8 -1 downto 0);
    signal   RXD_TLAST       : std_logic;
    signal   RXD_TVALID      : std_logic;
    signal   RXD_TREADY      : std_logic;
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    signal   TXD_CLK         : std_logic;
    signal   TXD_TDATA       : std_logic_vector(TXD_WIDTH.DATA   -1 downto 0);
    signal   TXD_TSTRB       : std_logic_vector(TXD_WIDTH.DATA/8 -1 downto 0);
    signal   TXD_TKEEP       : std_logic_vector(TXD_WIDTH.DATA/8 -1 downto 0);
    constant TXD_TUSER       : std_logic_vector(TXD_WIDTH.USER   -1 downto 0) := (others => '0');
    constant TXD_TDEST       : std_logic_vector(TXD_WIDTH.DEST   -1 downto 0) := (others => '0');
    constant TXD_TID         : std_logic_vector(TXD_WIDTH.ID     -1 downto 0) := (others => '0');
    signal   TXD_TLAST       : std_logic;
    signal   TXD_TVALID      : std_logic;
    signal   TXD_TREADY      : std_logic;
    -------------------------------------------------------------------------------
    -- GPIO(General Purpose Input/Output)
    -------------------------------------------------------------------------------
    signal   CSR_GPI         : std_logic_vector(GPI_WIDTH      -1 downto 0);
    signal   CSR_GPO         : std_logic_vector(GPO_WIDTH      -1 downto 0);
    signal   RXD_GPI         : std_logic_vector(GPI_WIDTH      -1 downto 0);
    signal   RXD_GPO         : std_logic_vector(GPO_WIDTH      -1 downto 0);
    signal   TXD_GPI         : std_logic_vector(GPI_WIDTH      -1 downto 0);
    signal   TXD_GPO         : std_logic_vector(GPO_WIDTH      -1 downto 0);
    -------------------------------------------------------------------------------
    -- 各種状態出力.
    -------------------------------------------------------------------------------
    signal   N_REPORT        : REPORT_STATUS_TYPE;
    signal   CSR_REPORT      : REPORT_STATUS_TYPE;
    signal   RXD_REPORT      : REPORT_STATUS_TYPE;
    signal   TXD_REPORT      : REPORT_STATUS_TYPE;
    signal   N_FINISH        : std_logic;
    signal   CSR_FINISH      : std_logic;
    signal   RXD_FINISH      : std_logic;
    signal   TXD_FINISH      : std_logic;
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    component PTTY_AXI4
        generic (
            TXD_BUF_DEPTH    : integer range  4 to    9 :=  7;
            RXD_BUF_DEPTH    : integer range  4 to    9 :=  7;
            CSR_ADDR_WIDTH   : integer range 12 to   64 := 12;
            CSR_DATA_WIDTH   : integer range  8 to 1024 := 32;
            CSR_ID_WIDTH     : integer                  :=  8;
            RXD_BYTES        : positive                 :=  1;
            TXD_BYTES        : positive                 :=  1
        );
        port (
            ARESETn          : in    std_logic;
            CSR_CLK          : in    std_logic;
            CSR_ARID         : in    std_logic_vector(CSR_ID_WIDTH    -1 downto 0);
            CSR_ARADDR       : in    std_logic_vector(CSR_ADDR_WIDTH  -1 downto 0);
            CSR_ARLEN        : in    std_logic_vector(7 downto 0);
            CSR_ARSIZE       : in    std_logic_vector(2 downto 0);
            CSR_ARBURST      : in    std_logic_vector(1 downto 0);
            CSR_ARVALID      : in    std_logic;
            CSR_ARREADY      : out   std_logic;
            CSR_RID          : out   std_logic_vector(CSR_ID_WIDTH    -1 downto 0);
            CSR_RDATA        : out   std_logic_vector(CSR_DATA_WIDTH  -1 downto 0);
            CSR_RRESP        : out   std_logic_vector(1 downto 0);
            CSR_RLAST        : out   std_logic;
            CSR_RVALID       : out   std_logic;
            CSR_RREADY       : in    std_logic;
            CSR_AWID         : in    std_logic_vector(CSR_ID_WIDTH    -1 downto 0);
            CSR_AWADDR       : in    std_logic_vector(CSR_ADDR_WIDTH  -1 downto 0);
            CSR_AWLEN        : in    std_logic_vector(7 downto 0);
            CSR_AWSIZE       : in    std_logic_vector(2 downto 0);
            CSR_AWBURST      : in    std_logic_vector(1 downto 0);
            CSR_AWVALID      : in    std_logic;
            CSR_AWREADY      : out   std_logic;
            CSR_WDATA        : in    std_logic_vector(CSR_DATA_WIDTH  -1 downto 0);
            CSR_WSTRB        : in    std_logic_vector(CSR_DATA_WIDTH/8-1 downto 0);
            CSR_WLAST        : in    std_logic;
            CSR_WVALID       : in    std_logic;
            CSR_WREADY       : out   std_logic;
            CSR_BID          : out   std_logic_vector(CSR_ID_WIDTH    -1 downto 0);
            CSR_BRESP        : out   std_logic_vector(1 downto 0);
            CSR_BVALID       : out   std_logic;
            CSR_BREADY       : in    std_logic;
            CSR_IRQ          : out   std_logic;
            RXD_CLK          : in    std_logic;
            RXD_TDATA        : in    std_logic_vector(8*RXD_BYTES-1 downto 0);
            RXD_TKEEP        : in    std_logic_vector(  RXD_BYTES-1 downto 0);
            RXD_TLAST        : in    std_logic;
            RXD_TVALID       : in    std_logic;
            RXD_TREADY       : out   std_logic;
            TXD_CLK          : in    std_logic;
            TXD_TDATA        : out   std_logic_vector(8*TXD_BYTES-1 downto 0);
            TXD_TKEEP        : out   std_logic_vector(  TXD_BYTES-1 downto 0);
            TXD_TLAST        : out   std_logic;
            TXD_TVALID       : out   std_logic;
            TXD_TREADY       : in    std_logic
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
            CLK             => CSR_CLK         , -- In  :
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
            WIDTH           => CSR_WIDTH       ,
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
            ACLK            => CSR_CLK         , -- In  :
            ARESETn         => ARESETn         , -- In  :
        ---------------------------------------------------------------------------
        -- リードアドレスチャネルシグナル.
        ---------------------------------------------------------------------------
            ARADDR          => CSR_ARADDR      , -- I/O : 
            ARLEN           => CSR_ARLEN       , -- I/O : 
            ARSIZE          => CSR_ARSIZE      , -- I/O : 
            ARBURST         => CSR_ARBURST     , -- I/O : 
            ARLOCK          => CSR_ARLOCK      , -- I/O : 
            ARCACHE         => CSR_ARCACHE     , -- I/O : 
            ARPROT          => CSR_ARPROT      , -- I/O : 
            ARQOS           => CSR_ARQOS       , -- I/O : 
            ARREGION        => CSR_ARREGION    , -- I/O : 
            ARUSER          => CSR_ARUSER      , -- I/O : 
            ARID            => CSR_ARID        , -- I/O : 
            ARVALID         => CSR_ARVALID     , -- I/O : 
            ARREADY         => CSR_ARREADY     , -- In  :    
        ---------------------------------------------------------------------------
        -- リードデータチャネルシグナル.
        ---------------------------------------------------------------------------
            RLAST           => CSR_RLAST       , -- In  :    
            RDATA           => CSR_RDATA       , -- In  :    
            RRESP           => CSR_RRESP       , -- In  :    
            RUSER           => CSR_RUSER       , -- In  :    
            RID             => CSR_RID         , -- In  :    
            RVALID          => CSR_RVALID      , -- In  :    
            RREADY          => CSR_RREADY      , -- I/O : 
        --------------------------------------------------------------------------
        -- ライトアドレスチャネルシグナル.
        --------------------------------------------------------------------------
            AWADDR          => CSR_AWADDR      , -- I/O : 
            AWLEN           => CSR_AWLEN       , -- I/O : 
            AWSIZE          => CSR_AWSIZE      , -- I/O : 
            AWBURST         => CSR_AWBURST     , -- I/O : 
            AWLOCK          => CSR_AWLOCK      , -- I/O : 
            AWCACHE         => CSR_AWCACHE     , -- I/O : 
            AWPROT          => CSR_AWPROT      , -- I/O : 
            AWQOS           => CSR_AWQOS       , -- I/O : 
            AWREGION        => CSR_AWREGION    , -- I/O : 
            AWUSER          => CSR_AWUSER      , -- I/O : 
            AWID            => CSR_AWID        , -- I/O : 
            AWVALID         => CSR_AWVALID     , -- I/O : 
            AWREADY         => CSR_AWREADY     , -- In  :    
        --------------------------------------------------------------------------
        -- ライトデータチャネルシグナル.
        --------------------------------------------------------------------------
            WLAST           => CSR_WLAST       , -- I/O : 
            WDATA           => CSR_WDATA       , -- I/O : 
            WSTRB           => CSR_WSTRB       , -- I/O : 
            WUSER           => CSR_WUSER       , -- I/O : 
            WID             => CSR_WID         , -- I/O : 
            WVALID          => CSR_WVALID      , -- I/O : 
            WREADY          => CSR_WREADY      , -- In  :    
        --------------------------------------------------------------------------
        -- ライト応答チャネルシグナル.
        --------------------------------------------------------------------------
            BRESP           => CSR_BRESP       , -- In  :    
            BUSER           => CSR_BUSER       , -- In  :    
            BID             => CSR_BID         , -- In  :    
            BVALID          => CSR_BVALID      , -- In  :    
            BREADY          => CSR_BREADY      , -- I/O : 
        --------------------------------------------------------------------------
        -- シンクロ用信号
        --------------------------------------------------------------------------
            SYNC(0)         => SYNC(0)         , -- I/O :
            SYNC(1)         => SYNC(1)         , -- I/O :
        --------------------------------------------------------------------------
        -- GPIO
        --------------------------------------------------------------------------
            GPI             => CSR_GPI         , -- In  :
            GPO             => CSR_GPO         , -- Out :
        --------------------------------------------------------------------------
        -- 各種状態出力.
        --------------------------------------------------------------------------
            REPORT_STATUS   => CSR_REPORT      , -- Out :
            FINISH          => CSR_FINISH        -- Out :
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
            WIDTH           => CSR_WIDTH       , -- 
            READ_ENABLE     => TRUE            , -- 
            WRITE_ENABLE    => TRUE              --
        )                                        -- 
        port map (                               -- 
        ---------------------------------------------------------------------------
        -- グローバルシグナル.
        ---------------------------------------------------------------------------
            ACLK            => CSR_CLK         , -- In  :
            ARESETn         => ARESETn         , -- In  :
        ---------------------------------------------------------------------------
        -- リードアドレスチャネルシグナル.
        ---------------------------------------------------------------------------
            ARADDR          => CSR_ARADDR      , -- In  :
            ARLEN           => CSR_ARLEN       , -- In  :
            ARSIZE          => CSR_ARSIZE      , -- In  :
            ARBURST         => CSR_ARBURST     , -- In  :
            ARLOCK          => CSR_ARLOCK      , -- In  :
            ARCACHE         => CSR_ARCACHE     , -- In  :
            ARPROT          => CSR_ARPROT      , -- In  :
            ARQOS           => CSR_ARQOS       , -- In  :
            ARREGION        => CSR_ARREGION    , -- In  :
            ARUSER          => CSR_ARUSER      , -- In  :
            ARID            => CSR_ARID        , -- In  :
            ARVALID         => CSR_ARVALID     , -- In  :
            ARREADY         => CSR_ARREADY     , -- In  :
        ---------------------------------------------------------------------------
        -- リードチャネルシグナル.
        ---------------------------------------------------------------------------
            RLAST           => CSR_RLAST       , -- In  :
            RDATA           => CSR_RDATA       , -- In  :
            RRESP           => CSR_RRESP       , -- In  :
            RUSER           => CSR_RUSER       , -- In  :
            RID             => CSR_RID         , -- In  :
            RVALID          => CSR_RVALID      , -- In  :
            RREADY          => CSR_RREADY      , -- In  :
        ---------------------------------------------------------------------------
        -- ライトアドレスチャネルシグナル.
        ---------------------------------------------------------------------------
            AWADDR          => CSR_AWADDR      , -- In  :
            AWLEN           => CSR_AWLEN       , -- In  :
            AWSIZE          => CSR_AWSIZE      , -- In  :
            AWBURST         => CSR_AWBURST     , -- In  :
            AWLOCK          => CSR_AWLOCK      , -- In  :
            AWCACHE         => CSR_AWCACHE     , -- In  :
            AWPROT          => CSR_AWPROT      , -- In  :
            AWQOS           => CSR_AWQOS       , -- In  :
            AWREGION        => CSR_AWREGION    , -- In  :
            AWUSER          => CSR_AWUSER      , -- In  :
            AWID            => CSR_AWID        , -- In  :
            AWVALID         => CSR_AWVALID     , -- In  :
            AWREADY         => CSR_AWREADY     , -- In  :
        ---------------------------------------------------------------------------
        -- ライトデータチャネルシグナル.
        ---------------------------------------------------------------------------
            WLAST           => CSR_WLAST       , -- In  :
            WDATA           => CSR_WDATA       , -- In  :
            WSTRB           => CSR_WSTRB       , -- In  :
            WUSER           => CSR_WUSER       , -- In  :
            WID             => CSR_WID         , -- In  :
            WVALID          => CSR_WVALID      , -- In  :
            WREADY          => CSR_WREADY      , -- In  :
        ---------------------------------------------------------------------------
        -- ライト応答チャネルシグナル.
        ---------------------------------------------------------------------------
            BRESP           => CSR_BRESP       , -- In  :
            BUSER           => CSR_BUSER       , -- In  :
            BID             => CSR_BID         , -- In  :
            BVALID          => CSR_BVALID      , -- In  :
            BREADY          => CSR_BREADY        -- In  :
    );
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    RXD: AXI4_STREAM_MASTER_PLAYER               -- 
        generic map (                            -- 
            SCENARIO_FILE   => SCENARIO_FILE   , --
            NAME            => "RXD"           , --
            OUTPUT_DELAY    => DELAY           , --
            SYNC_PLUG_NUM   => 3               , --
            WIDTH           => RXD_WIDTH       , --
            SYNC_WIDTH      => SYNC_WIDTH      , --
            GPI_WIDTH       => GPI_WIDTH       , --
            GPO_WIDTH       => GPO_WIDTH       , --
            FINISH_ABORT    => FALSE             --
        )                                        -- 
        port map (                               -- 
            ACLK            => RXD_CLK         , -- In  :
            ARESETn         => ARESETn         , -- In  :
            TDATA           => RXD_TDATA       , -- Out :
            TSTRB           => RXD_TSTRB       , -- Out :
            TKEEP           => RXD_TKEEP       , -- Out :
            TUSER           => open            , -- Out :
            TDEST           => open            , -- Out :
            TID             => open            , -- Out :
            TLAST           => RXD_TLAST       , -- Out :
            TVALID          => RXD_TVALID      , -- Out :
            TREADY          => RXD_TREADY      , -- In  :
            SYNC            => SYNC            , -- I/O :
            GPI             => RXD_GPI         , -- In  :
            GPO             => RXD_GPO         , -- Out :
            REPORT_STATUS   => RXD_REPORT      , -- Out :
            FINISH          => RXD_FINISH        -- Out :
        );                                       -- 
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    TXD: AXI4_STREAM_SLAVE_PLAYER                -- 
        generic map (                            -- 
            SCENARIO_FILE   => SCENARIO_FILE   , --
            NAME            => "TXD"           , --
            OUTPUT_DELAY    => DELAY           , --
            SYNC_PLUG_NUM   => 5               , --
            WIDTH           => TXD_WIDTH       , --
            SYNC_WIDTH      => SYNC_WIDTH      , --
            GPI_WIDTH       => GPI_WIDTH       , --
            GPO_WIDTH       => GPO_WIDTH       , --
            FINISH_ABORT    => FALSE             --
        )                                        -- 
        port map(                                -- 
            ACLK            => TXD_CLK         , -- In  :
            ARESETn         => ARESETn         , -- In  :
            TDATA           => TXD_TDATA       , -- In  :
            TSTRB           => TXD_TKEEP       , -- In  :
            TKEEP           => TXD_TKEEP       , -- In  :
            TUSER           => TXD_TUSER       , -- In  :
            TDEST           => TXD_TDEST       , -- In  :
            TID             => TXD_TID         , -- In  :
            TLAST           => TXD_TLAST       , -- In  :
            TVALID          => TXD_TVALID      , -- In  :
            TREADY          => TXD_TREADY      , -- Out :
            SYNC            => SYNC            , -- Inou:
            GPI             => TXD_GPI         , -- In  :
            GPO             => TXD_GPO         , -- Out :
            REPORT_STATUS   => TXD_REPORT      , -- Out :
            FINISH          => TXD_FINISH        -- Out :
        );                                       -- 
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    DUT: PTTY_AXI4                               -- 
        generic map (                            -- 
            TXD_BUF_DEPTH   => TXD_BUF_DEPTH   , --
            RXD_BUF_DEPTH   => RXD_BUF_DEPTH   , --
            CSR_ADDR_WIDTH  => AXI4_ADDR_WIDTH , --
            CSR_DATA_WIDTH  => AXI4_DATA_WIDTH , --
            CSR_ID_WIDTH    => CSR_WIDTH.ID    , --
            RXD_BYTES       => RXD_BYTES       , --
            TXD_BYTES       => TXD_BYTES         --
        )                                        -- 
        port map (                               -- 
            ARESETn         => ARESETn         , -- In  :
            CSR_CLK         => CSR_CLK         , -- In  :
            CSR_ARID        => CSR_ARID        , -- In  :
            CSR_ARADDR      => CSR_ARADDR      , -- In  :
            CSR_ARLEN       => CSR_ARLEN       , -- In  :
            CSR_ARSIZE      => CSR_ARSIZE      , -- In  :
            CSR_ARBURST     => CSR_ARBURST     , -- In  :
            CSR_ARVALID     => CSR_ARVALID     , -- In  :
            CSR_ARREADY     => CSR_ARREADY     , -- Out :
            CSR_RID         => CSR_RID         , -- Out :
            CSR_RDATA       => CSR_RDATA       , -- Out :
            CSR_RRESP       => CSR_RRESP       , -- Out :
            CSR_RLAST       => CSR_RLAST       , -- Out :
            CSR_RVALID      => CSR_RVALID      , -- Out :
            CSR_RREADY      => CSR_RREADY      , -- In  :
            CSR_AWID        => CSR_AWID        , -- In  :
            CSR_AWADDR      => CSR_AWADDR      , -- In  :
            CSR_AWLEN       => CSR_AWLEN       , -- In  :
            CSR_AWSIZE      => CSR_AWSIZE      , -- In  :
            CSR_AWBURST     => CSR_AWBURST     , -- In  :
            CSR_AWVALID     => CSR_AWVALID     , -- In  :
            CSR_AWREADY     => CSR_AWREADY     , -- Out :
            CSR_WDATA       => CSR_WDATA       , -- In  :
            CSR_WSTRB       => CSR_WSTRB       , -- In  :
            CSR_WLAST       => CSR_WLAST       , -- In  :
            CSR_WVALID      => CSR_WVALID      , -- In  :
            CSR_WREADY      => CSR_WREADY      , -- Out :
            CSR_BID         => CSR_BID         , -- Out :
            CSR_BRESP       => CSR_BRESP       , -- Out :
            CSR_BVALID      => CSR_BVALID      , -- Out :
            CSR_BREADY      => CSR_BREADY      , -- In  :
            CSR_IRQ         => CSR_IRQ         , -- Out :
            RXD_CLK         => RXD_CLK         , -- In  :
            RXD_TDATA       => RXD_TDATA       , -- In  :
            RXD_TKEEP       => RXD_TKEEP       , -- In  :
            RXD_TLAST       => RXD_TLAST       , -- In  :
            RXD_TVALID      => RXD_TVALID      , -- In  :
            RXD_TREADY      => RXD_TREADY      , -- Out :
            TXD_CLK         => TXD_CLK         , -- In  :
            TXD_TDATA       => TXD_TDATA       , -- Out :
            TXD_TKEEP       => TXD_TKEEP       , -- Out :
            TXD_TLAST       => TXD_TLAST       , -- Out :
            TXD_TVALID      => TXD_TVALID      , -- Out :
            TXD_TREADY      => TXD_TREADY        -- In  :
        );
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    process begin
        CSR_CLK <= '0';
        wait for CSR_CLK_PERIOD / 2;
        CSR_CLK <= '1';
        wait for CSR_CLK_PERIOD / 2;
    end process;
    process begin
        RXD_CLK <= '0';
        wait for RXD_CLK_PERIOD / 2;
        RXD_CLK <= '1';
        wait for RXD_CLK_PERIOD / 2;
    end process;
    process begin
        TXD_CLK <= '0';
        wait for TXD_CLK_PERIOD / 2;
        TXD_CLK <= '1';
        wait for TXD_CLK_PERIOD / 2;
    end process;

    ARESETn <= '1' when (RESET = '0') else '0';
    CSR_GPI(0)<= CSR_IRQ;
    CSR_GPI(CSR_GPI'high downto 1) <= CSR_GPO(CSR_GPI'high downto 1);
    RXD_GPI   <= CSR_GPO;
    RXD_GPI   <= CSR_GPO;
    process
        variable L   : LINE;
        constant T   : STRING(1 to 7) := "  ***  ";
    begin
        wait until (CSR_FINISH'event and CSR_FINISH = '1');
        wait for DELAY;
        WRITE(L,T);                                                     WRITELINE(OUTPUT,L);
        WRITE(L,T & "ERROR REPORT " & NAME);                            WRITELINE(OUTPUT,L);
        WRITE(L,T & "[ CSR ]");                                         WRITELINE(OUTPUT,L);
        WRITE(L,T & "  Error    : ");WRITE(L,CSR_REPORT.error_count   );WRITELINE(OUTPUT,L);
        WRITE(L,T & "  Mismatch : ");WRITE(L,CSR_REPORT.mismatch_count);WRITELINE(OUTPUT,L);
        WRITE(L,T & "  Warning  : ");WRITE(L,CSR_REPORT.warning_count );WRITELINE(OUTPUT,L);
        WRITE(L,T & "[ TXD ]");                                         WRITELINE(OUTPUT,L);
        WRITE(L,T & "  Error    : ");WRITE(L,TXD_REPORT.error_count   );WRITELINE(OUTPUT,L);
        WRITE(L,T & "  Mismatch : ");WRITE(L,TXD_REPORT.mismatch_count);WRITELINE(OUTPUT,L);
        WRITE(L,T & "  Warning  : ");WRITE(L,TXD_REPORT.warning_count );WRITELINE(OUTPUT,L);
        WRITE(L,T & "[ RXD ]");                                         WRITELINE(OUTPUT,L);
        WRITE(L,T & "  Error    : ");WRITE(L,RXD_REPORT.error_count   );WRITELINE(OUTPUT,L);
        WRITE(L,T & "  Mismatch : ");WRITE(L,RXD_REPORT.mismatch_count);WRITELINE(OUTPUT,L);
        WRITE(L,T & "  Warning  : ");WRITE(L,RXD_REPORT.warning_count );WRITELINE(OUTPUT,L);
        WRITE(L,T);                                                     WRITELINE(OUTPUT,L);
        assert FALSE report "Simulation complete." severity FAILURE;
        wait;
    end process;
    
 -- SYNC_PRINT_0: SYNC_PRINT generic map(string'("AXI4_TEST_1:SYNC(0)")) port map (SYNC(0));
 -- SYNC_PRINT_1: SYNC_PRINT generic map(string'("AXI4_TEST_1:SYNC(1)")) port map (SYNC(1));
end MODEL;
-----------------------------------------------------------------------------------
--
-----------------------------------------------------------------------------------
