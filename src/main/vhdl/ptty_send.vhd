-----------------------------------------------------------------------------------
--!     @file    ptty_send
--!     @brief   PTTY SEND CORE
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
entity  PTTY_SEND is
    generic (
        SBUF_DEPTH      : --! @brief BUFFER DEPTH :
                          --! バッファの容量(バイト数)を２のべき乗値で指定する.
                          integer range 4 to    9 :=  7;
        C_ADDR_WIDTH    : --! @brief REGISTER INTERFACE ADDRESS WIDTH :
                          --! レジスタアクセスのアドレスのビット幅を指定する.
                          integer range 1 to   64 := 32;
        C_DATA_WIDTH    : --! @brief REGISTER INTERFACE DATA WIDTH :
                          --! レジスタアクセスのデータのビット幅を指定する.
                          integer range 8 to 1024 := 32;
        O_BYTES         : --! @brief OUTLET DATA WIDTH :
                          --! 出力側のデータ幅(バイト数)を指定する.
                          integer := 1;
        O_CLK_RATE      : --! @brief OUTLET CLOCK RATE :
                          --! C_CLK_RATEとペアで出力側のクロック(O_CLK)とレジスタ
                          --! アクセス側のクロック(C_CLK)との関係を指定する.
                          integer := 1;
        C_CLK_RATE      : --! @brief REGISTER INTERFACE CLOCK RATE :
                          --! O_CLK_RATEとペアで出力側のクロック(O_CLK)とレジスタ
                          --! アクセス側のクロック(C_CLK)との関係を指定する.
                          integer := 1
    );
    port (
    -------------------------------------------------------------------------------
    -- Reset Signals.
    -------------------------------------------------------------------------------
        RST             : in  std_logic;
        CLR             : in  std_logic;
    -------------------------------------------------------------------------------
    -- Control Status Register Access Interface
    -------------------------------------------------------------------------------
        C_CLK           : --! @breif REGISTER INTERFACE CLOCK :
                          in  std_logic;
        C_CKE           : --! @breif REGISTER INTERFACE CLOCK ENABLE:
                          in  std_logic;
        C_ADDR          : --! @breif REGISTER ADDRESS :
                          in  std_logic_vector(C_ADDR_WIDTH  -1 downto 0);
        C_BEN           : --! @breif REGISTER BYTE ENABLE :
                          in  std_logic_vector(C_DATA_WIDTH/8-1 downto 0);
        C_WDATA         : --! @breif REGISTER WRITE DATA :
                          in  std_logic_vector(C_DATA_WIDTH  -1 downto 0);
        C_RDATA         : --! @breif REGISTER READ DATA :
                          out std_logic_vector(C_DATA_WIDTH  -1 downto 0);
        C_REG_REQ       : --! @breif REGISTER ACCESS REQUEST :
                          in  std_logic;
        C_BUF_REQ       : --! @breif REGISTER ACCESS REQUEST :
                          in  std_logic;
        C_WRITE         : --! @breif REGISTER ACCESS WRITE  :
                          in  std_logic;
        C_ACK           : --! @breif REGISTER ACCESS ACKNOWLEDGE :
                          out std_logic;
        C_ERR           : --! @breif REGISTER ACCESS ERROR ACKNOWLEDGE :
                          out std_logic;
        C_IRQ           : --! @breif INTERRUPT
                          out std_logic;
    -------------------------------------------------------------------------------
    -- 出力側の信号
    -------------------------------------------------------------------------------
        O_CLK           : --! @brief OUTLET CLOCK :
                          --! 出力側のクロック信号.
                          in  std_logic;
        O_CKE           : --! @brief OUTLET CLOCK ENABLE :
                          --! 出力側のクロック(I_CLK)の立上りが有効であることを示す信号.
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
end PTTY_SEND;
-----------------------------------------------------------------------------------
-- アーキテクチャ本体
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
library PIPEWORK;
use     PIPEWORK.COMPONENTS.REGISTER_ACCESS_ADAPTER;
architecture RTL of PTTY_SEND is
    -------------------------------------------------------------------------------
    -- SBUF_WIDTH : 送信バッファのデータ幅のバイト数を２のべき乗で示した値.
    -------------------------------------------------------------------------------
    function   CALC_SBUF_WIDTH return integer is
        variable width : integer;
    begin
        width := 0;
        while (2**(width+3) < C_DATA_WIDTH) loop
            width := width + 1;
        end loop;
        return width;
    end function;
    constant   SBUF_WIDTH         :  integer := CALC_SBUF_WIDTH;
    -------------------------------------------------------------------------------
    -- レジスタアクセスインターフェースのアドレスのビット数.
    -------------------------------------------------------------------------------
    constant   REGS_ADDR_WIDTH    :  integer := 3;
    -------------------------------------------------------------------------------
    -- 全レジスタのビット数.
    -------------------------------------------------------------------------------
    constant   REGS_DATA_BITS     :  integer := (2**REGS_ADDR_WIDTH)*8;
    -------------------------------------------------------------------------------
    -- レジスタアクセス用の信号群.
    -------------------------------------------------------------------------------
    signal     regs_addr          :  std_logic_vector(REGS_ADDR_WIDTH  -1 downto 0);
    signal     regs_rdata         :  std_logic_vector(C_DATA_WIDTH     -1 downto 0);
    signal     regs_ack           :  std_logic;
    signal     regs_err           :  std_logic;
    signal     regs_load          :  std_logic_vector(REGS_DATA_BITS   -1 downto 0);
    signal     regs_wbit          :  std_logic_vector(REGS_DATA_BITS   -1 downto 0);
    signal     regs_rbit          :  std_logic_vector(REGS_DATA_BITS   -1 downto 0);
    -------------------------------------------------------------------------------
    -- バッファアクセス用の信号群.
    -------------------------------------------------------------------------------
    signal     sbuf_we            :  std_logic_vector(2**(SBUF_WIDTH  )-1 downto 0);
    signal     sbuf_addr          :  std_logic_vector(SBUF_DEPTH       -1 downto 0);
    constant   sbuf_ack           :  std_logic := '1';
    constant   sbuf_err           :  std_logic := '0';
    constant   sbuf_rdata         :  std_logic_vector(C_DATA_WIDTH     -1 downto 0) := (others => '0');
    -------------------------------------------------------------------------------
    -- レジスタのアドレスマップ.
    -------------------------------------------------------------------------------
    --           31            24              16               8               0
    --           +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    -- Addr=0x00 |          BufPtr[15:0]         |       BufCount[15:00]         |
    --           +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    -- Addr=0x04 | Control[7:0]  |  Status[7:0]  |       PushSize[15:00]         |
    --           +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    -------------------------------------------------------------------------------
    constant   REGS_BASE_ADDR     :  integer := 16#00#;
    -------------------------------------------------------------------------------
    -- BufCount[15:0]
    -------------------------------------------------------------------------------
    constant   REGS_BUF_COUNT_ADDR:  integer := REGS_BASE_ADDR        + 16#00#;
    constant   REGS_BUF_COUNT_BITS:  integer := 16;
    constant   REGS_BUF_COUNT_LO  :  integer := 8*REGS_BUF_COUNT_ADDR + 0;
    constant   REGS_BUF_COUNT_HI  :  integer := 8*REGS_BUF_COUNT_ADDR + REGS_BUF_COUNT_BITS-1;
    signal     sbuf_count         :  std_logic_vector(SBUF_DEPTH   downto 0);
    -------------------------------------------------------------------------------
    -- BufPtr[15:0]
    -------------------------------------------------------------------------------
    constant   REGS_BUF_PTR_ADDR  :  integer := REGS_BASE_ADDR        + 16#02#;
    constant   REGS_BUF_PTR_BITS  :  integer := 16;
    constant   REGS_BUF_PTR_LO    :  integer := 8*REGS_BUF_PTR_ADDR   + 0;
    constant   REGS_BUF_PTR_HI    :  integer := 8*REGS_BUF_PTR_ADDR   + REGS_BUF_PTR_BITS-1;
    signal     sbuf_ptr           :  std_logic_vector(SBUF_DEPTH-1 downto 0);
    -------------------------------------------------------------------------------
    -- PushSize[15:0]
    -------------------------------------------------------------------------------
    constant   REGS_PUSH_SIZE_ADDR:  integer := REGS_BASE_ADDR        + 16#04#;
    constant   REGS_PUSH_SIZE_BITS:  integer := 16;
    constant   REGS_PUSH_SIZE_LO  :  integer := 8*REGS_PUSH_SIZE_ADDR + 0;
    constant   REGS_PUSH_SIZE_HI  :  integer := 8*REGS_PUSH_SIZE_ADDR + REGS_PUSH_SIZE_BITS-1;
    signal     sbuf_push_size     :  std_logic_vector(SBUF_DEPTH   downto 0);
    -------------------------------------------------------------------------------
    -- Status[7:0]
    -------------------------------------------------------------------------------
    -- Status[7:1] = 予約
    -- Status[0]   = バッファが空 かつ Control[2]=1 の時このフラグがセットされる
    -------------------------------------------------------------------------------
    constant   REGS_STAT_ADDR     :  integer := REGS_BASE_ADDR        + 16#06#;
    constant   REGS_STAT_RESV_HI  :  integer := 8*REGS_STAT_ADDR      +  7;
    constant   REGS_STAT_RESV_LO  :  integer := 8*REGS_STAT_ADDR      +  1;
    constant   REGS_STAT_DONE_POS :  integer := 8*REGS_STAT_ADDR      +  0;
    signal     stat_done_bit      :  std_logic;
    -------------------------------------------------------------------------------
    -- Control[7:0]
    -------------------------------------------------------------------------------
    -- Control[7]  = 1:モジュールをリセットする. 0:リセットを解除する.
    -- Control[6]  = 1:転送を一時中断する.       0:転送を再開する.
    -- Control[5]  = 1:転送を中止する.           0:意味無し.
    -- Control[4]  = 1:転送を開始する.           0:意味無し.
    -- Control[3]  = 予約.
    -- Control[2]  = 1:バッファが空の時にStatus[0]がセットされる.
    -- Control[1]  = 予約.
    -- Control[0]  = 1:最後の送信であることを指定する.
    -------------------------------------------------------------------------------
    constant   REGS_CTRL_ADDR     :  integer := REGS_BASE_ADDR        + 16#07#;
    constant   REGS_CTRL_RESET_POS:  integer := 8*REGS_CTRL_ADDR      +  7;
    constant   REGS_CTRL_PAUSE_POS:  integer := 8*REGS_CTRL_ADDR      +  6;
    constant   REGS_CTRL_ABORT_POS:  integer := 8*REGS_CTRL_ADDR      +  5;
    constant   REGS_CTRL_PUSH_POS :  integer := 8*REGS_CTRL_ADDR      +  4;
    constant   REGS_CTRL_RSV3_POS :  integer := 8*REGS_CTRL_ADDR      +  3;
    constant   REGS_CTRL_DONE_POS :  integer := 8*REGS_CTRL_ADDR      +  2;
    constant   REGS_CTRL_RSV1_POS :  integer := 8*REGS_CTRL_ADDR      +  1;
    constant   REGS_CTRL_LAST_POS :  integer := 8*REGS_CTRL_ADDR      +  0;
    signal     ctrl_reset_bit     :  std_logic;
    signal     ctrl_pause_bit     :  std_logic;
    signal     ctrl_abort_bit     :  std_logic;
    signal     ctrl_push_bit      :  std_logic;
    signal     ctrl_done_bit      :  std_logic;
    signal     ctrl_last_bit      :  std_logic;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    function   resize(I : std_logic_vector; BITS: integer) return std_logic_vector is
        alias    vec    : std_logic_vector(I'length-1 downto 0) is I;
        variable result : std_logic_vector(    BITS-1 downto 0);
    begin
        for i in result'range loop
            if vec'high <= i and i <= vec'low then
                result(i) := vec(i);
            else
                result(i) := '0';
            end if;
        end loop;
        return result;
    end function;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    component  SEND_BUF is
        generic (
            BUF_DEPTH   : integer := 8;
            BUF_WIDTH   : integer := 2;
            O_BYTES     : integer := 1;
            O_CLK_RATE  : integer := 1;
            S_CLK_RATE  : integer := 1
        );
        port (
            RST         : in  std_logic;
            O_CLK       : in  std_logic;
            O_CKE       : in  std_logic;
            O_DATA      : out std_logic_vector(8*O_BYTES-1 downto 0);
            O_STRB      : out std_logic_vector(  O_BYTES-1 downto 0);
            O_LAST      : out std_logic;
            O_VALID     : out std_logic;
            O_READY     : in  std_logic;
            S_CLK       : in  std_logic;
            S_CKE       : in  std_logic;
            BUF_WDATA   : in  std_logic_vector(2**(BUF_WIDTH+3)-1 downto 0);
            BUF_WE      : in  std_logic_vector(2**(BUF_WIDTH  )-1 downto 0);
            BUF_WADDR   : in  std_logic_vector(BUF_DEPTH-1 downto 0);
            BUF_COUNT   : out std_logic_vector(BUF_DEPTH   downto 0);
            BUF_CADDR   : out std_logic_vector(BUF_DEPTH-1 downto 0);
            BUF_LAST    : out std_logic;
            PUSH_SIZE   : in  std_logic_vector(BUF_DEPTH   downto 0);
            PUSH_LAST   : in  std_logic;
            PUSH_LOAD   : in  std_logic;
            RESET_DATA  : in  std_logic;
            RESET_LOAD  : in  std_logic
        );
    end component;
begin
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    regs_addr <= C_ADDR(regs_addr'range);
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    sbuf_addr <= C_ADDR(sbuf_addr'range);
    sbuf_we   <= C_BEN when (C_BUF_REQ = '1' and C_WRITE = '1') else (others => '0');
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    C_RDATA   <= regs_rdata when (C_REG_REQ = '1') else
                 sbuf_rdata when (C_BUF_REQ = '1') else (others => '0');
    C_ACK     <= '1'        when (C_REG_REQ = '1' and regs_ack = '1') or
                                 (C_BUF_REQ = '1' and sbuf_ack = '1') else '0';
    C_ERR     <= '1'        when (C_REG_REQ = '1' and regs_err = '1') or
                                 (C_BUF_REQ = '1' and sbuf_err = '1') else '0';
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    DEC: REGISTER_ACCESS_ADAPTER                               -- 
        generic map (                                          -- 
            ADDR_WIDTH      => REGS_ADDR_WIDTH               , -- 
            DATA_WIDTH      => C_DATA_WIDTH                  , -- 
            WBIT_MIN        => regs_wbit'low                 , -- 
            WBIT_MAX        => regs_wbit'high                , -- 
            RBIT_MIN        => regs_rbit'low                 , -- 
            RBIT_MAX        => regs_rbit'high                , -- 
            I_CLK_RATE      => 1                             , -- 
            O_CLK_RATE      => 1                             , -- 
            O_CLK_REGS      => 1                               -- 
        )                                                      -- 
        port map (                                             -- 
            RST             => RST                           , -- In  :
            I_CLK           => C_CLK                         , -- In  :
            I_CLR           => CLR                           , -- In  :
            I_CKE           => '1'                           , -- In  :
            I_REQ           => C_REG_REQ                     , -- In  :
            I_SEL           => '1'                           , -- In  :
            I_WRITE         => C_WRITE                       , -- In  :
            I_ADDR          => regs_addr                     , -- In  :
            I_BEN           => C_BEN                         , -- In  :
            I_WDATA         => C_WDATA                       , -- In  :
            I_RDATA         => regs_rdata                    , -- Out :
            I_ACK           => regs_ack                      , -- Out :
            I_ERR           => regs_err                      , -- Out :
            O_CLK           => C_CLK                         , -- In  :
            O_CLR           => CLR                           , -- In  :
            O_CKE           => '1'                           , -- In  :
            O_WDATA         => regs_wbit                     , -- Out :
            O_WLOAD         => regs_load                     , -- Out :
            O_RDATA         => regs_rbit                       -- In  :
        );                                                     -- 
    -------------------------------------------------------------------------------
    -- BufCount[15:0]
    -------------------------------------------------------------------------------
    regs_rbit(REGS_BUF_COUNT_HI downto REGS_BUF_COUNT_LO) <= resize(sbuf_count, REGS_BUF_COUNT_BITS);
    -------------------------------------------------------------------------------
    -- BufPtr[15:0]
    -------------------------------------------------------------------------------
    regs_rbit(REGS_BUF_PTR_HI   downto REGS_BUF_PTR_LO  ) <= resize(sbuf_ptr  , REGS_BUF_PTR_BITS  );
    -------------------------------------------------------------------------------
    -- PushSize[15:0]
    -------------------------------------------------------------------------------
    process (C_CLK, RST) begin
        if (RST = '1') then
                sbuf_push_size <= (others => '0');
        elsif (C_CLK'event and C_CLK = '1') then
            if (CLR = '1' or ctrl_reset_bit = '1') then
                sbuf_push_size <= (others => '0');
            else
                for i in sbuf_push_size'range loop
                    if (regs_load(REGS_PUSH_SIZE_LO+i) = '1') then
                        sbuf_push_size(i) <= regs_wbit(REGS_PUSH_SIZE_LO+i);
                    end if;
                end loop;
            end if;
        end if;
    end process;
    regs_rbit(REGS_PUSH_SIZE_HI downto REGS_PUSH_SIZE_LO) <= resize(sbuf_push_size, REGS_PUSH_SIZE_BITS);
    -------------------------------------------------------------------------------
    -- Status[7:0] (T.B.D)
    -------------------------------------------------------------------------------
    process (C_CLK, RST) begin
        if (RST = '1') then
                stat_done_bit <= '0';
        elsif (C_CLK'event and C_CLK = '1') then
            if (CLR = '1' or ctrl_reset_bit = '1') then
                stat_done_bit <= '0';
            elsif (ctrl_done_bit = '1' and unsigned(sbuf_count) = 0) then
                stat_done_bit <= '1';
            elsif (regs_load(REGS_STAT_DONE_POS) = '1' and regs_wbit(REGS_STAT_DONE_POS) = '0') then
                stat_done_bit <= '0';
            end if;
        end if;
    end process;
    C_IRQ <= '1' when (stat_done_bit = '1') else '0';
    regs_rbit(REGS_STAT_DONE_POS) <= stat_done_bit;
    regs_rbit(REGS_STAT_RESV_HI downto REGS_STAT_RESV_LO) <= (REGS_STAT_RESV_HI downto REGS_STAT_RESV_LO => '0');
    -------------------------------------------------------------------------------
    -- Control[7:0]
    -------------------------------------------------------------------------------
    process (C_CLK, RST) begin
        if (RST = '1') then
                ctrl_reset_bit <= '0';
                ctrl_pause_bit <= '0';
                ctrl_abort_bit <= '0';
                ctrl_push_bit  <= '0';
                ctrl_done_bit  <= '0';
                ctrl_last_bit  <= '0';
        elsif (C_CLK'event and C_CLK = '1') then
            if (CLR = '1') then
                ctrl_reset_bit <= '0';
                ctrl_pause_bit <= '0';
                ctrl_abort_bit <= '0';
                ctrl_push_bit  <= '0';
                ctrl_done_bit  <= '0';
                ctrl_last_bit  <= '0';
            elsif (ctrl_reset_bit = '1') then
                ctrl_pause_bit <= '0';
                ctrl_abort_bit <= '0';
                ctrl_push_bit  <= '0';
                ctrl_done_bit  <= '0';
                ctrl_last_bit  <= '0';
            else
                if (regs_load(REGS_CTRL_RESET_POS) = '1') then
                    ctrl_reset_bit <= regs_wbit(REGS_CTRL_RESET_POS);
                end if;
                if (regs_load(REGS_CTRL_PAUSE_POS) = '1') then
                    ctrl_pause_bit <= regs_wbit(REGS_CTRL_PAUSE_POS);
                end if;
                if (regs_load(REGS_CTRL_ABORT_POS) = '1') then
                    ctrl_abort_bit <= regs_wbit(REGS_CTRL_ABORT_POS);
                else
                    ctrl_abort_bit <= '0';
                end if;
                if (regs_load(REGS_CTRL_PUSH_POS ) = '1') then
                    ctrl_push_bit  <= regs_wbit(REGS_CTRL_PUSH_POS );
                else
                    ctrl_push_bit  <= '0';
                end if;
                if (regs_load(REGS_CTRL_DONE_POS ) = '1') then
                    ctrl_done_bit  <= regs_wbit(REGS_CTRL_DONE_POS );
                end if;
                if (regs_load(REGS_CTRL_LAST_POS ) = '1') then
                    ctrl_last_bit  <= regs_wbit(REGS_CTRL_LAST_POS );
                end if;
            end if;
        end if;
    end process;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    regs_rbit(REGS_CTRL_RESET_POS) <= ctrl_reset_bit;
    regs_rbit(REGS_CTRL_PAUSE_POS) <= ctrl_pause_bit;
    regs_rbit(REGS_CTRL_ABORT_POS) <= ctrl_abort_bit;
    regs_rbit(REGS_CTRL_PUSH_POS ) <= ctrl_push_bit;
    regs_rbit(REGS_CTRL_RSV3_POS ) <= '0';
    regs_rbit(REGS_CTRL_DONE_POS ) <= ctrl_done_bit;
    regs_rbit(REGS_CTRL_RSV1_POS ) <= '0';
    regs_rbit(REGS_CTRL_LAST_POS ) <= ctrl_last_bit;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    BUF: SEND_BUF                                              -- 
        generic map (                                          -- 
            BUF_DEPTH       => SBUF_DEPTH                    , --
            BUF_WIDTH       => SBUF_WIDTH                    , --
            O_BYTES         => O_BYTES                       , --
            O_CLK_RATE      => O_CLK_RATE                    , --
            S_CLK_RATE      => C_CLK_RATE                      --
        )                                                      -- 
        port map (                                             -- 
            RST             => RST                           , -- In  :
            O_CLK           => O_CLK                         , -- In  :
            O_CKE           => O_CKE                         , -- In  :
            O_DATA          => O_DATA                        , -- Out :
            O_STRB          => O_STRB                        , -- Out :
            O_LAST          => O_LAST                        , -- Out :
            O_VALID         => O_VALID                       , -- Out :
            O_READY         => O_READY                       , -- In  :
            S_CLK           => C_CLK                         , -- In  :
            S_CKE           => C_CKE                         , -- In  :
            BUF_WDATA       => C_WDATA                       , -- In  :
            BUF_WE          => sbuf_we                       , -- In  :
            BUF_WADDR       => sbuf_addr                     , -- In  :
            BUF_COUNT       => sbuf_count                    , -- Out :
            BUF_CADDR       => sbuf_ptr                      , -- Out :
            BUF_LAST        => open                          , -- Out :
            PUSH_SIZE       => sbuf_push_size                , -- In  :
            PUSH_LAST       => ctrl_last_bit                 , -- In  :
            PUSH_LOAD       => ctrl_push_bit                 , -- In  :
            RESET_DATA      => regs_wbit(REGS_CTRL_RESET_POS), -- In  :
            RESET_LOAD      => regs_load(REGS_CTRL_RESET_POS)  -- In  :
        );
end RTL;
