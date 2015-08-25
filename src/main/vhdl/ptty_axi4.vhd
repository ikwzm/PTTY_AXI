-----------------------------------------------------------------------------------
--!     @file    ptty_axi4.vhd
--!     @brief   PTTY_AXI4
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
-----------------------------------------------------------------------------------
--
-----------------------------------------------------------------------------------
entity  PTTY_AXI4 is
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
    -------------------------------------------------------------------------------
    -- Reset Signals.
    -------------------------------------------------------------------------------
        ARESETn         : in    std_logic;
    -------------------------------------------------------------------------------
    -- Control Status Register I/F Clock.
    -------------------------------------------------------------------------------
        C_CLK           : in    std_logic;
    -------------------------------------------------------------------------------
    -- Control Status Register I/F AXI4 Read Address Channel Signals.
    -------------------------------------------------------------------------------
        C_ARID          : in    std_logic_vector(C_ID_WIDTH    -1 downto 0);
        C_ARADDR        : in    std_logic_vector(C_ADDR_WIDTH  -1 downto 0);
        C_ARLEN         : in    std_logic_vector(7 downto 0);
        C_ARSIZE        : in    std_logic_vector(2 downto 0);
        C_ARBURST       : in    std_logic_vector(1 downto 0);
        C_ARVALID       : in    std_logic;
        C_ARREADY       : out   std_logic;
    -------------------------------------------------------------------------------
    -- Control Status Register I/F AXI4 Read Data Channel Signals.
    -------------------------------------------------------------------------------
        C_RID           : out   std_logic_vector(C_ID_WIDTH    -1 downto 0);
        C_RDATA         : out   std_logic_vector(C_DATA_WIDTH  -1 downto 0);
        C_RRESP         : out   std_logic_vector(1 downto 0);
        C_RLAST         : out   std_logic;
        C_RVALID        : out   std_logic;
        C_RREADY        : in    std_logic;
    -------------------------------------------------------------------------------
    -- Control Status Register I/F AXI4 Write Address Channel Signals.
    -------------------------------------------------------------------------------
        C_AWID          : in    std_logic_vector(C_ID_WIDTH    -1 downto 0);
        C_AWADDR        : in    std_logic_vector(C_ADDR_WIDTH  -1 downto 0);
        C_AWLEN         : in    std_logic_vector(7 downto 0);
        C_AWSIZE        : in    std_logic_vector(2 downto 0);
        C_AWBURST       : in    std_logic_vector(1 downto 0);
        C_AWVALID       : in    std_logic;
        C_AWREADY       : out   std_logic;
    -------------------------------------------------------------------------------
    -- Control Status Register I/F AXI4 Write Data Channel Signals.
    -------------------------------------------------------------------------------
        C_WDATA         : in    std_logic_vector(C_DATA_WIDTH  -1 downto 0);
        C_WSTRB         : in    std_logic_vector(C_DATA_WIDTH/8-1 downto 0);
        C_WLAST         : in    std_logic;
        C_WVALID        : in    std_logic;
        C_WREADY        : out   std_logic;
    -------------------------------------------------------------------------------
    -- Control Status Register I/F AXI4 Write Response Channel Signals.
    -------------------------------------------------------------------------------
        C_BID           : out   std_logic_vector(C_ID_WIDTH    -1 downto 0);
        C_BRESP         : out   std_logic_vector(1 downto 0);
        C_BVALID        : out   std_logic;
        C_BREADY        : in    std_logic;
    -------------------------------------------------------------------------------
    -- Interrupt
    -------------------------------------------------------------------------------
        C_IRQ           : out   std_logic;
    -------------------------------------------------------------------------------
    -- 入力側の信号
    -------------------------------------------------------------------------------
        I_CLK           : --! @brief INTAKE CLOCK :
                          --! 入力側のクロック信号.
                          in  std_logic;
        I_DATA          : --! @brief INTAKE DATA :
                          --! 入力側データ
                          in  std_logic_vector(8*I_BYTES-1 downto 0);
        I_STRB          : --! @brief INTAKE STROBE :
                          --! 入力側データ
                          in  std_logic_vector(  I_BYTES-1 downto 0);
        I_LAST          : --! @brief INTAKE LAST :
                          --! 入力側データ
                          in  std_logic;
        I_VALID         : --! @brief INTAKE ENABLE :
                          --! 入力有効信号.
                          in  std_logic;
        I_READY         : --! @brief INTAKE READY :
                          --! 入力許可信号.
                          out std_logic;
    -------------------------------------------------------------------------------
    -- 出力側の信号
    -------------------------------------------------------------------------------
        O_CLK           : --! @brief OUTLET CLOCK :
                          --! 出力側のクロック信号.
                          in  std_logic;
        O_DATA          : --! @brief OUTLET DATA :
                          --! 出力側データ
                          out std_logic_vector(8*O_BYTES-1 downto 0);
        O_STRB          : --! @brief OUTLET STROBE :
                          --! 出力側データ
                          out std_logic_vector(  O_BYTES-1 downto 0);
        O_LAST          : --! @brief OUTLET LAST :
                          --! 出力側データ
                          out std_logic;
        O_VALID         : --! @brief OUTLET ENABLE :
                          --! 出力有効信号.
                          out std_logic;
        O_READY         : --! @brief OUTLET READY :
                          --! 出力許可信号.
                          in  std_logic
    );
end PTTY_AXI4;
-----------------------------------------------------------------------------------
-- アーキテクチャ本体
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
library PIPEWORK;
use     PIPEWORK.AXI4_TYPES.all;
use     PIPEWORK.AXI4_COMPONENTS.AXI4_REGISTER_INTERFACE;
architecture RTL of PTTY_AXI4 is
    -------------------------------------------------------------------------------
    -- リセット信号.
    -------------------------------------------------------------------------------
    signal   RST                :  std_logic;
    constant CLR                :  std_logic := '0';
    -------------------------------------------------------------------------------
    -- レジスタアクセス用の信号群.
    -------------------------------------------------------------------------------
    signal   regs_req           :  std_logic;
    signal   regs_write         :  std_logic;
    signal   regs_ack           :  std_logic;
    signal   regs_err           :  std_logic;
    signal   regs_addr          :  std_logic_vector(C_ADDR_WIDTH  -1 downto 0);
    signal   regs_ben           :  std_logic_vector(C_DATA_WIDTH/8-1 downto 0);
    signal   regs_wdata         :  std_logic_vector(C_DATA_WIDTH  -1 downto 0);
    signal   regs_rdata         :  std_logic_vector(C_DATA_WIDTH  -1 downto 0);
    signal   regs_err_req       :  std_logic;
    signal   regs_err_ack       :  std_logic;
    -------------------------------------------------------------------------------
    -- PTTY_SEND アクセス用信号群.
    -------------------------------------------------------------------------------
    signal   send_reg_req       :  std_logic;
    signal   send_buf_req       :  std_logic;
    signal   send_ack           :  std_logic;
    signal   send_err           :  std_logic;
    signal   send_rdata         :  std_logic_vector(C_DATA_WIDTH  -1 downto 0);
    signal   send_irq           :  std_logic;
    -------------------------------------------------------------------------------
    -- PTTY_RECV アクセス用信号群.
    -------------------------------------------------------------------------------
    signal   recv_reg_req       :  std_logic;
    signal   recv_buf_req       :  std_logic;
    signal   recv_ack           :  std_logic;
    signal   recv_err           :  std_logic;
    signal   recv_rdata         :  std_logic_vector(C_DATA_WIDTH  -1 downto 0);
    signal   recv_irq           :  std_logic;
    -------------------------------------------------------------------------------
    -- レジスタマップ
    -------------------------------------------------------------------------------
    constant SEND_REG_AREA_LO   :  integer := 16#0010#;
    constant SEND_REG_AREA_HI   :  integer := 16#0017#;
    constant RECV_REG_AREA_LO   :  integer := 16#0020#;
    constant RECV_REG_AREA_HI   :  integer := 16#0027#;
    constant SEND_BUF_AREA_LO   :  integer := 16#1000#;
    constant SEND_BUF_AREA_HI   :  integer := 16#1FFF#;
    constant RECV_BUF_AREA_LO   :  integer := 16#2000#;
    constant RECV_BUF_AREA_HI   :  integer := 16#2FFF#;
    -------------------------------------------------------------------------------
    -- PTTY_SEND 
    -------------------------------------------------------------------------------
    component  PTTY_SEND
        generic (
            SBUF_DEPTH      : integer range 4 to    9 :=  7;
            C_ADDR_WIDTH    : integer range 1 to   64 := 32;
            C_DATA_WIDTH    : integer range 8 to 1024 := 32;
            O_BYTES         : integer := 1;
            O_CLK_RATE      : integer := 1;
            C_CLK_RATE      : integer := 1
        );
        port (
            RST             : in  std_logic;
            CLR             : in  std_logic;
            C_CLK           : in  std_logic;
            C_CKE           : in  std_logic;
            C_ADDR          : in  std_logic_vector(C_ADDR_WIDTH  -1 downto 0);
            C_BEN           : in  std_logic_vector(C_DATA_WIDTH/8-1 downto 0);
            C_WDATA         : in  std_logic_vector(C_DATA_WIDTH  -1 downto 0);
            C_RDATA         : out std_logic_vector(C_DATA_WIDTH  -1 downto 0);
            C_REG_REQ       : in  std_logic;
            C_BUF_REQ       : in  std_logic;
            C_WRITE         : in  std_logic;
            C_ACK           : out std_logic;
            C_ERR           : out std_logic;
            C_IRQ           : out std_logic;
            O_CLK           : in  std_logic;
            O_CKE           : in  std_logic;
            O_DATA          : out std_logic_vector(8*O_BYTES-1 downto 0);
            O_STRB          : out std_logic_vector(  O_BYTES-1 downto 0);
            O_LAST          : out std_logic;
            O_VALID         : out std_logic;
            O_READY         : in  std_logic
        );
    end component;
    -------------------------------------------------------------------------------
    -- PTTY_RECV
    -------------------------------------------------------------------------------
    component  PTTY_RECV
        generic (
            RBUF_DEPTH      : integer range 4 to    9 :=  7;
            C_ADDR_WIDTH    : integer range 1 to   64 := 32;
            C_DATA_WIDTH    : integer range 8 to 1024 := 32;
            I_BYTES         : integer := 1;
            I_CLK_RATE      : integer := 1;
            C_CLK_RATE      : integer := 1
        );
        port (
            RST             : in  std_logic;
            CLR             : in  std_logic;
            C_CLK           : in  std_logic;
            C_CKE           : in  std_logic;
            C_ADDR          : in  std_logic_vector(C_ADDR_WIDTH  -1 downto 0);
            C_BEN           : in  std_logic_vector(C_DATA_WIDTH/8-1 downto 0);
            C_WDATA         : in  std_logic_vector(C_DATA_WIDTH  -1 downto 0);
            C_RDATA         : out std_logic_vector(C_DATA_WIDTH  -1 downto 0);
            C_REG_REQ       : in  std_logic;
            C_BUF_REQ       : in  std_logic;
            C_WRITE         : in  std_logic;
            C_ACK           : out std_logic;
            C_ERR           : out std_logic;
            C_IRQ           : out std_logic;
            I_CLK           : in  std_logic;
            I_CKE           : in  std_logic;
            I_DATA          : in  std_logic_vector(8*I_BYTES-1 downto 0);
            I_STRB          : in  std_logic_vector(  I_BYTES-1 downto 0);
            I_LAST          : in  std_logic;
            I_VALID         : in  std_logic;
            I_READY         : out std_logic
        );
    end component;
begin
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    RST <= '1' when (ARESETn = '0') else '0';
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    AXI4: AXI4_REGISTER_INTERFACE                  --
        generic map (                              -- 
            AXI4_ADDR_WIDTH => C_ADDR_WIDTH      , --
            AXI4_DATA_WIDTH => C_DATA_WIDTH      , --
            AXI4_ID_WIDTH   => C_ID_WIDTH        , --
            REGS_ADDR_WIDTH => C_ADDR_WIDTH      , --
            REGS_DATA_WIDTH => C_DATA_WIDTH        --
        )                                          -- 
        port map (                                 -- 
        -----------------------------------------------------------------------
        -- Clock and Reset Signals.
        -----------------------------------------------------------------------
            CLK             => C_CLK             , -- In  :
            RST             => RST               , -- In  :
            CLR             => CLR               , -- In  :
        -----------------------------------------------------------------------
        -- AXI4 Read Address Channel Signals.
        -----------------------------------------------------------------------
            ARID            => C_ARID            , -- In  :
            ARADDR          => C_ARADDR          , -- In  :
            ARLEN           => C_ARLEN           , -- In  :
            ARSIZE          => C_ARSIZE          , -- In  :
            ARBURST         => C_ARBURST         , -- In  :
            ARVALID         => C_ARVALID         , -- In  :
            ARREADY         => C_ARREADY         , -- Out :
        -----------------------------------------------------------------------
        -- AXI4 Read Data Channel Signals.
        -----------------------------------------------------------------------
            RID             => C_RID             , -- Out :
            RDATA           => C_RDATA           , -- Out :
            RRESP           => C_RRESP           , -- Out :
            RLAST           => C_RLAST           , -- Out :
            RVALID          => C_RVALID          , -- Out :
            RREADY          => C_RREADY          , -- In  :
        -----------------------------------------------------------------------
        -- AXI4 Write Address Channel Signals.
        -----------------------------------------------------------------------
            AWID            => C_AWID            , -- In  :
            AWADDR          => C_AWADDR          , -- In  :
            AWLEN           => C_AWLEN           , -- In  :
            AWSIZE          => C_AWSIZE          , -- In  :
            AWBURST         => C_AWBURST         , -- In  :
            AWVALID         => C_AWVALID         , -- In  :
            AWREADY         => C_AWREADY         , -- Out :
        -----------------------------------------------------------------------
        -- AXI4 Write Data Channel Signals.
        -----------------------------------------------------------------------
            WDATA           => C_WDATA           , -- In  :
            WSTRB           => C_WSTRB           , -- In  :
            WLAST           => C_WLAST           , -- In  :
            WVALID          => C_WVALID          , -- In  :
            WREADY          => C_WREADY          , -- Out :
        -----------------------------------------------------------------------
        -- AXI4 Write Response Channel Signals.
        -----------------------------------------------------------------------
            BID             => C_BID             , -- Out :
            BRESP           => C_BRESP           , -- Out :
            BVALID          => C_BVALID          , -- Out :
            BREADY          => C_BREADY          , -- In  :
        -----------------------------------------------------------------------
        -- Register Interface.
        -----------------------------------------------------------------------
            REGS_REQ        => regs_req          , -- Out :
            REGS_WRITE      => regs_write        , -- Out :
            REGS_ACK        => regs_ack          , -- In  :
            REGS_ERR        => regs_err          , -- In  :
            REGS_ADDR       => regs_addr         , -- Out :
            REGS_BEN        => regs_ben          , -- Out :
            REGS_WDATA      => regs_wdata        , -- Out :
            REGS_RDATA      => regs_rdata          -- In  :
        );                                         -- 
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    process (regs_req, regs_addr)
        variable u_addr       : unsigned(C_ADDR_WIDTH-1 downto 0);
        variable send_reg_sel : boolean;
        variable send_buf_sel : boolean;
        variable recv_reg_sel : boolean;
        variable recv_buf_sel : boolean;
    begin
        if (regs_req = '1') then
            u_addr       := to_01(unsigned(regs_addr));
            send_reg_sel := (SEND_REG_AREA_LO <= u_addr and u_addr <= SEND_REG_AREA_HI);
            send_buf_sel := (SEND_BUF_AREA_LO <= u_addr and u_addr <= SEND_BUF_AREA_HI);
            recv_reg_sel := (RECV_REG_AREA_LO <= u_addr and u_addr <= RECV_REG_AREA_HI);
            recv_buf_sel := (RECV_BUF_AREA_LO <= u_addr and u_addr <= RECV_BUF_AREA_HI);
            if (send_reg_sel) then
                send_reg_req <= '1';
            else
                send_reg_req <= '0';
            end if;
            if (send_buf_sel) then
                send_buf_req <= '1';
            else
                send_buf_req <= '0';
            end if;
            if (recv_reg_sel) then
                recv_reg_req <= '1';
            else
                recv_reg_req <= '0';
            end if;
            if (recv_buf_sel) then
                recv_buf_req <= '1';
            else
                recv_buf_req <= '0';
            end if;
            if (send_reg_sel = FALSE) and
               (send_buf_sel = FALSE) and
               (recv_reg_sel = FALSE) and
               (recv_buf_sel = FALSE) then
                regs_err_req <= '1';
            else
                regs_err_req <= '0';
            end if;
        else
                send_reg_req <= '0';
                send_buf_req <= '0';
                recv_reg_req <= '0';
                recv_buf_req <= '0';
                regs_err_req <= '0';
        end if;
    end process;
    regs_err_ack <= regs_err_req;
    regs_ack     <= send_ack   or recv_ack or regs_err_ack;
    regs_err     <= send_err   or recv_err;
    regs_rdata   <= send_rdata or recv_rdata;
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    SEND:  PTTY_SEND                               -- 
        generic map (                              -- 
            SBUF_DEPTH      => SBUF_DEPTH        , -- 
            C_ADDR_WIDTH    => C_ADDR_WIDTH      , -- 
            C_DATA_WIDTH    => C_DATA_WIDTH      , -- 
            O_BYTES         => O_BYTES           , -- 
            O_CLK_RATE      => 0                 , -- 
            C_CLK_RATE      => 0                   -- 
        )                                          -- 
        port map (                                 -- 
            RST             => RST               , -- In  :
            CLR             => CLR               , -- In  :
            C_CLK           => C_CLK             , -- In  :
            C_CKE           => '1'               , -- In  :
            C_ADDR          => regs_addr         , -- In  :
            C_BEN           => regs_ben          , -- In  :
            C_WDATA         => regs_wdata        , -- In  :
            C_RDATA         => send_rdata        , -- Out :
            C_REG_REQ       => send_reg_req      , -- In  :
            C_BUF_REQ       => send_buf_req      , -- In  :
            C_WRITE         => regs_write        , -- In  :
            C_ACK           => send_ack          , -- Out :
            C_ERR           => send_err          , -- Out :
            C_IRQ           => send_irq          , -- Out :
            O_CLK           => O_CLK             , -- In  :
            O_CKE           => '1'               , -- In  :
            O_DATA          => O_DATA            , -- Out :
            O_STRB          => O_STRB            , -- Out :
            O_LAST          => O_LAST            , -- Out :
            O_VALID         => O_VALID           , -- Out :
            O_READY         => O_READY             -- In  :
        );                                         -- 
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    RECV: PTTY_RECV                                -- 
        generic map (                              -- 
            RBUF_DEPTH      => RBUF_DEPTH        , --
            C_ADDR_WIDTH    => C_ADDR_WIDTH      , --
            C_DATA_WIDTH    => C_DATA_WIDTH      , --
            I_BYTES         => I_BYTES           , --
            I_CLK_RATE      => 0                 , --
            C_CLK_RATE      => 0                   --
        )                                          -- 
        port map (                                 -- 
            RST             => RST               , -- In  :
            CLR             => CLR               , -- In  :
            C_CLK           => C_CLK             , -- In  :
            C_CKE           => '1'               , -- In  :
            C_ADDR          => regs_addr         , -- In  :
            C_BEN           => regs_ben          , -- In  :
            C_WDATA         => regs_wdata        , -- In  :
            C_RDATA         => recv_rdata        , -- Out :
            C_REG_REQ       => recv_reg_req      , -- In  :
            C_BUF_REQ       => recv_buf_req      , -- In  :
            C_WRITE         => regs_write        , -- In  :
            C_ACK           => recv_ack          , -- Out :
            C_ERR           => recv_err          , -- Out :
            C_IRQ           => recv_irq          , -- Out :
            I_CLK           => I_CLK             , -- In  :
            I_CKE           => '1'               , -- In  :
            I_DATA          => I_DATA            , -- In  :
            I_STRB          => I_STRB            , -- In  :
            I_LAST          => I_LAST            , -- In  :
            I_VALID         => I_VALID           , -- In  :
            I_READY         => I_READY             -- Out :
        );                                         --
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    C_IRQ <= '1' when (send_irq = '1' or recv_irq = '1') else '0';
end RTL;
