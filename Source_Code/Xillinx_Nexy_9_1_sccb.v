/* CMOSカメラモジュールのSCCBコントローラ           */
/* Copyright(C) 2013 Cobac.Net All rights reserved. */

module SCCB(
    input           CLK, RST,
    /* BUS I/F */
    input   [31:0]  IO_Address, IO_Write_Data,
    input   [3:0]   IO_Byte_Enable,
    output  [31:0]  RDATA,
    input           WR,
    /* SCCB out */
    output  reg     SCL,
    output          SDA
);

/* レジスタ書き込み信号 */
assign sccbtrig = WR && IO_Address[15:2]==14'h0000
                     && (&IO_Byte_Enable[1:0]);

/* BUSYフラグ読み出し */
reg     sccbbusy;
assign RDATA = (IO_Address[15:2]==14'h0001) ? {31'b0, sccbbusy}: 32'b0;

/* ステートマシン（宣言部） */
parameter HALT=2'h0, STBIT=2'h1, SEND=2'h2, POSDLY=2'h3;
reg [1:0]   cur, nxt;

/* 各種イネーブル信号作成用カウンタ（100kHz） */
parameter CNTMAX=9'd500;
reg [8:0]   cnt9;

always @( posedge CLK ) begin
    if ( RST )
        cnt9 <= 9'h0;
    else if ( cnt9==CNTMAX-1 )
        cnt9 <= 9'h0;
    else
        cnt9 <= cnt9 + 9'h1;
end

/* 各種イネーブル信号 */
wire state_en = (cnt9==CNTMAX-1);
wire sclset0  = (cnt9==2);
wire sclset1  = (cnt9==CNTMAX/2+2);
wire sft_en   = (cnt9==CNTMAX/4-1) && (cur!=HALT);

/* データシフトレジスタ */
reg [29:0] dsft;

always @( posedge CLK ) begin
    if ( RST )
        dsft <= 30'h3fff_ffff;
    else if ( sccbtrig )
        dsft <= { 2'b10, 8'h42, 1'b0, IO_Write_Data[15:8], 1'b0,
                                      IO_Write_Data[7:0],  1'b0, 1'b0};
    else if ( sft_en )
        dsft <= {dsft[28:0], 1'b1};
end

/* Hi-Zシフトレジスタ */
parameter HIZPOS=30'b00_000000001_000000001_000000001_0;
reg [29:0] zsft;

always @( posedge CLK ) begin
    if ( RST )
        zsft <= 30'b0;
    else if ( sccbtrig )
        zsft <= HIZPOS;
    else if ( sft_en )
        zsft <= {zsft[28:0], 1'b0};
end

/* SDA出力作成 */
assign SDA = (zsft[29]==1'b1) ? 1'bz: dsft[29];

/* SCL出力作成 */
always @( posedge CLK ) begin
    if ( RST )
        SCL <= 1'b1;
    else if ( cur==SEND ) begin
        if ( sclset0 )
            SCL <= 1'b0;
        else if ( sclset1 )
            SCL <= 1'b1;
    end
    else
        SCL <= 1'b1;
end

/* データ送出カウンタ */
reg [4:0] sendcnt;

always @( posedge CLK ) begin
    if ( RST )
        sendcnt <= 5'h00;
    else if ( cur==HALT )
        sendcnt <= 5'h00;
    else if ( cur==SEND && state_en )
        sendcnt <= sendcnt + 5'h01;
end

wire sendend = (sendcnt==5'd27);

/* sccbbusy遅延用カウンタ   */
/* 1カウントあたり10μs遅延 */
reg [7:0] busycnt;
parameter BUSYCNTMAX = 20;

always @( posedge CLK ) begin
    if ( RST )
        busycnt <= 8'h00;
    else if ( cur==HALT )
            busycnt <= 8'h00;
    else if ( state_en && cur==POSDLY )
        if ( busycnt==BUSYCNTMAX )
            busycnt <= 8'h00;
        else
            busycnt <= busycnt + 8'h01;
end

/* sccbbusy信号 */
always @( posedge CLK ) begin
    if ( RST )
        sccbbusy <= 1'b0;
    else if ( sccbtrig )
        sccbbusy <= 1'b1;
    else if ( state_en && cur==POSDLY && busycnt==BUSYCNTMAX )
        sccbbusy <= 1'b0;
end

/* 状態遷移の開始信号                     */
/* sccbtrigを次のstate_enまで伸ばして作成 */
/* sccbtrigとstate_enが同時でも伸びる     */
reg     regwrite;

always @(  posedge CLK ) begin
    if ( RST )
        regwrite <= 1'b0;
    else if ( sccbtrig )
        regwrite <= 1'b1;
    else if ( state_en )
        regwrite <= 1'b0;
end

/* ステートマシン */
always @( posedge CLK ) begin
    if ( RST )
        cur <= HALT;
    else if ( state_en )
        cur <= nxt;
end

always @* begin
    case ( cur )
        HALT:   if ( regwrite )
                    nxt = STBIT;
                else
                    nxt = HALT;
        STBIT: nxt = SEND;
        SEND:   if ( sendend )
                    nxt = POSDLY;
                else
                    nxt = SEND;
        POSDLY: if ( busycnt==BUSYCNTMAX )
                    nxt = HALT;
                else
                    nxt = POSDLY;
        default:nxt = HALT;
    endcase
end

endmodule
