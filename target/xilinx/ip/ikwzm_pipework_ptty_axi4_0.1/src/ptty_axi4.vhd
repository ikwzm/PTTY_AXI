-----------------------------------------------------------------------------------
--!     @file    ptty_rxd_buf.vhd
--!     @brief   Receive Data Buffer for PTTY_AXI4
--!     @version 0.1.0
--!     @date    2015/8/29
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
--! @brief 受信バッファ
-----------------------------------------------------------------------------------
entity  PTTY_RXD_BUF is
    generic (
        BUF_DEPTH   : --! @brief BUFFER DEPTH :
                      --! バッファの容量(バイト数)を２のべき乗値で指定する.
                      integer := 8;
        BUF_WIDTH   : --! @brief BUFFER DATA WIDTH :
                      --! バッファのデータ幅(バイト数)を２のべき乗値で指定する.
                      integer := 2;
        I_BYTES     : --! @brief INTAKE DATA WIDTH :
                      --! 入力側のデータ幅(バイト数)を指定する.
                      --! 現時点では入力側のデータ幅は１バイトの場合のみ実装している.
                      integer range 1 to 1 := 1;
        I_CLK_RATE  : --! @brief INTAKE CLOCK RATE :
                      --! S_CLK_RATEとペアで入力側のクロック(I_CLK)とバッファアクセ
                      --! ス側のクロック(S_CLK)との関係を指定する.
                      integer :=  1;
        S_CLK_RATE  : --! @brief BUFFER ACCESS CLOCK RATE :
                      --! I_CLK_RATEとペアで入力側のクロック(I_CLK)とバッファアクセ
                      --! ス側のクロック(S_CLK)との関係を指定する.
                      integer :=  1
    );
    port (
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
        RST         : --! @brief ASYNCRONOUSE RESET :
                      --! 非同期リセット信号.アクティブハイ.
                      in  std_logic;
    -------------------------------------------------------------------------------
    -- 入力側の信号
    -------------------------------------------------------------------------------
        I_CLK       : --! @brief INTAKE CLOCK :
                      --! 入力側のクロック信号.
                      in  std_logic;
        I_CKE       : --! @brief INTAKE CLOCK ENABLE :
                      --! 入力側のクロック(I_CLK)の立上りが有効であることを示す信号.
                      in  std_logic;
        I_DATA      : --! @brief INTAKE DATA :
                      --! 入力側データ
                      in  std_logic_vector(8*I_BYTES-1 downto 0);
        I_STRB      : --! @brief INTAKE STROBE :
                      --! 入力側データ
                      in  std_logic_vector(  I_BYTES-1 downto 0) := (others => '1');
        I_LAST      : --! @brief INTAKE LAST :
                      --! 入力側データ
                      in  std_logic;
        I_VALID     : --! @brief INTAKE ENABLE :
                      --! 入力有効信号.
                      in  std_logic;
        I_READY     : --! @brief INTAKE READY :
                      --! 入力許可信号.
                      out std_logic;
    -------------------------------------------------------------------------------
    -- バッファリード I/F
    -------------------------------------------------------------------------------
        S_CLK       : --! @brief BUFFER READ CLOCK :
                      --! バッファ側のクロック信号.
                      in  std_logic;
        S_CKE       : --! @brief BUFFER READ CLOCK ENABLE :
                      --! バッファ側のクロック(S_CLK)の立上りが有効であることを示す信号.
                      in  std_logic;
        BUF_RDATA   : --! @brief BUFFER READ DATA :
                      --! バッファから読み出したデータ.
                      --! BUF_RADDR で指定されたアドレスの１クロック後に対応するデー
                      --! タを出力する.
                      out std_logic_vector(2**(BUF_WIDTH+3)-1 downto 0);
        BUF_RADDR   : --! @brief BUFFER READ ADDRESS :
                      --! バッファから読み出すアドレス.
                      in  std_logic_vector(BUF_DEPTH-1 downto 0);
    -------------------------------------------------------------------------------
    -- バッファ制御
    -------------------------------------------------------------------------------
        BUF_COUNT   : --! @brief BUFFER COUNT :
                      --! バッファに格納されているデータのバイト数を出力する.
                      out std_logic_vector(BUF_DEPTH   downto 0);
        BUF_CADDR   : --! @brief BUFFER CURRENT ADDRESS :
                      --! データが格納されているバッファの先頭アドレスを出力する.
                      out std_logic_vector(BUF_DEPTH-1 downto 0);
        BUF_LAST    : --! @brief BUFFER LAST :
                      --! 入力側から I_LAST がアサートされたことを示す.
                      out std_logic;
        PULL_SIZE   : --! @brief BUFFER PULL SIZE :
                      --! バッファから読み出したデータのバイト数を入力する.
                      in  std_logic_vector(BUF_DEPTH   downto 0);
        PULL_LOAD   : --! @brief BUFFER PULL LOAD :
                      --! バッファから読み出したデータのバイト数(PULL_COUNT)を
                      --! 入力してBUF_COUNTおよびBUF_CADDRを更新する信号.
                      in  std_logic;
        RESET_DATA  : --! @brief RESET DATA :
                      --! リセットデータ入力信号.
                      in  std_logic;
        RESET_LOAD  : --! @brief RESET LOAD :
                      --! リセットデータロード信号.
                      in  std_logic
    );
end PTTY_RXD_BUF;
-----------------------------------------------------------------------------------
-- 
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
library PIPEWORK;
use     PIPEWORK.COMPONENTS.SDPRAM;
use     PIPEWORK.COMPONENTS.SYNCRONIZER;
use     PIPEWORK.COMPONENTS.SYNCRONIZER_INPUT_PENDING_REGISTER;
architecture RTL of PTTY_RXD_BUF is
    -------------------------------------------------------------------------------
    -- バッファ書き込み制御信号
    -------------------------------------------------------------------------------
    signal    buf_waddr         :  std_logic_vector(    BUF_DEPTH   -1 downto 0);
    signal    buf_wdata         :  std_logic_vector(2**(BUF_WIDTH+3)-1 downto 0);
    signal    buf_we            :  std_logic_vector(2**(BUF_WIDTH  )-1 downto 0);
    -------------------------------------------------------------------------------
    -- 入力側の各種信号
    -------------------------------------------------------------------------------
    signal    i_reset           :  std_logic;
    signal    i_reset_data      :  std_logic;
    signal    i_reset_load      :  std_logic;
    signal    i_pull_size       :  std_logic_vector(BUF_DEPTH   downto 0);
    signal    i_pull_valid      :  std_logic;
    signal    i_push_size       :  std_logic_vector(BUF_DEPTH   downto 0);
    signal    i_push_last       :  std_logic;
    signal    i_push_valid      :  std_logic;
    -------------------------------------------------------------------------------
    -- バッファ読み出し側の各種信号
    -------------------------------------------------------------------------------
    signal    s_push_size       :  std_logic_vector(BUF_DEPTH   downto 0);
    signal    s_push_last       :  std_logic;
    signal    s_push_valid      :  std_logic;
begin
    -------------------------------------------------------------------------------
    -- 入力側ブロック
    -------------------------------------------------------------------------------
    I_SIDE: block
        signal   buf_counter    :  unsigned(BUF_DEPTH downto 0);
        signal   buf_ready      :  boolean;
        signal   intake_ready   :  boolean;
    begin
        ---------------------------------------------------------------------------
        -- 入力側のデータ幅が１バイトの場合...
        ---------------------------------------------------------------------------
        I1: if (I_BYTES = 1) generate
            i_push_size  <= std_logic_vector(to_unsigned(1, i_push_size'length)) when I_STRB(0) = '1' else
                            std_logic_vector(to_unsigned(0, i_push_size'length));
            i_push_last  <= I_LAST;
            i_push_valid <= '1' when (I_VALID = '1' and buf_ready) else '0';
            I_READY      <= '1' when (intake_ready) else '0';
            -----------------------------------------------------------------------
            -- buf_wdata : バッファ書き込みデータ
            -----------------------------------------------------------------------
            process (I_DATA) begin
                for i in buf_we'range loop
                    buf_wdata(8*(i+1)-1 downto 8*i) <= I_DATA;
                end loop;
            end process;
            -----------------------------------------------------------------------
            -- buf_we    : バッファ書き込みイネーブル信号(バイト単位)
            -----------------------------------------------------------------------
            process (buf_waddr, i_push_valid, I_STRB) begin
                for i in buf_we'range loop
                    if (BUF_WIDTH > 0) then
                        if (i_push_valid = '1') and
                           (I_STRB(0)    = '1') and
                           (i = to_01(unsigned(buf_waddr(BUF_WIDTH-1 downto 0)))) then
                            buf_we(i) <= '1';
                        else
                            buf_we(i) <= '0';
                        end if;
                    else
                        if (i_push_valid = '1') and
                           (I_STRB(0)    = '1') then
                            buf_we(i) <= '1';
                        else
                            buf_we(i) <= '0';
                        end if;
                    end if;
                end loop;
            end process;
        end generate;
        ---------------------------------------------------------------------------
        -- buf_waddr    : バッファ書き込みアドレス
        -- buf_counter  : バッファに格納されているバイト数
        -- buf_ready    : バッファに空きがあることを示すフラグ
        -- intake_ready : 入力許可信号. buf_ready とリセット時の値が違うことに注意.
        ---------------------------------------------------------------------------
        process (I_CLK, RST)
            variable next_counter :  unsigned(BUF_DEPTH+1 downto 0);
            variable next_addr    :  unsigned(BUF_DEPTH+1 downto 0);
        begin
            if    (RST = '1') then
                    buf_waddr    <= (others => '0');
                    buf_counter  <= (others => '0');
                    buf_ready    <= FALSE;
                    intake_ready <= TRUE;
            elsif (I_CLK'event and I_CLK = '1') then
                if (i_reset = '1') then
                    buf_waddr    <= (others => '0');
                    buf_counter  <= (others => '0');
                    buf_ready    <= FALSE;
                    intake_ready <= TRUE;
                else
                    next_counter := "0" & buf_counter;
                    if (i_push_valid = '1') then
                        next_counter := next_counter + resize(unsigned(i_push_size),next_counter'length);
                    end if;
                    if (i_pull_valid = '1') then
                        next_counter := next_counter - resize(unsigned(i_pull_size),next_counter'length);
                    end if;
                    buf_counter <= next_counter(buf_counter'range);
                    if (next_counter <= 2**BUF_DEPTH - I_BYTES) then
                        buf_ready    <= TRUE;
                        intake_ready <= TRUE;
                    else
                        buf_ready    <= FALSE;
                        intake_ready <= FALSE;
                    end if;
                    if (i_push_valid = '1') then
                        next_addr := "00" & unsigned(buf_waddr);
                        next_addr := next_addr + resize(unsigned(i_push_size), next_addr'length);
                        buf_waddr <= std_logic_vector(next_addr(buf_waddr'range));
                    end if;
                end if;
            end if;
        end process;
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        process (I_CLK, RST) begin
            if    (RST = '1') then
                    i_reset <= '1';
            elsif (I_CLK'event and I_CLK = '1') then
                if (i_reset_load = '1') then
                    i_reset <= i_reset_data;
                end if;
            end if;
        end process;
    end block;
    -------------------------------------------------------------------------------
    -- 入力側からバッファ読み出し側への信号の伝搬
    -------------------------------------------------------------------------------
    I2S: block
        constant sync_i_pause   :  std_logic := '0';
        constant sync_i_clear   :  std_logic := '0';
        constant sync_o_clear   :  std_logic := '0';
        constant SYNC_DATA_LOW  :  integer := 0;
        constant SYNC_SIZE_LOW  :  integer := SYNC_DATA_LOW;
        constant SYNC_SIZE_HIGH :  integer := SYNC_DATA_LOW  + i_push_size'length-1;
        constant SYNC_LAST_POS  :  integer := SYNC_SIZE_HIGH + 1;
        constant SYNC_DATA_HIGH :  integer := SYNC_LAST_POS;
        constant SYNC_SIZE      :  std_logic_vector(SYNC_SIZE_HIGH downto SYNC_SIZE_LOW) := (others => '0');
        constant SYNC_DATA      :  std_logic_vector(SYNC_DATA_HIGH downto SYNC_DATA_LOW) := (others => '0');
        signal   sync_i_data    :  std_logic_vector(SYNC_DATA'range);
        signal   sync_i_valid   :  std_logic;
        signal   sync_i_ready   :  std_logic;
        signal   sync_o_data    :  std_logic_vector(SYNC_DATA'range);
        signal   sync_o_valid   :  std_logic;
    begin
        SIZE: SYNCRONIZER_INPUT_PENDING_REGISTER  -- 
            generic map(                          -- 
                DATA_BITS   => SYNC_SIZE'length , -- 
                OPERATION   => 2                  -- 
            )                                     -- 
            port map (                            -- 
                CLK         => I_CLK            , -- In  : 
                RST         => RST              , -- In  : 
                CLR         => i_reset          , -- In  :
                I_DATA      => i_push_size      , -- In  :
                I_VAL       => i_push_valid     , -- In  :
                I_PAUSE     => sync_i_pause     , -- In  :
                O_DATA      => sync_i_data(SYNC_SIZE'range),  -- Out :
                O_VAL       => sync_i_valid     , -- Out :
                O_RDY       => sync_i_ready       -- In  :
            );                                    -- 
        LAST: SYNCRONIZER_INPUT_PENDING_REGISTER  -- 
            generic map(                          -- 
                DATA_BITS   => 1                , -- 
                OPERATION   => 1                  -- 
            )                                     -- 
            port map (                            -- 
                CLK         => I_CLK            , -- In  : 
                RST         => RST              , -- In  : 
                CLR         => i_reset          , -- In  :
                I_DATA(0)   => i_push_last      , -- In  :
                I_VAL       => i_push_valid     , -- In  :
                I_PAUSE     => sync_i_pause     , -- In  :
                O_DATA(0)   => sync_i_data(SYNC_LAST_POS),  -- Out :
                O_VAL       => open             , -- Out :
                O_RDY       => sync_i_ready       -- In  :
            );                                    -- 
        SYNC: SYNCRONIZER                         -- 
            generic map(                          -- 
                DATA_BITS   => SYNC_DATA'length , -- 
                VAL_BITS    => 1                , -- 
                I_CLK_RATE  => I_CLK_RATE       , -- 
                O_CLK_RATE  => S_CLK_RATE       , -- 
                O_CLK_REGS  => 1                  -- 
            )                                     -- 
            port map (                            -- 
                RST         => RST              , -- In  :
                I_CLK       => I_CLK            , -- In  : 
                I_CLR       => sync_i_clear     , -- In  :
                I_CKE       => I_CKE            , -- In  :
                I_DATA      => sync_i_data      , -- In  :
                I_VAL(0)    => sync_i_valid     , -- In  :
                I_RDY       => sync_i_ready     , -- Out :
                O_CLK       => S_CLK            , -- In  :
                O_CLR       => sync_o_clear     , -- In  :
                O_CKE       => S_CKE            , -- In  :
                O_DATA      => sync_o_data      , -- Out :
                O_VAL(0)    => sync_o_valid       -- Out :
            );
        s_push_size  <= sync_o_data(SYNC_SIZE'range);
        s_push_last  <= sync_o_data(SYNC_LAST_POS);
        s_push_valid <= sync_o_valid;
    end block;
    -------------------------------------------------------------------------------
    -- バッファ読み出し側から入力側への信号の伝搬
    -------------------------------------------------------------------------------
    S2I: block
        constant sync_i_pause   :  std_logic := '0';
        constant sync_i_clear   :  std_logic := '0';
        constant sync_o_clear   :  std_logic := '0';
        constant SYNC_DATA_LOW  :  integer := 0;
        constant SYNC_SIZE_LOW  :  integer := SYNC_DATA_LOW;
        constant SYNC_SIZE_HIGH :  integer := SYNC_DATA_LOW  + i_push_size'length-1;
        constant SYNC_RESET_POS :  integer := SYNC_SIZE_HIGH + 1;
        constant SYNC_DATA_HIGH :  integer := SYNC_RESET_POS;
        constant SYNC_SIZE      :  std_logic_vector(SYNC_SIZE_HIGH downto SYNC_SIZE_LOW) := (others => '0');
        constant SYNC_DATA      :  std_logic_vector(SYNC_DATA_HIGH downto SYNC_DATA_LOW) := (others => '0');
        signal   sync_i_data    :  std_logic_vector(SYNC_DATA'range);
        signal   sync_i_valid   :  std_logic_vector(1 downto 0);
        signal   sync_i_ready   :  std_logic;
        signal   sync_o_data    :  std_logic_vector(SYNC_DATA'range);
        signal   sync_o_valid   :  std_logic_vector(1 downto 0);
    begin
        SIZE: SYNCRONIZER_INPUT_PENDING_REGISTER  -- 
            generic map(                          -- 
                DATA_BITS   => SYNC_SIZE'length , -- 
                OPERATION   => 2                  -- 
            )                                     -- 
            port map (                            -- 
                CLK         => S_CLK            , -- In  : 
                RST         => RST              , -- In  : 
                CLR         => sync_i_clear     , -- In  :
                I_DATA      => PULL_SIZE        , -- In  :
                I_VAL       => PULL_LOAD        , -- In  :
                I_PAUSE     => sync_i_pause     , -- In  :
                O_DATA      => sync_i_data(SYNC_SIZE'range),  -- Out :
                O_VAL       => sync_i_valid(0)  , -- Out :
                O_RDY       => sync_i_ready       -- In  :
            );                                    -- 
        RESET:SYNCRONIZER_INPUT_PENDING_REGISTER  -- 
            generic map(                          -- 
                DATA_BITS   => 1                , -- 
                OPERATION   => 1                  -- 
            )                                     -- 
            port map (                            -- 
                CLK         => S_CLK            , -- In  : 
                RST         => RST              , -- In  : 
                CLR         => sync_i_clear     , -- In  :
                I_DATA(0)   => RESET_DATA       , -- In  :
                I_VAL       => RESET_LOAD       , -- In  :
                I_PAUSE     => sync_i_pause     , -- In  :
                O_DATA(0)   => sync_i_data(SYNC_RESET_POS),  -- Out :
                O_VAL       => sync_i_valid(1)  , -- Out :
                O_RDY       => sync_i_ready       -- In  :
            );                                    -- 
        SYNC: SYNCRONIZER                         -- 
            generic map(                          -- 
                DATA_BITS   => SYNC_DATA'length , -- 
                VAL_BITS    => 2                , -- 
                I_CLK_RATE  => S_CLK_RATE       , -- 
                O_CLK_RATE  => I_CLK_RATE       , -- 
                O_CLK_REGS  => 0                  -- 
            )                                     -- 
            port map (                            -- 
                RST         => RST              , -- In  :
                I_CLK       => S_CLK            , -- In  : 
                I_CLR       => sync_i_clear     , -- In  :
                I_CKE       => S_CKE            , -- In  :
                I_DATA      => sync_i_data      , -- In  :
                I_VAL       => sync_i_valid     , -- In  :
                I_RDY       => sync_i_ready     , -- Out :
                O_CLK       => I_CLK            , -- In  :
                O_CLR       => sync_o_clear     , -- In  :
                O_CKE       => I_CKE            , -- In  :
                O_DATA      => sync_o_data      , -- Out :
                O_VAL       => sync_o_valid       -- Out :
            );
        i_pull_size  <= sync_o_data(SYNC_SIZE'range);
        i_pull_valid <= sync_o_valid(0);
        i_reset_data <= sync_o_data(SYNC_RESET_POS);
        i_reset_load <= sync_o_valid(1);
    end block;
    -------------------------------------------------------------------------------
    -- バッファ読み出し側
    -------------------------------------------------------------------------------
    S_SIDE: block
        signal   buf_counter    :  unsigned(BUF_DEPTH   downto 0);
        signal   buf_curr_addr  :  unsigned(BUF_DEPTH-1 downto 0);
    begin
        ---------------------------------------------------------------------------
        -- buf_counter   : バッファに格納されているバイト数
        -- buf_curr_addr : データが格納されているバッファの先頭アドレス
        ---------------------------------------------------------------------------
        process (S_CLK, RST)
            variable next_counter  : unsigned(BUF_DEPTH+1 downto 0);
            variable buf_next_addr : unsigned(BUF_DEPTH   downto 0);
        begin
            if    (RST = '1') then
                    buf_counter   <= (others => '0');
                    buf_curr_addr <= (others => '0');
                    BUF_LAST      <= '0';
            elsif (S_CLK'event and S_CLK = '1') then
                if (RESET_LOAD = '1' and RESET_DATA = '1') then
                    buf_counter   <= (others => '0');
                    buf_curr_addr <= (others => '0');
                    BUF_LAST      <= '0';
                else
                    next_counter := "0" & buf_counter;
                    if (s_push_valid = '1') then
                        next_counter := next_counter   + resize(unsigned(s_push_size), next_counter'length);
                    end if;
                    if (PULL_LOAD    = '1') then
                        next_counter := next_counter   - resize(unsigned(  PULL_SIZE), next_counter'length);
                    end if;
                    buf_counter   <= next_counter(buf_counter'range);
                    buf_next_addr := "0" & buf_curr_addr;
                    if (PULL_LOAD    = '1') then
                        buf_next_addr := buf_next_addr + resize(unsigned(  PULL_SIZE),buf_next_addr'length);
                    end if;
                    buf_curr_addr <= buf_next_addr(buf_curr_addr'range);
                    if    (s_push_valid = '1') then
                        BUF_LAST <= s_push_last;
                    elsif (PULL_LOAD    = '1') then
                        BUF_LAST <= '0';
                    end if;
                end if;
            end if;
        end process;
        BUF_COUNT <= std_logic_vector(buf_counter);
        BUF_CADDR <= std_logic_vector(buf_curr_addr);
    end block;
    -------------------------------------------------------------------------------
    -- バッファメモリ
    -------------------------------------------------------------------------------
    RAM: SDPRAM                                  -- 
        generic map(                             -- 
            DEPTH       => BUF_DEPTH+3         , --
            RWIDTH      => BUF_WIDTH+3         , --
            WWIDTH      => BUF_WIDTH+3         , --
            WEBIT       => BUF_WIDTH           , --
            ID          => 1                     -- 
        )                                        -- 
        port map (                               -- 
            WCLK        => I_CLK               , -- In  :
            WE          => buf_we              , -- In  :
            WADDR       => buf_waddr(BUF_DEPTH-1 downto BUF_WIDTH), -- In  :
            WDATA       => buf_wdata           , -- In  :
            RCLK        => S_CLK               , -- In  :
            RADDR       => BUF_RADDR(BUF_DEPTH-1 downto BUF_WIDTH), -- In  :
            RDATA       => BUF_RDATA             -- Out :
        );
end RTL;
-----------------------------------------------------------------------------------
--!     @file    ptty_txd_buf.vhd
--!     @brief   Transimit Data Buffer for PTTY_AXI4
--!     @version 0.1.0
--!     @date    2015/8/29
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
--! @brief 送信バッファ
-----------------------------------------------------------------------------------
entity  PTTY_TXD_BUF is
    generic (
        BUF_DEPTH   : --! @brief BUFFER DEPTH :
                      --! バッファの容量(バイト数)を２のべき乗値で指定する.
                      integer := 8;
        BUF_WIDTH   : --! @brief BUFFER DATA WIDTH :
                      --! バッファのデータ幅(バイト数)を２のべき乗値で指定する.
                      integer := 2;
        O_BYTES     : --! @brief OUTLET DATA WIDTH :
                      --! 出力側のデータ幅(バイト数)を指定する.
                      integer := 1;
        O_CLK_RATE  : --! @brief OUTLET CLOCK RATE :
                      --! S_CLK_RATEとペアで出力側のクロック(O_CLK)とバッファアクセ
                      --! ス側のクロック(S_CLK)との関係を指定する.
                      integer := 1;
        S_CLK_RATE  : --! @brief BUFFER ACCESS CLOCK RATE :
                      --! O_CLK_RATEとペアで出力側のクロック(O_CLK)とバッファアクセ
                      --! ス側のクロック(S_CLK)との関係を指定する.
                      integer := 1
    );
    port (
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
        RST         : --! @brief ASYNCRONOUSE RESET :
                      --! 非同期リセット信号.アクティブハイ.
                      in  std_logic;
    -------------------------------------------------------------------------------
    -- 出力側の信号
    -------------------------------------------------------------------------------
        O_CLK       : --! @brief OUTLET CLOCK :
                      --! 出力側のクロック信号.
                      in  std_logic;
        O_CKE       : --! @brief OUTLET CLOCK ENABLE :
                      --! 出力側のクロック(I_CLK)の立上りが有効であることを示す信号.
                      in  std_logic;
        O_DATA      : --! @brief OUTLET DATA :
                      --! 出力側データ
                      out std_logic_vector(8*O_BYTES-1 downto 0);
        O_STRB      : --! @brief OUTLET STROBE :
                      --! 出力側データ
                      out std_logic_vector(  O_BYTES-1 downto 0);
        O_LAST      : --! @brief OUTLET LAST :
                      --! 出力側データ
                      out std_logic;
        O_VALID     : --! @brief OUTLET ENABLE :
                      --! 出力有効信号.
                      out std_logic;
        O_READY     : --! @brief OUTLET READY :
                      --! 出力許可信号.
                      in  std_logic;
    -------------------------------------------------------------------------------
    -- バッファライト I/F
    -------------------------------------------------------------------------------
        S_CLK       : --! @brief BUFFER WRITE CLOCK :
                      --! バッファ側のクロック信号.
                      in  std_logic;
        S_CKE       : --! @brief BUFFER WRITE CLOCK ENABLE :
                      --! バッファ側のクロック(S_CLK)の立上りが有効であることを示す信号.
                      in  std_logic;
        BUF_WDATA   : --! @brief BUFFER WRITE DATA :
                      --! バッファに書き込むデータ.
                      in  std_logic_vector(2**(BUF_WIDTH+3)-1 downto 0);
        BUF_WE      : --! @brief BUFFER WRITE ENABLE :
                      --! バッファ書き込みバイトイネーブル信号.
                      in  std_logic_vector(2**(BUF_WIDTH  )-1 downto 0);
        BUF_WADDR   : --! @brief BUFFER WRITE ADDRESS :
                      --! バッファ書き込みアドレス.
                      in  std_logic_vector(BUF_DEPTH-1 downto 0);
    -------------------------------------------------------------------------------
    -- バッファ制御
    -------------------------------------------------------------------------------
        BUF_COUNT   : --! @brief BUFFER COUNT :
                      --! バッファに格納されているデータのバイト数を出力する.
                      out std_logic_vector(BUF_DEPTH   downto 0);
        BUF_CADDR   : --! @brief BUFFER CURRENT ADDRESS :
                      --! バッファの空いている先頭アドレスを出力する.
                      out std_logic_vector(BUF_DEPTH-1 downto 0);
        BUF_LAST    : --! @brief BUFFER LAST :
                      out std_logic;
        PUSH_SIZE   : --! @brief BUFFER PUSH SIZE :
                      --! バッファに書き込んだデータのバイト数を入力する.
                      in  std_logic_vector(BUF_DEPTH   downto 0);
        PUSH_LAST   : --! @brief BUFFER PUSH LAST :
                      in  std_logic;
        PUSH_LOAD   : --! @brief BUFFER PUSH LOAD :
                      --! バッファに書き込んだデータのバイト数(PUSH_COUNT)を
                      --! 入力してBUF_COUNTおよびBUF_CADDRを更新する信号.
                      in  std_logic;
        RESET_DATA  : --! @brief RESET DATA :
                      --! リセットデータ入力信号.
                      in  std_logic;
        RESET_LOAD  : --! @brief RESET LOAD :
                      --! リセットデータロード信号.
                      in  std_logic
    );
end PTTY_TXD_BUF;
-----------------------------------------------------------------------------------
-- 
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
library PIPEWORK;
use     PIPEWORK.COMPONENTS.SDPRAM;
use     PIPEWORK.COMPONENTS.REDUCER;
use     PIPEWORK.COMPONENTS.CHOPPER;
use     PIPEWORK.COMPONENTS.SYNCRONIZER;
use     PIPEWORK.COMPONENTS.SYNCRONIZER_INPUT_PENDING_REGISTER;
architecture RTL of PTTY_TXD_BUF is
    -------------------------------------------------------------------------------
    -- バッファ読み出し制御信号
    -------------------------------------------------------------------------------
    signal    buf_raddr         :  std_logic_vector(    BUF_DEPTH   -1 downto 0);
    signal    buf_rdata         :  std_logic_vector(2**(BUF_WIDTH+3)-1 downto 0);
    -------------------------------------------------------------------------------
    -- 出力側の各種信号
    -------------------------------------------------------------------------------
    signal    o_reset           :  std_logic;
    signal    o_reset_data      :  std_logic;
    signal    o_reset_load      :  std_logic;
    signal    o_push_size       :  std_logic_vector(BUF_DEPTH downto 0);
    signal    o_push_last       :  std_logic;
    signal    o_push_valid      :  std_logic;
    signal    o_pull_valid      :  std_logic;
    signal    o_pull_last       :  std_logic;
    signal    o_pull_size       :  std_logic_vector(BUF_DEPTH downto 0);
    -------------------------------------------------------------------------------
    -- バッファ書き込み側の各種信号
    -------------------------------------------------------------------------------
    signal    s_pull_size       :  std_logic_vector(BUF_DEPTH downto 0);
    signal    s_pull_last       :  std_logic;
    signal    s_pull_valid      :  std_logic;
begin
    -------------------------------------------------------------------------------
    -- 出力側(O_BYTES > 1)
    -------------------------------------------------------------------------------
    O_SIDE: block
        signal    out_valid     :  std_logic;
        signal    out_last      :  std_logic;
        signal    out_strb      :  std_logic_vector(O_BYTES-1 downto 0);
        signal    buf_valid     :  std_logic;
        signal    buf_ready     :  std_logic;
        signal    buf_last      :  std_logic;
        signal    buf_strb      :  std_logic_vector(2**BUF_WIDTH-1 downto 0);
    begin
        ---------------------------------------------------------------------------
        -- 出力 I/F
        ---------------------------------------------------------------------------
        O_STRB    <= out_strb;
        O_LAST    <= out_last;
        O_VALID   <= out_valid;
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        QUEUE: REDUCER                                --
            generic map (                             --
                WORD_BITS   => 8                    , --
                STRB_BITS   => 1                    , --
                I_WIDTH     => 2**BUF_WIDTH         , --
                O_WIDTH     => O_BYTES              , --
                QUEUE_SIZE  => 0                    , --
                VALID_MIN   => 0                    , --
                VALID_MAX   => 0                    , --
                O_SHIFT_MIN => O_BYTES              , --
                O_SHIFT_MAX => O_BYTES              , --
                I_JUSTIFIED => 0                    , --
                FLUSH_ENABLE=> 0                      --
            )                                         --
            port map (                                --
                CLK         => O_CLK                , -- In  :
                RST         => RST                  , -- In  :
                CLR         => o_reset              , -- In  :
                BUSY        => open                 , -- Out :
                VALID       => open                 , -- Out :
                I_DATA      => buf_rdata            , -- In  :
                I_STRB      => buf_strb             , -- In  :
                I_DONE      => buf_last             , -- In  :
                I_VAL       => buf_valid            , -- In  :
                I_RDY       => buf_ready            , -- Out :
                O_DATA      => O_DATA               , -- Out :
                O_STRB      => out_strb             , -- Out :
                O_DONE      => out_last             , -- Out :
                O_VAL       => out_valid            , -- Out :
                O_RDY       => O_READY                -- In  :
            );                                        -- 
        ---------------------------------------------------------------------------
        -- o_pull_valid : データの出力があったことを示す.
        -- o_pull_last  : 最後のデータの出力があったことを示すフラグ.
        -- o_pull_size  : データの出力バイト数(=バッファから読み出したバイト数)
        ---------------------------------------------------------------------------
        o_pull_valid <= '1' when (out_valid = '1' and O_READY = '1') else '0';
        o_pull_last  <= out_last;
        process (out_strb)
            variable o_size  : integer range 0 to O_BYTES;
            function count_bits(I: std_logic_vector) return integer is
                alias    vec : std_logic_vector(I'length-1 downto 0) is I;
                variable num : integer range 0 to vec'length;
            begin
                if (vec'length = 1) then
                    if vec(0) = '1' then
                        num := 1;
                    else
                        num := 0;
                    end if;
                else
                    num := count_bits(vec(vec'length/2-1 downto 0))
                         + count_bits(vec(vec'length  -1 downto vec'length/2));
                end if;
                return num;
            end function;
        begin
            if (O_BYTES > 1) then
                o_size := count_bits(out_strb);
            else
                o_size := 1;
            end if;
            o_pull_size <= std_logic_vector(to_unsigned(o_size, o_pull_size'length));
        end process;
        ---------------------------------------------------------------------------
        -- バッファ制御部
        ---------------------------------------------------------------------------
        CTRL: block
            signal    next_addr     :  std_logic_vector(BUF_DEPTH-1 downto 0);
            signal    curr_addr     :  std_logic_vector(BUF_DEPTH-1 downto 0);
            signal    next_count    :  std_logic_vector(BUF_DEPTH   downto 0);
            signal    curr_count    :  std_logic_vector(BUF_DEPTH   downto 0);
            signal    word_size     :  std_logic_vector(BUF_WIDTH   downto 0);
            signal    buf_empty     :  std_logic;
            signal    chop_last     :  std_logic;
            signal    push_last     :  std_logic;
        begin
            -----------------------------------------------------------------------
            -- next_count : 次のクロックでのバッファに格納されているバイト数
            -----------------------------------------------------------------------
            process (curr_count, buf_valid, buf_ready, word_size, o_push_valid, o_push_size, o_reset)
                variable temp_count : unsigned(BUF_DEPTH+1 downto 0);
            begin
                temp_count := to_01("0" & unsigned(curr_count));
                if (o_push_valid = '1') then
                    temp_count := temp_count + resize(to_01(unsigned(o_push_size)), temp_count'length);
                end if;
                if (buf_valid = '1' and buf_ready = '1') then
                    temp_count := temp_count - resize(to_01(unsigned(word_size  )), temp_count'length);
                end if;
                if (o_reset = '1') then
                    next_count <= (others => '0');
                else
                    next_count <= std_logic_vector(temp_count(next_count'range));
                end if;
            end process;
            -----------------------------------------------------------------------
            -- next_addr  : 次のクロックでのバッファから読み出すアドレス
            -----------------------------------------------------------------------
            process (curr_addr, buf_valid, buf_ready, word_size)
                variable temp_addr : unsigned(BUF_DEPTH-1 downto 0);
            begin
                temp_addr := to_01(unsigned(curr_addr));
                if (buf_valid = '1' and buf_ready = '1') then
                    temp_addr := temp_addr + to_01(unsigned(word_size));
                end if;
                next_addr <= std_logic_vector(temp_addr);
            end process;
            -----------------------------------------------------------------------
            -- curr_count : バッファに格納されているバイト数
            -- curr_addr  : バッファから読み出すアドレス
            -----------------------------------------------------------------------
            process (O_CLK, RST) begin
                if    (RST = '1') then
                        curr_addr  <= (others => '0');
                        curr_count <= (others => '0');
                elsif (O_CLK'event and O_CLK = '1') then
                    if (o_reset = '1') then
                        curr_addr  <= (others => '0');
                        curr_count <= (others => '0');
                    else
                        curr_addr  <= next_addr;
                        curr_count <= next_count;
                    end if;
                end if;
            end process;
            -----------------------------------------------------------------------
            -- word_size  : バッファから読み出すバイト数
            -- buf_strb   : バッファから QUEUE に転送する時のバイトネーブル信号
            -- buf_empty  : バッファが空であることを示すフラグ.
            -----------------------------------------------------------------------
            CHOP: CHOPPER                                 -- 
                generic map (                             -- 
                    BURST       => 1                    , --
                    MIN_PIECE   => BUF_WIDTH            , --
                    MAX_PIECE   => BUF_WIDTH            , --
                    MAX_SIZE    => BUF_DEPTH            , --
                    ADDR_BITS   => next_addr'length     , --
                    SIZE_BITS   => next_count'length    , --
                    COUNT_BITS  => next_count'length    , --
                    PSIZE_BITS  => word_size'length     , --
                    GEN_VALID   => 1                      -- 
                )                                         -- 
                port map (                                -- 
                    CLK         => O_CLK                , -- In  :
                    RST         => RST                  , -- In  :
                    CLR         => o_reset              , -- In  : 
                    ADDR        => next_addr            , -- In  :
                    SIZE        => next_count           , -- In  :
                    SEL         => "0"                  , -- In  :
                    LOAD        => '1'                  , -- In  :
                    CHOP        => '0'                  , -- In  :
                    COUNT       => open                 , -- Out :
                    NONE        => buf_empty            , -- Out :
                    LAST        => chop_last            , -- Out :
                    NEXT_NONE   => open                 , -- Out :
                    NEXT_LAST   => open                 , -- Out :
                    PSIZE       => word_size            , -- Out :
                    VALID       => buf_strb             , -- Out :
                    NEXT_VALID  => open                   -- Out :
                );                                        --
            -----------------------------------------------------------------------
            -- push_last :
            -----------------------------------------------------------------------
            process (O_CLK, RST) begin
                if    (RST = '1') then
                        push_last <= '0';
                elsif (O_CLK'event and O_CLK = '1') then
                    if (o_reset = '1') then
                        push_last <= '0';
                    elsif (o_push_valid = '1' and o_push_last = '1') then
                        push_last <= '1';
                    elsif (buf_valid = '1' and buf_ready = '1' and buf_last = '1') then
                        push_last <= '0';
                    end if;
                end if;
            end process;
            -----------------------------------------------------------------------
            -- buf_valid : バッファにデータがあることを示すフラグ.
            -- buf_last  : バッファの最後のデータであることを示すフラグ.
            -- buf_raddr : バッファ読み出しアドレス.
            -----------------------------------------------------------------------
            buf_valid <= '1' when (buf_empty = '0') else '0';
            buf_last  <= '1' when (push_last = '1' and chop_last = '1') else '0';
            buf_raddr <= next_addr;
            -----------------------------------------------------------------------
            -- o_reset   : 出力側をリセットする信号
            -----------------------------------------------------------------------
            process (O_CLK, RST) begin
                if    (RST = '1') then
                        o_reset <= '1';
                elsif (O_CLK'event and O_CLK = '1') then
                    if (o_reset_load = '1') then
                        o_reset <= o_reset_data;
                    end if;
                end if;
            end process;
        end block;
    end block;
    -------------------------------------------------------------------------------
    -- 出力側からバッファ書き込み側への信号の伝搬
    -------------------------------------------------------------------------------
    O2S: block
        constant sync_i_pause   :  std_logic := '0';
        constant sync_i_clear   :  std_logic := '0';
        constant sync_o_clear   :  std_logic := '0';
        constant SYNC_DATA_LOW  :  integer := 0;
        constant SYNC_SIZE_LOW  :  integer := SYNC_DATA_LOW;
        constant SYNC_SIZE_HIGH :  integer := SYNC_DATA_LOW  + o_pull_size'length-1;
        constant SYNC_LAST_POS  :  integer := SYNC_SIZE_HIGH + 1;
        constant SYNC_DATA_HIGH :  integer := SYNC_LAST_POS;
        constant SYNC_SIZE      :  std_logic_vector(SYNC_SIZE_HIGH downto SYNC_SIZE_LOW) := (others => '0');
        constant SYNC_DATA      :  std_logic_vector(SYNC_DATA_HIGH downto SYNC_DATA_LOW) := (others => '0');
        signal   sync_i_data    :  std_logic_vector(SYNC_DATA'range);
        signal   sync_i_valid   :  std_logic;
        signal   sync_i_ready   :  std_logic;
        signal   sync_o_data    :  std_logic_vector(SYNC_DATA'range);
        signal   sync_o_valid   :  std_logic;
    begin
        SIZE: SYNCRONIZER_INPUT_PENDING_REGISTER  -- 
            generic map(                          -- 
                DATA_BITS   => SYNC_SIZE'length , -- 
                OPERATION   => 2                  -- 
            )                                     -- 
            port map (                            -- 
                CLK         => O_CLK            , -- In  : 
                RST         => RST              , -- In  : 
                CLR         => o_reset          , -- In  :
                I_DATA      => o_pull_size      , -- In  :
                I_VAL       => o_pull_valid     , -- In  :
                I_PAUSE     => sync_i_pause     , -- In  :
                O_DATA      => sync_i_data(SYNC_SIZE'range),  -- Out :
                O_VAL       => sync_i_valid     , -- Out :
                O_RDY       => sync_i_ready       -- In  :
            );                                    -- 
        LAST: SYNCRONIZER_INPUT_PENDING_REGISTER  -- 
            generic map(                          -- 
                DATA_BITS   => 1                , -- 
                OPERATION   => 1                  -- 
            )                                     -- 
            port map (                            -- 
                CLK         => O_CLK            , -- In  : 
                RST         => RST              , -- In  : 
                CLR         => o_reset          , -- In  :
                I_DATA(0)   => o_pull_last      , -- In  :
                I_VAL       => o_pull_valid     , -- In  :
                I_PAUSE     => sync_i_pause     , -- In  :
                O_DATA(0)   => sync_i_data(SYNC_LAST_POS),  -- Out :
                O_VAL       => open             , -- Out :
                O_RDY       => sync_i_ready       -- In  :
            );                                    -- 
        SYNC: SYNCRONIZER                         -- 
            generic map(                          -- 
                DATA_BITS   => SYNC_DATA'length , -- 
                VAL_BITS    => 1                , -- 
                I_CLK_RATE  => O_CLK_RATE       , -- 
                O_CLK_RATE  => S_CLK_RATE       , -- 
                O_CLK_REGS  => 0                  -- 
            )                                     -- 
            port map (                            -- 
                RST         => RST              , -- In  :
                I_CLK       => O_CLK            , -- In  : 
                I_CLR       => sync_i_clear     , -- In  :
                I_CKE       => O_CKE            , -- In  :
                I_DATA      => sync_i_data      , -- In  :
                I_VAL(0)    => sync_i_valid     , -- In  :
                I_RDY       => sync_i_ready     , -- Out :
                O_CLK       => S_CLK            , -- In  :
                O_CLR       => sync_o_clear     , -- In  :
                O_CKE       => S_CKE            , -- In  :
                O_DATA      => sync_o_data      , -- Out :
                O_VAL(0)    => sync_o_valid       -- Out :
            );
        s_pull_size  <= sync_o_data(SYNC_SIZE'range);
        s_pull_last  <= sync_o_data(SYNC_LAST_POS);
        s_pull_valid <= sync_o_valid;
    end block;
    -------------------------------------------------------------------------------
    -- バッファ書き込み側から出力側への信号の伝搬
    -------------------------------------------------------------------------------
    S2O: block
        constant sync_i_pause   :  std_logic := '0';
        constant sync_i_clear   :  std_logic := '0';
        constant sync_o_clear   :  std_logic := '0';
        constant SYNC_DATA_LOW  :  integer := 0;
        constant SYNC_SIZE_LOW  :  integer := SYNC_DATA_LOW;
        constant SYNC_SIZE_HIGH :  integer := SYNC_DATA_LOW  + PUSH_SIZE'length-1;
        constant SYNC_LAST_POS  :  integer := SYNC_SIZE_HIGH + 1;
        constant SYNC_RESET_POS :  integer := SYNC_LAST_POS  + 1;
        constant SYNC_DATA_HIGH :  integer := SYNC_RESET_POS;
        constant SYNC_SIZE      :  std_logic_vector(SYNC_SIZE_HIGH downto SYNC_SIZE_LOW) := (others => '0');
        constant SYNC_DATA      :  std_logic_vector(SYNC_DATA_HIGH downto SYNC_DATA_LOW) := (others => '0');
        signal   sync_i_data    :  std_logic_vector(SYNC_DATA'range);
        signal   sync_i_valid   :  std_logic_vector(1 downto 0);
        signal   sync_i_ready   :  std_logic;
        signal   sync_o_data    :  std_logic_vector(SYNC_DATA'range);
        signal   sync_o_valid   :  std_logic_vector(1 downto 0);
    begin
        SIZE: SYNCRONIZER_INPUT_PENDING_REGISTER  -- 
            generic map(                          -- 
                DATA_BITS   => SYNC_SIZE'length , -- 
                OPERATION   => 2                  -- 
            )                                     -- 
            port map (                            -- 
                CLK         => S_CLK            , -- In  : 
                RST         => RST              , -- In  : 
                CLR         => sync_i_clear     , -- In  :
                I_DATA      => PUSH_SIZE        , -- In  :
                I_VAL       => PUSH_LOAD        , -- In  :
                I_PAUSE     => sync_i_pause     , -- In  :
                O_DATA      => sync_i_data(SYNC_SIZE'range),  -- Out :
                O_VAL       => sync_i_valid(0)  , -- Out :
                O_RDY       => sync_i_ready       -- In  :
            );                                    -- 
        LAST: SYNCRONIZER_INPUT_PENDING_REGISTER  -- 
            generic map(                          -- 
                DATA_BITS   => 1                , -- 
                OPERATION   => 1                  -- 
            )                                     -- 
            port map (                            -- 
                CLK         => S_CLK            , -- In  : 
                RST         => RST              , -- In  : 
                CLR         => sync_i_clear     , -- In  :
                I_DATA(0)   => PUSH_LAST        , -- In  :
                I_VAL       => PUSH_LOAD        , -- In  :
                I_PAUSE     => sync_i_pause     , -- In  :
                O_DATA(0)   => sync_i_data(SYNC_LAST_POS),  -- Out :
                O_VAL       => open             , -- Out :
                O_RDY       => sync_i_ready       -- In  :
            );                                    -- 
        RESET:SYNCRONIZER_INPUT_PENDING_REGISTER  -- 
            generic map(                          -- 
                DATA_BITS   => 1                , -- 
                OPERATION   => 1                  -- 
            )                                     -- 
            port map (                            -- 
                CLK         => S_CLK            , -- In  : 
                RST         => RST              , -- In  : 
                CLR         => sync_i_clear     , -- In  :
                I_DATA(0)   => RESET_DATA       , -- In  :
                I_VAL       => RESET_LOAD       , -- In  :
                I_PAUSE     => sync_i_pause     , -- In  :
                O_DATA(0)   => sync_i_data(SYNC_RESET_POS),  -- Out :
                O_VAL       => sync_i_valid(1)  , -- Out :
                O_RDY       => sync_i_ready       -- In  :
            );                                    -- 
        SYNC: SYNCRONIZER                         -- 
            generic map(                          -- 
                DATA_BITS   => SYNC_DATA'length , -- 
                VAL_BITS    => 2                , -- 
                I_CLK_RATE  => S_CLK_RATE       , -- 
                O_CLK_RATE  => O_CLK_RATE       , --
                O_CLK_REGS  => 1                  -- 
            )                                     -- 
            port map (                            -- 
                RST         => RST              , -- In  :
                I_CLK       => S_CLK            , -- In  : 
                I_CLR       => sync_i_clear     , -- In  :
                I_CKE       => S_CKE            , -- In  :
                I_DATA      => sync_i_data      , -- In  :
                I_VAL       => sync_i_valid     , -- In  :
                I_RDY       => sync_i_ready     , -- Out :
                O_CLK       => O_CLK            , -- In  :
                O_CLR       => sync_o_clear     , -- In  :
                O_CKE       => O_CKE            , -- In  :
                O_DATA      => sync_o_data      , -- Out :
                O_VAL       => sync_o_valid       -- Out :
            );
        o_push_size  <= sync_o_data(SYNC_SIZE'range);
        o_push_last  <= sync_o_data(SYNC_LAST_POS);
        o_push_valid <= sync_o_valid(0);
        o_reset_data <= sync_o_data(SYNC_RESET_POS);
        o_reset_load <= sync_o_valid(1);
    end block;
    -------------------------------------------------------------------------------
    -- バッファ書き込み側
    -------------------------------------------------------------------------------
    S_SIDE: block
        signal   curr_count :  unsigned(BUF_DEPTH   downto 0);
        signal   curr_addr  :  unsigned(BUF_DEPTH-1 downto 0);
    begin
        ---------------------------------------------------------------------------
        -- curr_count   : バッファに格納されているバイト数
        -- curr_addr : データが格納されているバッファの先頭アドレス
        ---------------------------------------------------------------------------
        process (S_CLK, RST)
            variable next_count : unsigned(BUF_DEPTH+1 downto 0);
            variable next_addr  : unsigned(BUF_DEPTH   downto 0);
        begin
            if    (RST = '1') then
                    curr_count   <= (others => '0');
                    curr_addr <= (others => '0');
            elsif (S_CLK'event and S_CLK = '1') then
                if (RESET_LOAD = '1' and RESET_DATA = '1') then
                    curr_count   <= (others => '0');
                    curr_addr <= (others => '0');
                else
                    next_count := "0" & curr_count;
                    if (PUSH_LOAD    = '1') then
                        next_count := next_count + resize(unsigned(  PUSH_SIZE),next_count'length);
                    end if;
                    if (s_pull_valid = '1') then
                        next_count := next_count - resize(unsigned(s_pull_size),next_count'length);
                    end if;
                    curr_count <= next_count(curr_count'range);
                    if (PUSH_LOAD    = '1') then
                        next_addr := "0" & curr_addr;
                        next_addr := next_addr   + resize(unsigned(  PUSH_SIZE), next_addr'length);
                        curr_addr <= next_addr(curr_addr'range);
                    end if;
                end if;
            end if;
        end process;
        BUF_COUNT <= std_logic_vector(curr_count);
        BUF_CADDR <= std_logic_vector(curr_addr );
    end block;
    -------------------------------------------------------------------------------
    -- バッファメモリ
    -------------------------------------------------------------------------------
    RAM: SDPRAM                                  -- 
        generic map(                             -- 
            DEPTH       => BUF_DEPTH+3         , --
            RWIDTH      => BUF_WIDTH+3         , --
            WWIDTH      => BUF_WIDTH+3         , --
            WEBIT       => BUF_WIDTH           , --
            ID          => 0                     -- 
        )                                        -- 
        port map (                               -- 
            WCLK        => S_CLK               , -- In  :
            WE          => BUF_WE              , -- In  :
            WADDR       => BUF_WADDR(BUF_DEPTH-1 downto BUF_WIDTH), -- In  :
            WDATA       => BUF_WDATA           , -- In  :
            RCLK        => O_CLK               , -- In  :
            RADDR       => buf_raddr(BUF_DEPTH-1 downto BUF_WIDTH), -- In  :
            RDATA       => buf_rdata             -- Out :
        );
end RTL;
-----------------------------------------------------------------------------------
--!     @file    ptty_rx
--!     @brief   PTTY Receive Data Core
--!     @version 0.1.0
--!     @date    2015/8/29
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
entity  PTTY_RX is
    generic (
        RXD_BUF_DEPTH   : --! @brief RECEIVE DATA BUFFER DEPTH :
                          --! バッファの容量(バイト数)を２のべき乗値で指定する.
                          integer range 4 to   15 :=  7;
        RXD_BUF_BASE    : --! @brief RECEIVE DATA BUFFER BASE ADDRESS :
                          --! バッファのベースアドレスを指定する.
                          integer := 16#0000#;
        CSR_ADDR_WIDTH  : --! @brief REGISTER INTERFACE ADDRESS WIDTH :
                          --! レジスタアクセスのアドレスのビット幅を指定する.
                          integer range 1 to   64 := 32;
        CSR_DATA_WIDTH  : --! @brief REGISTER INTERFACE DATA WIDTH :
                          --! レジスタアクセスのデータのビット幅を指定する.
                          integer range 8 to 1024 := 32;
        RXD_BYTES       : --! @brief RECEIVE DATA DATA WIDTH :
                          --! 入力側のデータ幅(バイト数)を指定する.
                          integer := 1;
        RXD_CLK_RATE    : --! @brief RECEIVE DATA CLOCK RATE :
                          --! CSR_CLK_RATEとペアで入力側のクロック(RXD_CLK)とレジス
                          --! タアクセス側のクロック(C_CLK)との関係を指定する.
                          integer := 1;
        CSR_CLK_RATE      : --! @brief REGISTER INTERFACE CLOCK RATE :
                          --! RXD_CLK_RATEとペアで入力側のクロック(RXD_CLK)とレジス
                          --! タアクセス側のクロック(C_CLK)との関係を指定する.
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
        CSR_CLK         : --! @breif REGISTER INTERFACE CLOCK :
                          in  std_logic;
        CSR_CKE         : --! @breif REGISTER INTERFACE CLOCK ENABLE:
                          in  std_logic;
        CSR_ADDR        : --! @breif REGISTER ADDRESS :
                          in  std_logic_vector(CSR_ADDR_WIDTH  -1 downto 0);
        CSR_BEN         : --! @breif REGISTER BYTE ENABLE :
                          in  std_logic_vector(CSR_DATA_WIDTH/8-1 downto 0);
        CSR_WDATA       : --! @breif REGISTER WRITE DATA :
                          in  std_logic_vector(CSR_DATA_WIDTH  -1 downto 0);
        CSR_RDATA       : --! @breif REGISTER READ DATA :
                          out std_logic_vector(CSR_DATA_WIDTH  -1 downto 0);
        CSR_REG_REQ     : --! @breif REGISTER ACCESS REQUEST :
                          in  std_logic;
        CSR_BUF_REQ     : --! @breif REGISTER ACCESS REQUEST :
                          in  std_logic;
        CSR_WRITE       : --! @breif REGISTER ACCESS WRITE  :
                          in  std_logic;
        CSR_ACK         : --! @breif REGISTER ACCESS ACKNOWLEDGE :
                          out std_logic;
        CSR_ERR         : --! @breif REGISTER ACCESS ERROR ACKNOWLEDGE :
                          out std_logic;
        CSR_IRQ         : --! @breif INTERRUPT
                          out std_logic;
    -------------------------------------------------------------------------------
    -- 入力側の信号
    -------------------------------------------------------------------------------
        RXD_CLK         : --! @brief RECEIVE DATA CLOCK :
                          --! 入力側のクロック信号.
                          in  std_logic;
        RXD_CKE         : --! @brief RECEIVE DATA CLOCK ENABLE :
                          --! 入力側のクロック(RXD_CLK)の立上りが有効であることを示す信号.
                          in  std_logic;
        RXD_DATA        : --! @brief RECEIVE DATA DATA :
                          --! 入力側データ
                          in  std_logic_vector(8*RXD_BYTES-1 downto 0);
        RXD_STRB        : --! @brief RECEIVE DATA STROBE :
                          --! 入力側データ
                          in  std_logic_vector(  RXD_BYTES-1 downto 0);
        RXD_LAST        : --! @brief RECEIVE DATA LAST :
                          --! 入力側データ
                          in  std_logic;
        RXD_VALID       : --! @brief RECEIVE DATA ENABLE :
                          --! 入力有効信号.
                          in  std_logic;
        RXD_READY       : --! @brief RECEIVE DATA READY :
                          --! 入力許可信号.
                          out std_logic
    );
end PTTY_RX;
-----------------------------------------------------------------------------------
-- アーキテクチャ本体
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
library PIPEWORK;
use     PIPEWORK.COMPONENTS.REGISTER_ACCESS_ADAPTER;
architecture RTL of PTTY_RX is
    -------------------------------------------------------------------------------
    -- RXD_BUF_WIDTH : 受信バッファのデータ幅のバイト数を２のべき乗で示した値.
    -------------------------------------------------------------------------------
    function   CALC_RXD_BUF_WIDTH return integer is
        variable width : integer;
    begin
        width := 0;
        while (2**(width+3) < CSR_DATA_WIDTH) loop
            width := width + 1;
        end loop;
        return width;
    end function;
    constant   RXD_BUF_WIDTH         :  integer := CALC_RXD_BUF_WIDTH;
    -------------------------------------------------------------------------------
    -- レジスタアクセスインターフェースのアドレスのビット数.
    -------------------------------------------------------------------------------
    constant   REGS_ADDR_WIDTH    :  integer := 4;
    -------------------------------------------------------------------------------
    -- 全レジスタのビット数.
    -------------------------------------------------------------------------------
    constant   REGS_DATA_BITS     :  integer := (2**REGS_ADDR_WIDTH)*8;
    -------------------------------------------------------------------------------
    -- レジスタアクセス用の信号群.
    -------------------------------------------------------------------------------
    signal     regs_addr          :  std_logic_vector(REGS_ADDR_WIDTH  -1 downto 0);
    signal     regs_rdata         :  std_logic_vector(CSR_DATA_WIDTH   -1 downto 0);
    signal     regs_ack           :  std_logic;
    signal     regs_err           :  std_logic;
    signal     regs_load          :  std_logic_vector(REGS_DATA_BITS   -1 downto 0);
    signal     regs_wbit          :  std_logic_vector(REGS_DATA_BITS   -1 downto 0);
    signal     regs_rbit          :  std_logic_vector(REGS_DATA_BITS   -1 downto 0);
    -------------------------------------------------------------------------------
    -- バッファアクセス用の信号群.
    -------------------------------------------------------------------------------
    signal     rbuf_addr          :  std_logic_vector(RXD_BUF_DEPTH    -1 downto 0);
    signal     rbuf_ack           :  std_logic;
    signal     rbuf_err           :  std_logic;
    signal     rbuf_rdata         :  std_logic_vector(CSR_DATA_WIDTH   -1 downto 0);
    -------------------------------------------------------------------------------
    -- レジスタのアドレスマップ.
    -------------------------------------------------------------------------------
    --           31            24              16               8               0
    --           +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    -- Addr=0x00 |                      Header[31:00]                            |
    --           +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    -- Addr=0x04 |                   Configuration[31:00]                        |
    --           +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    -- Addr=0x08 |          BufPtr[15:0]         |       BufCount[15:00]         |
    --           +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    -- Addr=0x0C | Control[7:0]  |  Status[7:0]  |       PullSize[15:00]         |
    --           +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    -------------------------------------------------------------------------------
    constant   REGS_BASE_ADDR     :  integer := 16#00#;
    -------------------------------------------------------------------------------
    -- Header[31:0]
    -------------------------------------------------------------------------------
    constant   REGS_HEADER_ADDR   :  integer := REGS_BASE_ADDR        + 16#00#;
    constant   REGS_HEADER_BITS   :  integer := 32;
    constant   REGS_HEADER_LO     :  integer := 8*REGS_HEADER_ADDR    + 0;
    constant   REGS_HEADER_HI     :  integer := REGS_HEADER_LO        + REGS_HEADER_BITS-1;
    constant   REGS_HEADER_VALUE  :  std_logic_vector(REGS_HEADER_BITS-1 downto 0) := (others => '0');
    -------------------------------------------------------------------------------
    -- Configuration[31:0]
    -------------------------------------------------------------------------------
    -- Configuration[15:00] = バッファの容量
    -- Configuration[31:16] = 予約
    -------------------------------------------------------------------------------
    constant   REGS_CONFIG_ADDR   :  integer := REGS_BASE_ADDR        + 16#04#;
    constant   REGS_BUF_SIZE_BITS :  integer := 16;
    constant   REGS_BUF_SIZE_LO   :  integer := 8*REGS_CONFIG_ADDR    +  0;
    constant   REGS_BUF_SIZE_HI   :  integer := REGS_BUF_SIZE_LO      + REGS_BUF_SIZE_BITS - 1;
    constant   REGS_CONFIG_RSV_LO :  integer := 8*REGS_CONFIG_ADDR    + 16;
    constant   REGS_CONFIG_RSV_HI :  integer := REGS_CONFIG_RSV_LO    + 15;
    constant   REGS_BUF_SIZE      :  std_logic_vector(REGS_BUF_SIZE_BITS-1 downto 0)
                                  := std_logic_vector(to_unsigned(2**RXD_BUF_DEPTH, REGS_BUF_SIZE_BITS));
    constant   REGS_CONFIG_RSV    :  std_logic_vector(REGS_CONFIG_RSV_HI downto REGS_CONFIG_RSV_LO)
                                  := (others => '0');
    -------------------------------------------------------------------------------
    -- BufCount[15:0]
    -------------------------------------------------------------------------------
    constant   REGS_BUF_COUNT_ADDR:  integer := REGS_BASE_ADDR        + 16#08#;
    constant   REGS_BUF_COUNT_BITS:  integer := 16;
    constant   REGS_BUF_COUNT_LO  :  integer := 8*REGS_BUF_COUNT_ADDR + 0;
    constant   REGS_BUF_COUNT_HI  :  integer := REGS_BUF_COUNT_LO     + REGS_BUF_COUNT_BITS-1;
    signal     rbuf_count         :  std_logic_vector(RXD_BUF_DEPTH downto 0);
    -------------------------------------------------------------------------------
    -- BufPtr[15:0]
    -------------------------------------------------------------------------------
    constant   REGS_BUF_PTR_ADDR  :  integer := REGS_BASE_ADDR        + 16#0A#;
    constant   REGS_BUF_PTR_BITS  :  integer := 16;
    constant   REGS_BUF_PTR_LO    :  integer := 8*REGS_BUF_PTR_ADDR   + 0;
    constant   REGS_BUF_PTR_HI    :  integer := REGS_BUF_PTR_LO       + REGS_BUF_PTR_BITS-1;
    signal     rbuf_offset        :  std_logic_vector(RXD_BUF_DEPTH  -1 downto 0);
    signal     rbuf_ptr           :  std_logic_vector(REGS_BUF_PTR_BITS downto 0);
    -------------------------------------------------------------------------------
    -- PullSize[15:0]
    -------------------------------------------------------------------------------
    constant   REGS_PULL_SIZE_ADDR:  integer := REGS_BASE_ADDR        + 16#0C#;
    constant   REGS_PULL_SIZE_BITS:  integer := 16;
    constant   REGS_PULL_SIZE_LO  :  integer := 8*REGS_PULL_SIZE_ADDR + 0;
    constant   REGS_PULL_SIZE_HI  :  integer := REGS_PULL_SIZE_LO     + REGS_PULL_SIZE_BITS-1;
    signal     rbuf_pull_size     :  std_logic_vector(RXD_BUF_DEPTH downto 0);
    -------------------------------------------------------------------------------
    -- Status[7:0]
    -------------------------------------------------------------------------------
    -- Status[7]   = I_LAST がアサートされたことを示すフラグ
    -- Status[6:1] = 予約
    -- Status[0]   = バッファにデータがある かつ Control[2]=1 の時このフラグがセットされる
    -------------------------------------------------------------------------------
    constant   REGS_STAT_ADDR     :  integer := REGS_BASE_ADDR        + 16#0E#;
    constant   REGS_STAT_LAST_POS :  integer := 8*REGS_STAT_ADDR      +  7;
    constant   REGS_STAT_RESV_HI  :  integer := 8*REGS_STAT_ADDR      +  6;
    constant   REGS_STAT_RESV_LO  :  integer := 8*REGS_STAT_ADDR      +  1;
    constant   REGS_STAT_READY_POS:  integer := 8*REGS_STAT_ADDR      +  0;
    signal     stat_ready_bit     :  std_logic;
    signal     rbuf_last          :  std_logic;
    -------------------------------------------------------------------------------
    -- Control[7:0]
    -------------------------------------------------------------------------------
    -- Control[7]  = 1:モジュールをリセットする. 0:リセットを解除する.
    -- Control[6]  = 1:転送を一時中断する.       0:転送を再開する.
    -- Control[5]  = 1:転送を中止する.           0:意味無し.
    -- Control[4]  = 1:転送を開始する.           0:意味無し.
    -- Control[3]  = 予約.
    -- Control[2]  = 1:バッファにデータがある時にStatus[0]がセットされる.
    -- Control[1]  = 予約.
    -- Control[0]  = 予約.
    -------------------------------------------------------------------------------
    constant   REGS_CTRL_ADDR     :  integer := REGS_BASE_ADDR        + 16#0F#;
    constant   REGS_CTRL_RESET_POS:  integer := 8*REGS_CTRL_ADDR      +  7;
    constant   REGS_CTRL_PAUSE_POS:  integer := 8*REGS_CTRL_ADDR      +  6;
    constant   REGS_CTRL_ABORT_POS:  integer := 8*REGS_CTRL_ADDR      +  5;
    constant   REGS_CTRL_PULL_POS :  integer := 8*REGS_CTRL_ADDR      +  4;
    constant   REGS_CTRL_RSV3_POS :  integer := 8*REGS_CTRL_ADDR      +  3;
    constant   REGS_CTRL_READY_POS:  integer := 8*REGS_CTRL_ADDR      +  2;
    constant   REGS_CTRL_RSV1_POS :  integer := 8*REGS_CTRL_ADDR      +  1;
    constant   REGS_CTRL_RSV0_POS :  integer := 8*REGS_CTRL_ADDR      +  0;
    signal     ctrl_reset_bit     :  std_logic;
    signal     ctrl_pause_bit     :  std_logic;
    signal     ctrl_abort_bit     :  std_logic;
    signal     ctrl_pull_bit      :  std_logic;
    signal     ctrl_ready_bit     :  std_logic;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    function   resize(I : std_logic_vector; BITS: integer) return std_logic_vector is
        alias    vec    : std_logic_vector(I'length-1 downto 0) is I;
        variable result : std_logic_vector(    BITS-1 downto 0);
    begin
        for i in result'range loop
            if vec'low <= i and i <= vec'high then
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
    component  PTTY_RXD_BUF 
        generic (
            BUF_DEPTH   : integer := 8;
            BUF_WIDTH   : integer := 2;
            I_BYTES     : integer range 1 to 1 := 1;
            I_CLK_RATE  : integer := 1;
            S_CLK_RATE  : integer := 1
        );
        port (
            RST         : in  std_logic;
            I_CLK       : in  std_logic;
            I_CKE       : in  std_logic;
            I_DATA      : in  std_logic_vector(8*I_BYTES-1 downto 0);
            I_STRB      : in  std_logic_vector(  I_BYTES-1 downto 0);
            I_LAST      : in  std_logic;
            I_VALID     : in  std_logic;
            I_READY     : out std_logic;
            S_CLK       : in  std_logic;
            S_CKE       : in  std_logic;
            BUF_RDATA   : out std_logic_vector(2**(BUF_WIDTH+3)-1 downto 0);
            BUF_RADDR   : in  std_logic_vector(BUF_DEPTH-1 downto 0);
            BUF_COUNT   : out std_logic_vector(BUF_DEPTH   downto 0);
            BUF_CADDR   : out std_logic_vector(BUF_DEPTH-1 downto 0);
            BUF_LAST    : out std_logic;
            PULL_SIZE   : in  std_logic_vector(BUF_DEPTH   downto 0);
            PULL_LOAD   : in  std_logic;
            RESET_DATA  : in  std_logic;
            RESET_LOAD  : in  std_logic
        );
    end component;
begin
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    regs_addr <= CSR_ADDR(regs_addr'range);
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    rbuf_addr <= CSR_ADDR(rbuf_addr'range);
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    rbuf_err  <= '0';
    process (CSR_CLK, RST) begin
        if (RST = '1') then
                rbuf_ack <= '0';
        elsif (CSR_CLK'event and CSR_CLK = '1') then
            if (CLR = '1') then
                rbuf_ack <= '0';
            elsif (rbuf_ack = '0' and CSR_BUF_REQ = '1') then
                rbuf_ack <= '1';
            else
                rbuf_ack <= '0';
            end if;
        end if;
    end process;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    CSR_RDATA <= regs_rdata when (CSR_REG_REQ = '1') else
                 rbuf_rdata when (CSR_BUF_REQ = '1') else (others => '0');
    CSR_ACK   <= '1'        when (CSR_REG_REQ = '1' and regs_ack = '1') or
                                 (CSR_BUF_REQ = '1' and rbuf_ack = '1') else '0';
    CSR_ERR   <= '1'        when (CSR_REG_REQ = '1' and regs_err = '1') or
                                 (CSR_BUF_REQ = '1' and rbuf_err = '1') else '0';
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    DEC: REGISTER_ACCESS_ADAPTER                               -- 
        generic map (                                          -- 
            ADDR_WIDTH      => REGS_ADDR_WIDTH               , -- 
            DATA_WIDTH      => CSR_DATA_WIDTH                , -- 
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
            I_CLK           => CSR_CLK                       , -- In  :
            I_CLR           => CLR                           , -- In  :
            I_CKE           => '1'                           , -- In  :
            I_REQ           => CSR_REG_REQ                   , -- In  :
            I_SEL           => '1'                           , -- In  :
            I_WRITE         => CSR_WRITE                     , -- In  :
            I_ADDR          => regs_addr                     , -- In  :
            I_BEN           => CSR_BEN                       , -- In  :
            I_WDATA         => CSR_WDATA                     , -- In  :
            I_RDATA         => regs_rdata                    , -- Out :
            I_ACK           => regs_ack                      , -- Out :
            I_ERR           => regs_err                      , -- Out :
            O_CLK           => CSR_CLK                       , -- In  :
            O_CLR           => CLR                           , -- In  :
            O_CKE           => '1'                           , -- In  :
            O_WDATA         => regs_wbit                     , -- Out :
            O_WLOAD         => regs_load                     , -- Out :
            O_RDATA         => regs_rbit                       -- In  :
        );                                                     -- 
    -------------------------------------------------------------------------------
    -- Header[31:0]
    -------------------------------------------------------------------------------
    regs_rbit(REGS_HEADER_HI     downto REGS_HEADER_LO    ) <= REGS_HEADER_VALUE;
    -------------------------------------------------------------------------------
    -- Configuration[31:0]
    -------------------------------------------------------------------------------
    regs_rbit(REGS_BUF_SIZE_HI   downto REGS_BUF_SIZE_LO  ) <= REGS_BUF_SIZE;
    regs_rbit(REGS_CONFIG_RSV_HI downto REGS_CONFIG_RSV_LO) <= REGS_CONFIG_RSV;
    -------------------------------------------------------------------------------
    -- BufCount[15:0]
    -------------------------------------------------------------------------------
    regs_rbit(REGS_BUF_COUNT_HI  downto REGS_BUF_COUNT_LO ) <= resize(rbuf_count, REGS_BUF_COUNT_BITS);
    -------------------------------------------------------------------------------
    -- BufPtr[15:0]
    -------------------------------------------------------------------------------
    regs_rbit(REGS_BUF_PTR_HI    downto REGS_BUF_PTR_LO   ) <= resize(rbuf_ptr  , REGS_BUF_PTR_BITS);
    rbuf_ptr <= std_logic_vector(to_unsigned(RXD_BUF_BASE, rbuf_ptr'length) + to_01(unsigned(rbuf_offset)));
    -------------------------------------------------------------------------------
    -- PullSize[15:0]
    -------------------------------------------------------------------------------
    process (CSR_CLK, RST) begin
        if (RST = '1') then
                rbuf_pull_size <= (others => '0');
        elsif (CSR_CLK'event and CSR_CLK = '1') then
            if (CLR = '1' or ctrl_reset_bit = '1') then
                rbuf_pull_size <= (others => '0');
            else
                for i in rbuf_pull_size'range loop
                    if (regs_load(REGS_PULL_SIZE_LO+i) = '1') then
                        rbuf_pull_size(i) <= regs_wbit(REGS_PULL_SIZE_LO+i);
                    end if;
                end loop;
            end if;
        end if;
    end process;
    regs_rbit(REGS_PULL_SIZE_HI downto REGS_PULL_SIZE_LO) <= resize(rbuf_pull_size, REGS_PULL_SIZE_BITS);
    -------------------------------------------------------------------------------
    -- Status[7:0] (T.B.D)
    -------------------------------------------------------------------------------
    process (CSR_CLK, RST) begin
        if (RST = '1') then
                stat_ready_bit <= '0';
        elsif (CSR_CLK'event and CSR_CLK = '1') then
            if (CLR = '1' or ctrl_reset_bit = '1') then
                stat_ready_bit <= '0';
            elsif (regs_load(REGS_STAT_READY_POS) = '1' and regs_wbit(REGS_STAT_READY_POS) = '0') then
                stat_ready_bit <= '0';
            elsif (ctrl_ready_bit = '1' and ctrl_pull_bit = '0' and unsigned(rbuf_count) > 0) then
                stat_ready_bit <= '1';
            end if;
        end if;
    end process;
    CSR_IRQ <= '1' when (stat_ready_bit = '1') else '0';
    regs_rbit(REGS_STAT_READY_POS) <= stat_ready_bit;
    regs_rbit(REGS_STAT_LAST_POS ) <= rbuf_last;
    regs_rbit(REGS_STAT_RESV_HI downto REGS_STAT_RESV_LO) <= (REGS_STAT_RESV_HI downto REGS_STAT_RESV_LO => '0');
    -------------------------------------------------------------------------------
    -- Control[7] : ctrl_reset_bit
    -------------------------------------------------------------------------------
    process (CSR_CLK, RST) begin
        if     (RST = '1') then
                ctrl_reset_bit <= '0';
        elsif  (CSR_CLK'event and CSR_CLK = '1') then
            if (CLR = '1') then
                ctrl_reset_bit <= '0';
            elsif (regs_load(REGS_CTRL_RESET_POS) = '1') then
                ctrl_reset_bit <= regs_wbit(REGS_CTRL_RESET_POS);
            end if;
        end if;
    end process;
    regs_rbit(REGS_CTRL_RESET_POS) <= ctrl_reset_bit;
    -------------------------------------------------------------------------------
    -- Control[6:0]
    -------------------------------------------------------------------------------
    process (CSR_CLK, RST) begin
        if (RST = '1') then
                ctrl_pause_bit <= '0';
                ctrl_abort_bit <= '0';
                ctrl_pull_bit  <= '0';
                ctrl_ready_bit <= '0';
        elsif (CSR_CLK'event and CSR_CLK = '1') then
            if (CLR = '1' or ctrl_reset_bit = '1') then
                ctrl_pause_bit <= '0';
                ctrl_abort_bit <= '0';
                ctrl_pull_bit  <= '0';
                ctrl_ready_bit <= '0';
            else
                if (regs_load(REGS_CTRL_PAUSE_POS) = '1') then
                    ctrl_pause_bit <= regs_wbit(REGS_CTRL_PAUSE_POS);
                end if;
                if (regs_load(REGS_CTRL_ABORT_POS) = '1') then
                    ctrl_abort_bit <= regs_wbit(REGS_CTRL_ABORT_POS);
                else
                    ctrl_abort_bit <= '0';
                end if;
                if (regs_load(REGS_CTRL_PULL_POS ) = '1') then
                    ctrl_pull_bit  <= regs_wbit(REGS_CTRL_PULL_POS );
                else
                    ctrl_pull_bit  <= '0';
                end if;
                if (regs_load(REGS_CTRL_READY_POS ) = '1') then
                    ctrl_ready_bit  <= regs_wbit(REGS_CTRL_READY_POS );
                end if;
            end if;
        end if;
    end process;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    regs_rbit(REGS_CTRL_PAUSE_POS) <= ctrl_pause_bit;
    regs_rbit(REGS_CTRL_ABORT_POS) <= ctrl_abort_bit;
    regs_rbit(REGS_CTRL_PULL_POS ) <= ctrl_pull_bit;
    regs_rbit(REGS_CTRL_RSV3_POS ) <= '0';
    regs_rbit(REGS_CTRL_READY_POS) <= ctrl_ready_bit;
    regs_rbit(REGS_CTRL_RSV1_POS ) <= '0';
    regs_rbit(REGS_CTRL_RSV0_POS ) <= '0';
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    BUF: PTTY_RXD_BUF                                          -- 
        generic map (                                          -- 
            BUF_DEPTH       => RXD_BUF_DEPTH                 , --
            BUF_WIDTH       => RXD_BUF_WIDTH                 , --
            I_BYTES         => RXD_BYTES                     , --
            I_CLK_RATE      => RXD_CLK_RATE                  , --
            S_CLK_RATE      => CSR_CLK_RATE                    -- 
        )
        port map (                                             -- 
            RST             => RST                           , -- In  :
            I_CLK           => RXD_CLK                       , -- In  :
            I_CKE           => RXD_CKE                       , -- In  :
            I_DATA          => RXD_DATA                      , -- In  :
            I_STRB          => RXD_STRB                      , -- In  :
            I_LAST          => RXD_LAST                      , -- In  :
            I_VALID         => RXD_VALID                     , -- In  :
            I_READY         => RXD_READY                     , -- Out :
            S_CLK           => CSR_CLK                       , -- In  :
            S_CKE           => CSR_CKE                       , -- In  :
            BUF_RDATA       => rbuf_rdata                    , -- Out :
            BUF_RADDR       => rbuf_addr                     , -- In  :
            BUF_COUNT       => rbuf_count                    , -- Out :
            BUF_CADDR       => rbuf_offset                   , -- Out :
            BUF_LAST        => rbuf_last                     , -- Out :
            PULL_SIZE       => rbuf_pull_size                , -- In  :
            PULL_LOAD       => ctrl_pull_bit                 , -- In  :
            RESET_DATA      => regs_wbit(REGS_CTRL_RESET_POS), -- In  :
            RESET_LOAD      => regs_load(REGS_CTRL_RESET_POS)  -- In  :
        );
end RTL;

-----------------------------------------------------------------------------------
--!     @file    ptty_tx
--!     @brief   PTTY Transimit Data Core
--!     @version 0.1.0
--!     @date    2015/8/26
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
entity  PTTY_TX is
    generic (
        TXD_BUF_DEPTH   : --! @brief TRANSMIT DATA BUFFER DEPTH :
                          --! バッファの容量(バイト数)を２のべき乗値で指定する.
                          integer range 4 to   15 :=  7;
        TXD_BUF_BASE    : --! @brief TRANSMIT DATA BUFFER BASE ADDRESS :
                          --! バッファのベースアドレスを指定する.
                          integer := 16#0000#;
        CSR_ADDR_WIDTH  : --! @brief REGISTER INTERFACE ADDRESS WIDTH :
                          --! レジスタアクセスのアドレスのビット幅を指定する.
                          integer range 1 to   64 := 32;
        CSR_DATA_WIDTH  : --! @brief REGISTER INTERFACE DATA WIDTH :
                          --! レジスタアクセスのデータのビット幅を指定する.
                          integer range 8 to 1024 := 32;
        TXD_BYTES       : --! @brief TRANSMIT DATA WIDTH :
                          --! 出力側のデータ幅(バイト数)を指定する.
                          integer := 1;
        TXD_CLK_RATE    : --! @brief TRANSMIT DATA CLOCK RATE :
                          --! CSR_CLK_RATEとペアで出力側のクロック(TXD_CLK)とレジス
                          --! タアクセス側のクロック(CSR_CLK)との関係を指定する.
                          integer := 1;
        CSR_CLK_RATE    : --! @brief REGISTER INTERFACE CLOCK RATE :
                          --! TXD_CLK_RATEとペアで出力側のクロック(TXD_CLK)とレジス
                          --! タアクセス側のクロック(CSR_CLK)との関係を指定する.
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
        CSR_CLK         : --! @breif REGISTER INTERFACE CLOCK :
                          in  std_logic;
        CSR_CKE         : --! @breif REGISTER INTERFACE CLOCK ENABLE:
                          in  std_logic;
        CSR_ADDR        : --! @breif REGISTER ADDRESS :
                          in  std_logic_vector(CSR_ADDR_WIDTH  -1 downto 0);
        CSR_BEN         : --! @breif REGISTER BYTE ENABLE :
                          in  std_logic_vector(CSR_DATA_WIDTH/8-1 downto 0);
        CSR_WDATA       : --! @breif REGISTER WRITE DATA :
                          in  std_logic_vector(CSR_DATA_WIDTH  -1 downto 0);
        CSR_RDATA       : --! @breif REGISTER READ DATA :
                          out std_logic_vector(CSR_DATA_WIDTH  -1 downto 0);
        CSR_REG_REQ     : --! @breif REGISTER ACCESS REQUEST :
                          in  std_logic;
        CSR_BUF_REQ     : --! @breif REGISTER ACCESS REQUEST :
                          in  std_logic;
        CSR_WRITE       : --! @breif REGISTER ACCESS WRITE  :
                          in  std_logic;
        CSR_ACK         : --! @breif REGISTER ACCESS ACKNOWLEDGE :
                          out std_logic;
        CSR_ERR         : --! @breif REGISTER ACCESS ERROR ACKNOWLEDGE :
                          out std_logic;
        CSR_IRQ         : --! @breif INTERRUPT
                          out std_logic;
    -------------------------------------------------------------------------------
    -- 出力側の信号
    -------------------------------------------------------------------------------
        TXD_CLK         : --! @brief TRANSMIT CLOCK :
                          --! 出力側のクロック信号.
                          in  std_logic;
        TXD_CKE         : --! @brief TRANSMIT CLOCK ENABLE :
                          --! 出力側のクロック(I_CLK)の立上りが有効であることを示す信号.
                          in  std_logic;
        TXD_DATA        : --! @brief TRANSMIT DATA :
                          --! 出力側データ
                          out std_logic_vector(8*TXD_BYTES-1 downto 0);
        TXD_STRB        : --! @brief TRANSMIT STROBE :
                          --! 出力側データ
                          out std_logic_vector(  TXD_BYTES-1 downto 0);
        TXD_LAST        : --! @brief TRANSMIT LAST :
                          --! 出力側データ
                          out std_logic;
        TXD_VALID       : --! @brief TRANSMIT ENABLE :
                          --! 出力有効信号.
                          out std_logic;
        TXD_READY       : --! @brief TRANSMIT READY :
                          --! 出力許可信号.
                          in  std_logic
    );
end PTTY_TX;
-----------------------------------------------------------------------------------
-- アーキテクチャ本体
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
library PIPEWORK;
use     PIPEWORK.COMPONENTS.REGISTER_ACCESS_ADAPTER;
architecture RTL of PTTY_TX is
    -------------------------------------------------------------------------------
    -- TXD_BUF_WIDTH : 送信バッファのデータ幅のバイト数を２のべき乗で示した値.
    -------------------------------------------------------------------------------
    function   CALC_TXD_BUF_WIDTH return integer is
        variable width : integer;
    begin
        width := 0;
        while (2**(width+3) < CSR_DATA_WIDTH) loop
            width := width + 1;
        end loop;
        return width;
    end function;
    constant   TXD_BUF_WIDTH         :  integer := CALC_TXD_BUF_WIDTH;
    -------------------------------------------------------------------------------
    -- レジスタアクセスインターフェースのアドレスのビット数.
    -------------------------------------------------------------------------------
    constant   REGS_ADDR_WIDTH    :  integer := 4;
    -------------------------------------------------------------------------------
    -- 全レジスタのビット数.
    -------------------------------------------------------------------------------
    constant   REGS_DATA_BITS     :  integer := (2**REGS_ADDR_WIDTH)*8;
    -------------------------------------------------------------------------------
    -- レジスタアクセス用の信号群.
    -------------------------------------------------------------------------------
    signal     regs_addr          :  std_logic_vector(REGS_ADDR_WIDTH   -1 downto 0);
    signal     regs_rdata         :  std_logic_vector(CSR_DATA_WIDTH    -1 downto 0);
    signal     regs_ack           :  std_logic;
    signal     regs_err           :  std_logic;
    signal     regs_load          :  std_logic_vector(REGS_DATA_BITS    -1 downto 0);
    signal     regs_wbit          :  std_logic_vector(REGS_DATA_BITS    -1 downto 0);
    signal     regs_rbit          :  std_logic_vector(REGS_DATA_BITS    -1 downto 0);
    -------------------------------------------------------------------------------
    -- バッファアクセス用の信号群.
    -------------------------------------------------------------------------------
    signal     sbuf_we            :  std_logic_vector(2**(TXD_BUF_WIDTH)-1 downto 0);
    signal     sbuf_addr          :  std_logic_vector(TXD_BUF_DEPTH     -1 downto 0);
    constant   sbuf_ack           :  std_logic := '1';
    constant   sbuf_err           :  std_logic := '0';
    constant   sbuf_rdata         :  std_logic_vector(CSR_DATA_WIDTH    -1 downto 0) := (others => '0');
    -------------------------------------------------------------------------------
    -- レジスタのアドレスマップ.
    -------------------------------------------------------------------------------
    --           31            24              16               8               0
    --           +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    -- Addr=0x00 |                      Header[31:00]                            |
    --           +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    -- Addr=0x04 |                   Configuration[31:00]                        |
    --           +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    -- Addr=0x08 |          BufPtr[15:0]         |       BufCount[15:00]         |
    --           +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    -- Addr=0x0C | Control[7:0]  |  Status[7:0]  |       PushSize[15:00]         |
    --           +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    -------------------------------------------------------------------------------
    constant   REGS_BASE_ADDR     :  integer := 16#00#;
    -------------------------------------------------------------------------------
    -- Header[31:0]
    -------------------------------------------------------------------------------
    constant   REGS_HEADER_ADDR   :  integer := REGS_BASE_ADDR        + 16#00#;
    constant   REGS_HEADER_BITS   :  integer := 32;
    constant   REGS_HEADER_LO     :  integer := 8*REGS_HEADER_ADDR    + 0;
    constant   REGS_HEADER_HI     :  integer := REGS_HEADER_LO        + REGS_HEADER_BITS-1;
    constant   REGS_HEADER_VALUE  :  std_logic_vector(REGS_HEADER_BITS-1 downto 0) := (others => '0');
    -------------------------------------------------------------------------------
    -- Configuration[31:0]
    -------------------------------------------------------------------------------
    -- Configuration[15:00] = バッファの容量
    -- Configuration[31:16] = 予約
    -------------------------------------------------------------------------------
    constant   REGS_CONFIG_ADDR   :  integer := REGS_BASE_ADDR        + 16#04#;
    constant   REGS_BUF_SIZE_BITS :  integer := 16;
    constant   REGS_BUF_SIZE_LO   :  integer := 8*REGS_CONFIG_ADDR    +  0;
    constant   REGS_BUF_SIZE_HI   :  integer := REGS_BUF_SIZE_LO      + REGS_BUF_SIZE_BITS - 1;
    constant   REGS_CONFIG_RSV_LO :  integer := 8*REGS_CONFIG_ADDR    + 16;
    constant   REGS_CONFIG_RSV_HI :  integer := REGS_CONFIG_RSV_LO    + 15;
    constant   REGS_BUF_SIZE      :  std_logic_vector(REGS_BUF_SIZE_BITS-1 downto 0)
                                  := std_logic_vector(to_unsigned(2**TXD_BUF_DEPTH, REGS_BUF_SIZE_BITS));
    constant   REGS_CONFIG_RSV    :  std_logic_vector(REGS_CONFIG_RSV_HI downto REGS_CONFIG_RSV_LO)
                                  := (others => '0');
    -------------------------------------------------------------------------------
    -- BufCount[15:0]
    -------------------------------------------------------------------------------
    constant   REGS_BUF_COUNT_ADDR:  integer := REGS_BASE_ADDR        + 16#08#;
    constant   REGS_BUF_COUNT_BITS:  integer := 16;
    constant   REGS_BUF_COUNT_LO  :  integer := 8*REGS_BUF_COUNT_ADDR + 0;
    constant   REGS_BUF_COUNT_HI  :  integer := REGS_BUF_COUNT_LO     + REGS_BUF_COUNT_BITS-1;
    signal     sbuf_count         :  std_logic_vector(TXD_BUF_DEPTH downto 0);
    -------------------------------------------------------------------------------
    -- BufPtr[15:0]
    -------------------------------------------------------------------------------
    constant   REGS_BUF_PTR_ADDR  :  integer := REGS_BASE_ADDR        + 16#0A#;
    constant   REGS_BUF_PTR_BITS  :  integer := 16;
    constant   REGS_BUF_PTR_LO    :  integer := 8*REGS_BUF_PTR_ADDR   + 0;
    constant   REGS_BUF_PTR_HI    :  integer := REGS_BUF_PTR_LO       + REGS_BUF_PTR_BITS-1;
    signal     sbuf_offset        :  std_logic_vector(TXD_BUF_DEPTH  -1 downto 0);
    signal     sbuf_ptr           :  std_logic_vector(REGS_BUF_PTR_BITS downto 0);
    -------------------------------------------------------------------------------
    -- PushSize[15:0]
    -------------------------------------------------------------------------------
    constant   REGS_PUSH_SIZE_ADDR:  integer := REGS_BASE_ADDR        + 16#0C#;
    constant   REGS_PUSH_SIZE_BITS:  integer := 16;
    constant   REGS_PUSH_SIZE_LO  :  integer := 8*REGS_PUSH_SIZE_ADDR + 0;
    constant   REGS_PUSH_SIZE_HI  :  integer := REGS_PUSH_SIZE_LO     + REGS_PUSH_SIZE_BITS-1;
    signal     sbuf_push_size     :  std_logic_vector(TXD_BUF_DEPTH downto 0);
    -------------------------------------------------------------------------------
    -- Status[7:0]
    -------------------------------------------------------------------------------
    -- Status[7:1] = 予約
    -- Status[0]   = バッファが空 かつ Control[2]=1 の時このフラグがセットされる
    -------------------------------------------------------------------------------
    constant   REGS_STAT_ADDR     :  integer := REGS_BASE_ADDR        + 16#0E#;
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
    constant   REGS_CTRL_ADDR     :  integer := REGS_BASE_ADDR        + 16#0F#;
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
            if vec'low <= i and i <= vec'high then
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
    component  PTTY_TXD_BUF is
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
    regs_addr <= CSR_ADDR(regs_addr'range);
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    sbuf_addr <= CSR_ADDR(sbuf_addr'range);
    sbuf_we   <= CSR_BEN when (CSR_BUF_REQ = '1' and CSR_WRITE = '1') else (others => '0');
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    CSR_RDATA   <= regs_rdata when (CSR_REG_REQ = '1') else
                   sbuf_rdata when (CSR_BUF_REQ = '1') else (others => '0');
    CSR_ACK     <= '1'        when (CSR_REG_REQ = '1' and regs_ack = '1') or
                                   (CSR_BUF_REQ = '1' and sbuf_ack = '1') else '0';
    CSR_ERR     <= '1'        when (CSR_REG_REQ = '1' and regs_err = '1') or
                                   (CSR_BUF_REQ = '1' and sbuf_err = '1') else '0';
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    DEC: REGISTER_ACCESS_ADAPTER                               -- 
        generic map (                                          -- 
            ADDR_WIDTH      => REGS_ADDR_WIDTH               , -- 
            DATA_WIDTH      => CSR_DATA_WIDTH                , -- 
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
            I_CLK           => CSR_CLK                       , -- In  :
            I_CLR           => CLR                           , -- In  :
            I_CKE           => '1'                           , -- In  :
            I_REQ           => CSR_REG_REQ                   , -- In  :
            I_SEL           => '1'                           , -- In  :
            I_WRITE         => CSR_WRITE                     , -- In  :
            I_ADDR          => regs_addr                     , -- In  :
            I_BEN           => CSR_BEN                       , -- In  :
            I_WDATA         => CSR_WDATA                     , -- In  :
            I_RDATA         => regs_rdata                    , -- Out :
            I_ACK           => regs_ack                      , -- Out :
            I_ERR           => regs_err                      , -- Out :
            O_CLK           => CSR_CLK                       , -- In  :
            O_CLR           => CLR                           , -- In  :
            O_CKE           => '1'                           , -- In  :
            O_WDATA         => regs_wbit                     , -- Out :
            O_WLOAD         => regs_load                     , -- Out :
            O_RDATA         => regs_rbit                       -- In  :
        );                                                     -- 
    -------------------------------------------------------------------------------
    -- Header[31:0]
    -------------------------------------------------------------------------------
    regs_rbit(REGS_HEADER_HI     downto REGS_HEADER_LO    ) <= REGS_HEADER_VALUE;
    -------------------------------------------------------------------------------
    -- Configuration[31:0]
    -------------------------------------------------------------------------------
    regs_rbit(REGS_BUF_SIZE_HI   downto REGS_BUF_SIZE_LO  ) <= REGS_BUF_SIZE;
    regs_rbit(REGS_CONFIG_RSV_HI downto REGS_CONFIG_RSV_LO) <= REGS_CONFIG_RSV;
    -------------------------------------------------------------------------------
    -- BufCount[15:0]
    -------------------------------------------------------------------------------
    regs_rbit(REGS_BUF_COUNT_HI downto REGS_BUF_COUNT_LO) <= resize(sbuf_count, REGS_BUF_COUNT_BITS);
    -------------------------------------------------------------------------------
    -- BufPtr[15:0]
    -------------------------------------------------------------------------------
    regs_rbit(REGS_BUF_PTR_HI   downto REGS_BUF_PTR_LO  ) <= resize(sbuf_ptr  , REGS_BUF_PTR_BITS  );
    sbuf_ptr <= std_logic_vector(to_unsigned(TXD_BUF_BASE, sbuf_ptr'length) + to_01(unsigned(sbuf_offset)));
    -------------------------------------------------------------------------------
    -- PushSize[15:0]
    -------------------------------------------------------------------------------
    process (CSR_CLK, RST) begin
        if (RST = '1') then
                sbuf_push_size <= (others => '0');
        elsif (CSR_CLK'event and CSR_CLK = '1') then
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
    -- Control[2] : ctrl_done_bit
    -- Status[0]  : stat_done_bit
    -------------------------------------------------------------------------------
    DONE: block
        type      STATE_TYPE   is (IDLE_STATE, PUSH_STATE, WAIT_STATE, DONE_STATE);
        signal    curr_state   :  STATE_TYPE;
    begin
        process (CSR_CLK, RST)
            variable  set_ctrl_done :  boolean;
            variable  clr_ctrl_done :  boolean;
            variable  clr_stat_done :  boolean;
            variable  next_state    :  STATE_TYPE;
        begin
            if (RST = '1') then
                    curr_state    <= IDLE_STATE;
                    ctrl_done_bit <= '0';
                    stat_done_bit <= '0';
            elsif (CSR_CLK'event and CSR_CLK = '1') then
                if (CLR = '1' or ctrl_reset_bit = '1') then
                    curr_state    <= IDLE_STATE;
                    ctrl_done_bit <= '0';
                    stat_done_bit <= '0';
                else
                    set_ctrl_done := (regs_load(REGS_CTRL_DONE_POS) = '1' and regs_wbit(REGS_CTRL_DONE_POS) = '1');
                    clr_ctrl_done := (regs_load(REGS_CTRL_DONE_POS) = '1' and regs_wbit(REGS_CTRL_DONE_POS) = '0');
                    clr_stat_done := (regs_load(REGS_STAT_DONE_POS) = '1' and regs_wbit(REGS_STAT_DONE_POS) = '0');
                    case curr_state is
                        when IDLE_STATE =>
                            if (set_ctrl_done) then
                                next_state := PUSH_STATE;
                            else
                                next_state := IDLE_STATE;
                            end if;
                        when PUSH_STATE =>
                            if (clr_ctrl_done) then
                                next_state := IDLE_STATE;
                            else
                                next_state := WAIT_STATE;
                            end if;
                        when WAIT_STATE =>
                            if    (unsigned(sbuf_count) = 0) then
                                next_state := DONE_STATE;
                            elsif (clr_ctrl_done) then
                                next_state := IDLE_STATE;
                            else
                                next_state := WAIT_STATE;
                            end if;
                        when DONE_STATE =>
                            if (clr_stat_done) then
                                if (set_ctrl_done) then
                                    next_state := PUSH_STATE;
                                else
                                    next_state := IDLE_STATE;
                                end if;
                            else
                                next_state := DONE_STATE;
                            end if;
                        when others =>
                                next_state := IDLE_STATE;
                    end case;
                    curr_state <= next_state;
                    if (next_state = PUSH_STATE or next_state = WAIT_STATE) then
                        ctrl_done_bit <= '1';
                    else
                        ctrl_done_bit <= '0';
                    end if;
                    if (next_state = DONE_STATE) then
                        stat_done_bit <= '1';
                    else
                        stat_done_bit <= '0';
                    end if;
                end if;
            end if;
        end process;
    end block;
    CSR_IRQ <= '1' when (stat_done_bit = '1') else '0';
    regs_rbit(REGS_STAT_DONE_POS) <= stat_done_bit;
    regs_rbit(REGS_STAT_RESV_HI downto REGS_STAT_RESV_LO) <= (REGS_STAT_RESV_HI downto REGS_STAT_RESV_LO => '0');
    -------------------------------------------------------------------------------
    -- Control[7] : ctrl_reset_bit
    -------------------------------------------------------------------------------
    process (CSR_CLK, RST) begin
        if     (RST = '1') then
                ctrl_reset_bit <= '0';
        elsif  (CSR_CLK'event and CSR_CLK = '1') then
            if (CLR = '1') then
                ctrl_reset_bit <= '0';
            elsif (regs_load(REGS_CTRL_RESET_POS) = '1') then
                ctrl_reset_bit <= regs_wbit(REGS_CTRL_RESET_POS);
            end if;
        end if;
    end process;
    regs_rbit(REGS_CTRL_RESET_POS) <= ctrl_reset_bit;
    -------------------------------------------------------------------------------
    -- Control[6:0] : 
    -------------------------------------------------------------------------------
    process (CSR_CLK, RST) begin
        if (RST = '1') then
                ctrl_pause_bit <= '0';
                ctrl_abort_bit <= '0';
                ctrl_push_bit  <= '0';
                ctrl_last_bit  <= '0';
        elsif (CSR_CLK'event and CSR_CLK = '1') then
            if (CLR = '1' or ctrl_reset_bit = '1') then
                ctrl_pause_bit <= '0';
                ctrl_abort_bit <= '0';
                ctrl_push_bit  <= '0';
                ctrl_last_bit  <= '0';
            else
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
                if (regs_load(REGS_CTRL_LAST_POS ) = '1') then
                    ctrl_last_bit  <= regs_wbit(REGS_CTRL_LAST_POS );
                end if;
            end if;
        end if;
    end process;
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
    BUF: PTTY_TXD_BUF                                          -- 
        generic map (                                          -- 
            BUF_DEPTH       => TXD_BUF_DEPTH                 , --
            BUF_WIDTH       => TXD_BUF_WIDTH                 , --
            O_BYTES         => TXD_BYTES                     , --
            O_CLK_RATE      => TXD_CLK_RATE                  , --
            S_CLK_RATE      => CSR_CLK_RATE                    --
        )                                                      -- 
        port map (                                             -- 
            RST             => RST                           , -- In  :
            O_CLK           => TXD_CLK                       , -- In  :
            O_CKE           => TXD_CKE                       , -- In  :
            O_DATA          => TXD_DATA                      , -- Out :
            O_STRB          => TXD_STRB                      , -- Out :
            O_LAST          => TXD_LAST                      , -- Out :
            O_VALID         => TXD_VALID                     , -- Out :
            O_READY         => TXD_READY                     , -- In  :
            S_CLK           => CSR_CLK                       , -- In  :
            S_CKE           => CSR_CKE                       , -- In  :
            BUF_WDATA       => CSR_WDATA                     , -- In  :
            BUF_WE          => sbuf_we                       , -- In  :
            BUF_WADDR       => sbuf_addr                     , -- In  :
            BUF_COUNT       => sbuf_count                    , -- Out :
            BUF_CADDR       => sbuf_offset                   , -- Out :
            BUF_LAST        => open                          , -- Out :
            PUSH_SIZE       => sbuf_push_size                , -- In  :
            PUSH_LAST       => ctrl_last_bit                 , -- In  :
            PUSH_LOAD       => ctrl_push_bit                 , -- In  :
            RESET_DATA      => regs_wbit(REGS_CTRL_RESET_POS), -- In  :
            RESET_LOAD      => regs_load(REGS_CTRL_RESET_POS)  -- In  :
        );
end RTL;
-----------------------------------------------------------------------------------
--!     @file    ptty_axi4.vhd
--!     @brief   PTTY_AXI4
--!     @version 0.1.0
--!     @date    2015/8/29
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
        TXD_BUF_DEPTH   : integer range  4 to    9 :=  7;
        RXD_BUF_DEPTH   : integer range  4 to    9 :=  7;
        CSR_ADDR_WIDTH  : integer range 12 to   64 := 12;
        CSR_DATA_WIDTH  : integer range  8 to 1024 := 32;
        CSR_ID_WIDTH    : integer                  := 12;
        RXD_BYTES       : integer range  1 to    1 :=  1;
        TXD_BYTES       : integer range  1 to    1 :=  1
    );
    port (
    -------------------------------------------------------------------------------
    -- Reset Signals.
    -------------------------------------------------------------------------------
        ARESETn         : in    std_logic;
    -------------------------------------------------------------------------------
    -- Control Status Register I/F Clock.
    -------------------------------------------------------------------------------
        CSR_CLK         : in    std_logic;
    -------------------------------------------------------------------------------
    -- Control Status Register I/F AXI4 Read Address Channel Signals.
    -------------------------------------------------------------------------------
        CSR_ARID        : in    std_logic_vector(CSR_ID_WIDTH    -1 downto 0);
        CSR_ARADDR      : in    std_logic_vector(CSR_ADDR_WIDTH  -1 downto 0);
        CSR_ARLEN       : in    std_logic_vector(7 downto 0);
        CSR_ARSIZE      : in    std_logic_vector(2 downto 0);
        CSR_ARBURST     : in    std_logic_vector(1 downto 0);
        CSR_ARVALID     : in    std_logic;
        CSR_ARREADY     : out   std_logic;
    -------------------------------------------------------------------------------
    -- Control Status Register I/F AXI4 Read Data Channel Signals.
    -------------------------------------------------------------------------------
        CSR_RID         : out   std_logic_vector(CSR_ID_WIDTH    -1 downto 0);
        CSR_RDATA       : out   std_logic_vector(CSR_DATA_WIDTH  -1 downto 0);
        CSR_RRESP       : out   std_logic_vector(1 downto 0);
        CSR_RLAST       : out   std_logic;
        CSR_RVALID      : out   std_logic;
        CSR_RREADY      : in    std_logic;
    -------------------------------------------------------------------------------
    -- Control Status Register I/F AXI4 Write Address Channel Signals.
    -------------------------------------------------------------------------------
        CSR_AWID        : in    std_logic_vector(CSR_ID_WIDTH    -1 downto 0);
        CSR_AWADDR      : in    std_logic_vector(CSR_ADDR_WIDTH  -1 downto 0);
        CSR_AWLEN       : in    std_logic_vector(7 downto 0);
        CSR_AWSIZE      : in    std_logic_vector(2 downto 0);
        CSR_AWBURST     : in    std_logic_vector(1 downto 0);
        CSR_AWVALID     : in    std_logic;
        CSR_AWREADY     : out   std_logic;
    -------------------------------------------------------------------------------
    -- Control Status Register I/F AXI4 Write Data Channel Signals.
    -------------------------------------------------------------------------------
        CSR_WDATA       : in    std_logic_vector(CSR_DATA_WIDTH  -1 downto 0);
        CSR_WSTRB       : in    std_logic_vector(CSR_DATA_WIDTH/8-1 downto 0);
        CSR_WLAST       : in    std_logic;
        CSR_WVALID      : in    std_logic;
        CSR_WREADY      : out   std_logic;
    -------------------------------------------------------------------------------
    -- Control Status Register I/F AXI4 Write Response Channel Signals.
    -------------------------------------------------------------------------------
        CSR_BID         : out   std_logic_vector(CSR_ID_WIDTH    -1 downto 0);
        CSR_BRESP       : out   std_logic_vector(1 downto 0);
        CSR_BVALID      : out   std_logic;
        CSR_BREADY      : in    std_logic;
    -------------------------------------------------------------------------------
    -- Interrupt
    -------------------------------------------------------------------------------
        CSR_IRQ         : out   std_logic;
    -------------------------------------------------------------------------------
    -- 入力側の信号
    -------------------------------------------------------------------------------
        RXD_CLK         : --! @brief RECEIVE DATA CLOCK :
                          --! 入力側のクロック信号.
                          in  std_logic;
        RXD_TDATA       : --! @brief RECEIVE DATA DATA :
                          --! 入力側データ
                          in  std_logic_vector(8*RXD_BYTES-1 downto 0);
        RXD_TSTRB       : --! @brief RECEIVE DATA STROBE :
                          --! 入力側データ
                          in  std_logic_vector(  RXD_BYTES-1 downto 0);
        RXD_TLAST       : --! @brief RECEIVE DATA LAST :
                          --! 入力側データ
                          in  std_logic;
        RXD_TVALID      : --! @brief RECEIVE DATA ENABLE :
                          --! 入力有効信号.
                          in  std_logic;
        RXD_TREADY      : --! @brief RECEIVE DATA READY :
                          --! 入力許可信号.
                          out std_logic;
    -------------------------------------------------------------------------------
    -- 出力側の信号
    -------------------------------------------------------------------------------
        TXD_CLK         : --! @brief TRANSMIT DATA CLOCK :
                          --! 出力側のクロック信号.
                          in  std_logic;
        TXD_TDATA       : --! @brief TRANSMIT DATA DATA :
                          --! 出力側データ
                          out std_logic_vector(8*TXD_BYTES-1 downto 0);
        TXD_TSTRB       : --! @brief TRANSMIT DATA STROBE :
                          --! 出力側データ
                          out std_logic_vector(  TXD_BYTES-1 downto 0);
        TXD_TLAST       : --! @brief TRANSMIT DATA LAST :
                          --! 出力側データ
                          out std_logic;
        TXD_TVALID      : --! @brief TRANSMIT DATA ENABLE :
                          --! 出力有効信号.
                          out std_logic;
        TXD_TREADY      : --! @brief TRANSMIT DATA READY :
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
    signal   regs_addr          :  std_logic_vector(CSR_ADDR_WIDTH  -1 downto 0);
    signal   regs_ben           :  std_logic_vector(CSR_DATA_WIDTH/8-1 downto 0);
    signal   regs_wdata         :  std_logic_vector(CSR_DATA_WIDTH  -1 downto 0);
    signal   regs_rdata         :  std_logic_vector(CSR_DATA_WIDTH  -1 downto 0);
    signal   regs_err_req       :  std_logic;
    signal   regs_err_ack       :  std_logic;
    -------------------------------------------------------------------------------
    -- PTTY_SEND アクセス用信号群.
    -------------------------------------------------------------------------------
    signal   tx_regs_req        :  std_logic;
    signal   txd_buf_req        :  std_logic;
    signal   tx_ack             :  std_logic;
    signal   tx_err             :  std_logic;
    signal   tx_rdata           :  std_logic_vector(CSR_DATA_WIDTH  -1 downto 0);
    signal   tx_irq             :  std_logic;
    -------------------------------------------------------------------------------
    -- PTTY_RECV アクセス用信号群.
    -------------------------------------------------------------------------------
    signal   rx_regs_req       :  std_logic;
    signal   rxd_buf_req       :  std_logic;
    signal   rx_ack            :  std_logic;
    signal   rx_err            :  std_logic;
    signal   rx_rdata          :  std_logic_vector(CSR_DATA_WIDTH  -1 downto 0);
    signal   rx_irq            :  std_logic;
    -------------------------------------------------------------------------------
    -- レジスタマップ
    -------------------------------------------------------------------------------
    constant TX_REGS_AREA_LO   :  integer := 16#0010#;
    constant TX_REGS_AREA_HI   :  integer := 16#001F#;
    constant RX_REGS_AREA_LO   :  integer := 16#0020#;
    constant RX_REGS_AREA_HI   :  integer := 16#002F#;
    constant TXD_BUF_AREA_LO   :  integer := 16#0800#;
    constant TXD_BUF_AREA_HI   :  integer := 16#0BFF#;
    constant RXD_BUF_AREA_LO   :  integer := 16#0C00#;
    constant RXD_BUF_AREA_HI   :  integer := 16#0FFF#;
    -------------------------------------------------------------------------------
    -- PTTY_TX
    -------------------------------------------------------------------------------
    component  PTTY_TX
        generic (
            TXD_BUF_DEPTH   : integer range 4 to   15 :=  7;
            TXD_BUF_BASE    : integer := 0;
            CSR_ADDR_WIDTH  : integer range 1 to   64 := 32;
            CSR_DATA_WIDTH  : integer range 8 to 1024 := 32;
            TXD_BYTES       : integer := 1;
            TXD_CLK_RATE    : integer := 1;
            CSR_CLK_RATE    : integer := 1
        );
        port (
            RST             : in  std_logic;
            CLR             : in  std_logic;
            CSR_CLK         : in  std_logic;
            CSR_CKE         : in  std_logic;
            CSR_ADDR        : in  std_logic_vector(CSR_ADDR_WIDTH  -1 downto 0);
            CSR_BEN         : in  std_logic_vector(CSR_DATA_WIDTH/8-1 downto 0);
            CSR_WDATA       : in  std_logic_vector(CSR_DATA_WIDTH  -1 downto 0);
            CSR_RDATA       : out std_logic_vector(CSR_DATA_WIDTH  -1 downto 0);
            CSR_REG_REQ     : in  std_logic;
            CSR_BUF_REQ     : in  std_logic;
            CSR_WRITE       : in  std_logic;
            CSR_ACK         : out std_logic;
            CSR_ERR         : out std_logic;
            CSR_IRQ         : out std_logic;
            TXD_CLK         : in  std_logic;
            TXD_CKE         : in  std_logic;
            TXD_DATA        : out std_logic_vector(8*TXD_BYTES-1 downto 0);
            TXD_STRB        : out std_logic_vector(  TXD_BYTES-1 downto 0);
            TXD_LAST        : out std_logic;
            TXD_VALID       : out std_logic;
            TXD_READY       : in  std_logic
        );
    end component;
    -------------------------------------------------------------------------------
    -- PTTY_RX
    -------------------------------------------------------------------------------
    component  PTTY_RX
        generic (
            RXD_BUF_DEPTH   : integer range 4 to   15 :=  7;
            RXD_BUF_BASE    : integer := 0;
            CSR_ADDR_WIDTH  : integer range 1 to   64 := 32;
            CSR_DATA_WIDTH  : integer range 8 to 1024 := 32;
            RXD_BYTES       : integer := 1;
            RXD_CLK_RATE    : integer := 1;
            CSR_CLK_RATE    : integer := 1
        );
        port (
            RST             : in  std_logic;
            CLR             : in  std_logic;
            CSR_CLK         : in  std_logic;
            CSR_CKE         : in  std_logic;
            CSR_ADDR        : in  std_logic_vector(CSR_ADDR_WIDTH  -1 downto 0);
            CSR_BEN         : in  std_logic_vector(CSR_DATA_WIDTH/8-1 downto 0);
            CSR_WDATA       : in  std_logic_vector(CSR_DATA_WIDTH  -1 downto 0);
            CSR_RDATA       : out std_logic_vector(CSR_DATA_WIDTH  -1 downto 0);
            CSR_REG_REQ     : in  std_logic;
            CSR_BUF_REQ     : in  std_logic;
            CSR_WRITE       : in  std_logic;
            CSR_ACK         : out std_logic;
            CSR_ERR         : out std_logic;
            CSR_IRQ         : out std_logic;
            RXD_CLK         : in  std_logic;
            RXD_CKE         : in  std_logic;
            RXD_DATA        : in  std_logic_vector(8*RXD_BYTES-1 downto 0);
            RXD_STRB        : in  std_logic_vector(  RXD_BYTES-1 downto 0);
            RXD_LAST        : in  std_logic;
            RXD_VALID       : in  std_logic;
            RXD_READY       : out std_logic
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
            AXI4_ADDR_WIDTH => CSR_ADDR_WIDTH    , --
            AXI4_DATA_WIDTH => CSR_DATA_WIDTH    , --
            AXI4_ID_WIDTH   => CSR_ID_WIDTH      , --
            REGS_ADDR_WIDTH => CSR_ADDR_WIDTH    , --
            REGS_DATA_WIDTH => CSR_DATA_WIDTH      --
        )                                          -- 
        port map (                                 -- 
        -----------------------------------------------------------------------
        -- Clock and Reset Signals.
        -----------------------------------------------------------------------
            CLK             => CSR_CLK           , -- In  :
            RST             => RST               , -- In  :
            CLR             => CLR               , -- In  :
        -----------------------------------------------------------------------
        -- AXI4 Read Address Channel Signals.
        -----------------------------------------------------------------------
            ARID            => CSR_ARID          , -- In  :
            ARADDR          => CSR_ARADDR        , -- In  :
            ARLEN           => CSR_ARLEN         , -- In  :
            ARSIZE          => CSR_ARSIZE        , -- In  :
            ARBURST         => CSR_ARBURST       , -- In  :
            ARVALID         => CSR_ARVALID       , -- In  :
            ARREADY         => CSR_ARREADY       , -- Out :
        -----------------------------------------------------------------------
        -- AXI4 Read Data Channel Signals.
        -----------------------------------------------------------------------
            RID             => CSR_RID           , -- Out :
            RDATA           => CSR_RDATA         , -- Out :
            RRESP           => CSR_RRESP         , -- Out :
            RLAST           => CSR_RLAST         , -- Out :
            RVALID          => CSR_RVALID        , -- Out :
            RREADY          => CSR_RREADY        , -- In  :
        -----------------------------------------------------------------------
        -- AXI4 Write Address Channel Signals.
        -----------------------------------------------------------------------
            AWID            => CSR_AWID          , -- In  :
            AWADDR          => CSR_AWADDR        , -- In  :
            AWLEN           => CSR_AWLEN         , -- In  :
            AWSIZE          => CSR_AWSIZE        , -- In  :
            AWBURST         => CSR_AWBURST       , -- In  :
            AWVALID         => CSR_AWVALID       , -- In  :
            AWREADY         => CSR_AWREADY       , -- Out :
        -----------------------------------------------------------------------
        -- AXI4 Write Data Channel Signals.
        -----------------------------------------------------------------------
            WDATA           => CSR_WDATA         , -- In  :
            WSTRB           => CSR_WSTRB         , -- In  :
            WLAST           => CSR_WLAST         , -- In  :
            WVALID          => CSR_WVALID        , -- In  :
            WREADY          => CSR_WREADY        , -- Out :
        -----------------------------------------------------------------------
        -- AXI4 Write Response Channel Signals.
        -----------------------------------------------------------------------
            BID             => CSR_BID           , -- Out :
            BRESP           => CSR_BRESP         , -- Out :
            BVALID          => CSR_BVALID        , -- Out :
            BREADY          => CSR_BREADY        , -- In  :
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
        variable u_addr       : unsigned(CSR_ADDR_WIDTH-1 downto 0);
        variable tx_regs_sel : boolean;
        variable txd_buf_sel : boolean;
        variable rx_regs_sel : boolean;
        variable rxd_buf_sel : boolean;
    begin
        if (regs_req = '1') then
            u_addr       := to_01(unsigned(regs_addr));
            tx_regs_sel := (TX_REGS_AREA_LO <= u_addr and u_addr <= TX_REGS_AREA_HI);
            txd_buf_sel := (TXD_BUF_AREA_LO <= u_addr and u_addr <= TXD_BUF_AREA_HI);
            rx_regs_sel := (RX_REGS_AREA_LO <= u_addr and u_addr <= RX_REGS_AREA_HI);
            rxd_buf_sel := (RXD_BUF_AREA_LO <= u_addr and u_addr <= RXD_BUF_AREA_HI);
            if (tx_regs_sel) then
                tx_regs_req <= '1';
            else
                tx_regs_req <= '0';
            end if;
            if (txd_buf_sel) then
                txd_buf_req <= '1';
            else
                txd_buf_req <= '0';
            end if;
            if (rx_regs_sel) then
                rx_regs_req <= '1';
            else
                rx_regs_req <= '0';
            end if;
            if (rxd_buf_sel) then
                rxd_buf_req <= '1';
            else
                rxd_buf_req <= '0';
            end if;
            if (tx_regs_sel = FALSE) and
               (txd_buf_sel = FALSE) and
               (rx_regs_sel = FALSE) and
               (rxd_buf_sel = FALSE) then
                regs_err_req <= '1';
            else
                regs_err_req <= '0';
            end if;
        else
                tx_regs_req <= '0';
                txd_buf_req <= '0';
                rx_regs_req <= '0';
                rxd_buf_req <= '0';
                regs_err_req <= '0';
        end if;
    end process;
    regs_err_ack <= regs_err_req;
    regs_ack     <= tx_ack   or rx_ack or regs_err_ack;
    regs_err     <= tx_err   or rx_err;
    regs_rdata   <= tx_rdata or rx_rdata;
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    TX:  PTTY_TX                                   -- 
        generic map (                              -- 
            TXD_BUF_DEPTH   => TXD_BUF_DEPTH     , --
            TXD_BUF_BASE    => TXD_BUF_AREA_LO   , --
            CSR_ADDR_WIDTH  => CSR_ADDR_WIDTH    , -- 
            CSR_DATA_WIDTH  => CSR_DATA_WIDTH    , -- 
            TXD_BYTES       => TXD_BYTES         , -- 
            TXD_CLK_RATE    => 0                 , -- 
            CSR_CLK_RATE    => 0                   -- 
        )                                          -- 
        port map (                                 -- 
            RST             => RST               , -- In  :
            CLR             => CLR               , -- In  :
            CSR_CLK         => CSR_CLK           , -- In  :
            CSR_CKE         => '1'               , -- In  :
            CSR_ADDR        => regs_addr         , -- In  :
            CSR_BEN         => regs_ben          , -- In  :
            CSR_WDATA       => regs_wdata        , -- In  :
            CSR_RDATA       => tx_rdata          , -- Out :
            CSR_REG_REQ     => tx_regs_req       , -- In  :
            CSR_BUF_REQ     => txd_buf_req       , -- In  :
            CSR_WRITE       => regs_write        , -- In  :
            CSR_ACK         => tx_ack            , -- Out :
            CSR_ERR         => tx_err            , -- Out :
            CSR_IRQ         => tx_irq            , -- Out :
            TXD_CLK         => TXD_CLK           , -- In  :
            TXD_CKE         => '1'               , -- In  :
            TXD_DATA        => TXD_TDATA         , -- Out :
            TXD_STRB        => TXD_TSTRB         , -- Out :
            TXD_LAST        => TXD_TLAST         , -- Out :
            TXD_VALID       => TXD_TVALID        , -- Out :
            TXD_READY       => TXD_TREADY          -- In  :
        );                                         -- 
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    RX: PTTY_RX                                    -- 
        generic map (                              -- 
            RXD_BUF_DEPTH   => RXD_BUF_DEPTH     , --
            RXD_BUF_BASE    => RXD_BUF_AREA_LO   , --
            CSR_ADDR_WIDTH  => CSR_ADDR_WIDTH    , --
            CSR_DATA_WIDTH  => CSR_DATA_WIDTH    , --
            RXD_BYTES       => RXD_BYTES         , --
            RXD_CLK_RATE    => 0                 , --
            CSR_CLK_RATE    => 0                   --
        )                                          -- 
        port map (                                 -- 
            RST             => RST               , -- In  :
            CLR             => CLR               , -- In  :
            CSR_CLK         => CSR_CLK           , -- In  :
            CSR_CKE         => '1'               , -- In  :
            CSR_ADDR        => regs_addr         , -- In  :
            CSR_BEN         => regs_ben          , -- In  :
            CSR_WDATA       => regs_wdata        , -- In  :
            CSR_RDATA       => rx_rdata          , -- Out :
            CSR_REG_REQ     => rx_regs_req       , -- In  :
            CSR_BUF_REQ     => rxd_buf_req       , -- In  :
            CSR_WRITE       => regs_write        , -- In  :
            CSR_ACK         => rx_ack            , -- Out :
            CSR_ERR         => rx_err            , -- Out :
            CSR_IRQ         => rx_irq            , -- Out :
            RXD_CLK         => RXD_CLK           , -- In  :
            RXD_CKE         => '1'               , -- In  :
            RXD_DATA        => RXD_TDATA         , -- In  :
            RXD_STRB        => RXD_TSTRB         , -- In  :
            RXD_LAST        => RXD_TLAST         , -- In  :
            RXD_VALID       => RXD_TVALID        , -- In  :
            RXD_READY       => RXD_TREADY          -- Out :
        );                                         --
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    CSR_IRQ <= '1' when (tx_irq = '1' or rx_irq = '1') else '0';
end RTL;
