/* キャプチャ回路（第９章課題用に改造）             */
/* Copyright(C) 2013 Cobac.Net All rights reserved. */

module CAPTURE(
    input           CLK, RST,
    /* BUS I/F */
    input   [31:0]  IO_Address, IO_Write_Data,
    input   [3:0]   IO_Byte_Enable,
    output  [31:0]  RDATA,
    input           WR,
    /* MEMIF */
    output  [23:1]  CMEMADDR,
    output  [15:0]  CMEMDOUT,
    output          CMEMnWE_asrt, CMEMnWE_deas,
    /* CMOSカメラ */
    input           PCLK,
    input           HREF,
    input           VSYNC,
    output  reg     XCLK,
    input   [7:0]   CAMDATA,
    /* フラグ */
    output  reg     OVFLAG, UFFLAG,
    output          empty,
    output  [2:0]   STATE
);

/* キャプチャページ・レジスタ */
reg [5:0]   captpage;

always @( posedge CLK ) begin
    if ( RST )
        captpage <= 6'h00;
    else if ( (IO_Address[15:2]==14'h0000) & WR & IO_Byte_Enable[0] )
        captpage <= IO_Write_Data[5:0];
end

/* キャプチャON、cblankフラグ */
reg  capton, cblank;
wire captend;

always @( posedge CLK ) begin
    if ( RST )
        cblank <= 1'b0;
    else if ( captend )
        cblank <= 1'b1;
    else if ( (IO_Address[15:2]==14'h0001) &
            (IO_Write_Data[0]==1'b0) & WR & IO_Byte_Enable[0] )
        cblank <= 1'b0;
end

always @( posedge CLK ) begin
    if ( RST )
        capton <= 1'b0;
    else if ( (IO_Address[15:2]==14'h0001) & WR & IO_Byte_Enable[0] )
        capton <= IO_Write_Data[1];
end

/* レジスタ読み出し */
assign RDATA = (IO_Address[15:2]==14'h0000) ? {26'b0, captpage}:
                {30'b0, capton, cblank};

/* カメラ用クロック XCLK:25MHz */
always @( posedge CLK ) begin
    if ( RST )
        XCLK <= 1'b0;
    else
        XCLK <= ~XCLK;
end

/* 書き込み用アドレスカウンタ（宣言部分） */
reg [18:0]  addrcnt;
parameter ADDRMAX = 640*480-1;
wire addrend = (addrcnt==ADDRMAX);

/* メモリ書き込みコントロールステートマシン（宣言部） */
parameter HALT=3'h0, S0=3'h1, S1=3'h2, S2=3'h3, S3=3'h4,
          S4=3'h5, STBY=3'h6;
reg [2:0] cur, nxt;
assign STATE = cur;

/* 内部リセット信号・・VSYNCの立ち上がりで作成 */
reg ff, camrst;

always @( posedge PCLK ) begin
    if ( RST )
        ff <= 1'b0;
    else
        ff <= VSYNC;
end

always @( posedge PCLK ) begin
    if ( RST )
        camrst <= 1'b0;
    else
        camrst <= (VSYNC & ~ff);
end

/* HREFをPCLKで遅延 */
reg HREF_dly;
always @( posedge PCLK ) begin
    if ( RST )
        HREF_dly <= 1'b0;
    else
        HREF_dly <= HREF;
end

/* HREF_dly期間のカウンタ */
reg [10:0] wrcnt;

always @( posedge PCLK ) begin
    if ( RST )
        wrcnt <= 11'h0;
    else if ( HREF_dly==1'b0 )
        wrcnt <= 11'h0;
    else
        wrcnt <= wrcnt + 11'h1;
end

/* FIFO書き込み信号（1200データだけ取り込み） */
assign fifo_wr = (11'd40 <= wrcnt) && (wrcnt<=11'd1239)  & capton;

/* カメラデータ取り込み */
reg [7:0] fifodin;

always @( posedge PCLK ) begin
    if ( RST )
        fifodin <= 8'h00;
    else if ( camrst )
        fifodin <= 8'h00;
    else if ( HREF )
        fifodin <= CAMDATA;
end

/* FIFO接続 */
wire fifo_rd = (cur==HALT || cur==S4 || cur==STBY) & ~empty;
wire overflow, underflow;

captfifo captfifo(
    .wr_clk     (PCLK),
    .rd_clk     (CLK),
    .din        (fifodin),
    .wr_en      (fifo_wr),
    .rd_en      (fifo_rd),
    .dout       (CMEMDOUT),
    .full       (/* 未接続 */),
    .overflow   (overflow),
    .empty      (empty),
    .underflow  (underflow)
);

/* オーバーフロー、アンダーフローフラグ（デバッグ用） */
always @( posedge CLK ) begin
    if ( RST )
        OVFLAG <= 1'b0;
    else if ( overflow )
        OVFLAG <= 1'b1;
end     

always @( posedge CLK ) begin
    if ( RST )
        UFFLAG <= 1'b0;
    else if ( underflow )
        UFFLAG <= 1'b1;
end     

/* VSYNCをCLKで同期化し、立ち上がり検出して終了信号captendを作成 */
reg [2:0] syncclk;

always @( posedge CLK ) begin
    if ( RST )
        syncclk <= 3'h0;
    else
        syncclk <= {syncclk[1:0], VSYNC};
end

assign captend = ~syncclk[2] & syncclk[1];

/* メモリ書き込みコントロールステートマシン */
always @( posedge CLK ) begin
    if ( RST )
        cur <= HALT;
    else if ( captend )
        cur <= HALT;
    else
        cur <= nxt;
end

always @* begin
    case ( cur )
        HALT:   if ( ~empty )
                    nxt <= S0;
                else
                    nxt <= HALT;
        S0:     nxt <= S1;
        S1:     nxt <= S2;
        S2:     nxt <= S3;
        S3:     nxt <= S4;
        S4:     if ( addrend )
                    nxt <= HALT;
                else if ( ~empty )
                    nxt <= S0;
                else
                    nxt <= STBY;
        STBY:   if ( ~empty )
                    nxt <= S0;
                else
                    nxt <= STBY;
        default:nxt <= HALT;
    endcase
end

/* 書き込み用アドレスカウンタ */
always @( posedge CLK ) begin
    if ( RST )
        addrcnt <= 19'h0;
    else if ( cur==HALT )
        addrcnt <= 19'h0;
    else if ( cur==S4 )
        if ( addrend )
            addrcnt <= 19'h0;
        else
            addrcnt <= addrcnt + 19'h1;
end

parameter CAPTSIZE = 600*480;  // 横方向は600個に減らす
assign CMEMADDR = captpage*CAPTSIZE + addrcnt;

/* メモリ書き込み信号 */
assign CMEMnWE_asrt = ( cur==S0 );
assign CMEMnWE_deas = ( cur==S3 );

endmodule
