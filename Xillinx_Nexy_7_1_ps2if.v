/* PS/2インターフェース                             */
/* Copyright(C) 2013 Cobac.Net All rights reserved. */

module PS2IF(
    input           CLK, RST,
    input   [31:0]  IO_Address,
    input   [3:0]   IO_Byte_Enable,
    input   [31:0]  IO_Write_Data,
    input           WR,
    output  [31:0]  RDATA,
    inout           PS2CLK, PS2DATA     // 双方向
);

/* I/Oバス信号の一部を切り出し使いやすくする */
wire [3:0] ADDR  = IO_Address[3:0];
wire [7:0] WDATA = IO_Write_Data[7:0];

/* シフトレジスタ、受信レジスタ、フラグ類（reg宣言） */
reg     [9:0]   sft;
reg     [7:0]   ps2rdata;
reg     empty, valid;

/* ステートマシン（パラメータおよびreg宣言） */
parameter HALT=3'h0, CLKLOW=3'h1, STBIT=3'h2, SENDBIT=3'h3,
          WAITCLK=3'h4, GETBIT=3'h5, SETFLG=3'h6;
(* signal_encoding = "user" *) reg [2:0]   cur, nxt;

/* 送信時のシフトレジスタ書き込み信号 */
wire txregwr = (ADDR==4'h8) & WR & IO_Byte_Enable[0];

/* レジスタ読み出し */
assign RDATA = (ADDR==4'h0) ? 
               {30'b0, empty, valid}: {24'b0, ps2rdata};

/* PS2CLK出力のハザード防止 */
reg     ps2clken;

always @( posedge CLK ) begin
    if ( RST )
        ps2clken <= 1'b0;
    else
        ps2clken <= (cur==CLKLOW  || cur==STBIT);
end

/* PS2出力 */
assign  PS2CLK  = (ps2clken) ? 1'b0  : 1'bz;
assign  PS2DATA = (cur==SENDBIT || cur==STBIT) ? sft[0]: 1'bz;

/* スタートビット送出用100μs計時用カウンタ */
reg [12:0]   txcnt;

parameter TXMAX=13'd5000;
wire over100us = (txcnt==TXMAX-1);

always @( posedge CLK ) begin
    if ( RST )
        txcnt <= 13'h0000;
    else if ( cur==HALT )
        txcnt <= 13'h0000;
    else if ( over100us )
        txcnt <= 13'h0000;
    else
        txcnt <= txcnt + 13'h1;
end

/* 受信したPS2CLKの立ち下がり検出および同期化 */
reg     [2:0]   sreg;
wire            clkfall;

always @( posedge CLK ) begin
    if ( RST )
        sreg <= 3'b000;
    else
        sreg <= {sreg[1:0], PS2CLK};
end

assign clkfall = sreg[2] & ~sreg[1];

/* 送受信ビット数カウンタ */
reg     [3:0]   bitcnt;

always @( posedge CLK ) begin
    if ( RST )
        bitcnt <= 4'h0;
    else if ( cur==HALT )
        bitcnt <= 4'h0;
    else if ( (cur==SENDBIT || cur==GETBIT) & clkfall )
        bitcnt <= bitcnt + 4'h1;
end

/* ステートマシン */
always @( posedge CLK ) begin
    if ( RST )
        cur <= HALT;
    else
        cur <= nxt;
end

always @* begin
    case ( cur )
        HALT:   if ( txregwr )
                    nxt = CLKLOW;
                else if ( (PS2DATA==1'b0) & clkfall )
                    nxt = GETBIT;
                else
                    nxt = HALT;
        CLKLOW: if ( over100us )
                    nxt = STBIT;
                else
                    nxt = CLKLOW;
        STBIT:  if ( over100us )
                    nxt = SENDBIT;
                else
                    nxt = STBIT;
        SENDBIT:if ( (bitcnt==4'h9) & clkfall )
                    nxt = WAITCLK;
                else
                    nxt = SENDBIT;
        WAITCLK:if ( clkfall )
                    nxt = HALT;
                else
                    nxt = WAITCLK;
        GETBIT: if ( (bitcnt==4'h7) & clkfall )
                    nxt = SETFLG;
                else
                    nxt = GETBIT;
        SETFLG: if ( clkfall )
                    nxt = WAITCLK;
                else
                    nxt = SETFLG;
        default:nxt = HALT;
    endcase
end

/* emptyフラグ（受信中も非empty） */
always @( posedge CLK ) begin
    if ( RST )
        empty <= 1'b1;
    else
        empty <= (cur==HALT) ? 1'b1: 1'b0;
end

/* 受信データ有効フラグ */
always @( posedge CLK ) begin
    if ( RST )
        valid <= 1'b0;
    else if ( (ADDR==4'h0) & WR )
        valid <= WDATA[0];
    else if ( cur==SETFLG & clkfall )
        valid <= 1'b1;
end

/* シフトレジスタ */
always @( posedge CLK ) begin
    if ( RST )
        sft <= 10'h000;
    else if ( txregwr )
        sft <= { ~(^WDATA), WDATA, 1'b0 };
    else if ( cur==SENDBIT & clkfall )
        sft <= {1'b1, sft[9:1]};
    else if ( cur==GETBIT & clkfall )
        sft <= {PS2DATA, sft[9:1]};
end

/* 受信データ */
always @( posedge CLK ) begin
    if ( RST )
        ps2rdata <= 8'h00;
    else if ( cur==SETFLG & clkfall )
        ps2rdata <= sft[9:2];
end

endmodule
