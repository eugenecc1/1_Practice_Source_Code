/* グラフィック表示回路                             */
/* Copyright(C) 2013 Cobac.Net All rights reserved. */

module DISPCTRL(
    input               CLK, RST,
    /* BUS I/F */
    input       [31:0]  IO_Address, IO_Write_Data,
    input       [3:0]   IO_Byte_Enable,
    output      [31:0]  RDATA,
    input               WR,
    /* MEMIF */
    output      [23:1]  DMEMADDR,
    input       [15:0]  DMEMDIN,
    input       [1:0]   MODE,
    /* VGA出力 */
    output  reg [2:0]   VGA_R, VGA_G,
    output  reg [1:0]   VGA_B,
    output              VGA_HS, VGA_VS,
    /* フラグ */
    output  reg         OVFLAG, UFFLAG
);

/* MODE */
parameter DISPMODE = 2'b00;

/* 表示ページレジスタ */
reg [5:0] disppage;

always @( posedge CLK ) begin
    if ( RST )
        disppage <= 6'h00;
    else if ( (IO_Address[15:2]==14'h0000) & WR & IO_Byte_Enable[0] )
        disppage <= IO_Write_Data[5:0];
end

/* dblankフラグ */
reg  dblank;
wire dispend;

always @( posedge CLK ) begin
    if ( RST )
        dblank <= 1'b0;
    else if ( dispend )
        dblank <= 1'b1;
    else if ( (IO_Address[15:2]==14'h0001) &
            ( (IO_Write_Data[0]==1'b0) & WR & IO_Byte_Enable[0] ) )
        dblank <= 1'b0;
end

/* レジスタ読み出し */
assign RDATA = (IO_Address[15:2]==14'h0000) ? {26'b0, disppage}:
                {31'b0, dblank};

/* 読み出し用アドレスカウンタ（宣言） */
reg [17:0]  addrcnt;
parameter ADDRMAX = 320*480-1;
wire      addrend = (addrcnt==ADDRMAX);

/* FIFO書き込みコントロールステートマシン（宣言） */
parameter HALT=3'h0, S0=3'h1, S1=3'h2, S2=3'h3, S3=3'h4, STBY=3'h5;
reg [2:0] cur, nxt;

/* HVカウンタを接続 */
wire    [9:0]   HCNT;
wire    [9:0]   VCNT;
wire            PCK;

HVGEN HVGEN( .CLK(CLK), .RST(RST), .PCK(PCK),
  .VGA_HS(VGA_HS), .VGA_VS(VGA_VS), .HCNT(HCNT), .VCNT(VCNT) );

/* VCNTをグラフィック表示用に補正 */
wire    [9:0]   gvcnt;
assign gvcnt = (VCNT>10'd484) ? VCNT -10'd485: VCNT + 10'd40; 

/* 画像開始/終了信号・・CLKのFF2段で受けて作成 */
wire vstart_pck = (gvcnt==10'd523);
wire vend_pck   = (gvcnt==10'd481);

reg [1:0] stff, edff;

always @( posedge CLK ) begin
    if ( RST ) begin
        stff <= 2'b00;
        edff <= 2'b00;
    end
    else begin
        stff <= {stff[0], vstart_pck};
        edff <= {edff[0], vend_pck};
    end
end

wire    vstart  = ~stff[1] & stff[0];
assign  dispend = ~edff[1] & edff[0];


/* FIFOを接続 */
wire almost_full, fifo_rd, overflow, empty, underflow;
wire [7:0]  fifo_out;

dispfifo dispfifo(
  .wr_clk       (CLK),
  .rd_clk       (PCK),
  .din          ( {DMEMDIN[7:0], DMEMDIN[15:8]} ),  // 上下バイト交換
  .wr_en        (cur==S3),
  .rd_en        (fifo_rd),
  .dout         (fifo_out),
  .full         (/* 未接続 */),
  .almost_full  (almost_full),
  .overflow     (overflow),
  .empty        (empty),
  .underflow    (underflow)
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

/* 水平、垂直表示イネーブル信号 */
wire   hdispen = (10'd7<=HCNT && HCNT<10'd647);
wire   vdispen = (gvcnt<9'd480);
assign fifo_rd = vdispen && (10'd6<=HCNT && HCNT<10'd646) && ~empty;

/* RGB出力信号作成 */
always @( posedge PCK ) begin
    if ( RST )
        {VGA_R, VGA_G, VGA_B} <= 8'h00;
    else if ( MODE==DISPMODE )
        {VGA_R, VGA_G, VGA_B} <= fifo_out & {8{hdispen & vdispen}};
    else
        {VGA_R, VGA_G, VGA_B} <= 8'h03 & {2{hdispen & vdispen}};
end

/* FIFO書き込みコントロールステートマシン */
always @( posedge CLK ) begin
    if ( RST )
        cur <= HALT;
    else
        cur <= nxt;
end

always @* begin
    case ( cur )
        HALT:   if ( vstart )
                    nxt = S0;
                else
                    nxt = HALT;
        S0:     nxt = S1;
        S1:     nxt = S2;
        S2:     nxt = S3;
        S3:     if ( addrend )
                    nxt = HALT;
                else if ( ~almost_full )
                    nxt = S0;
                else
                    nxt = STBY;
        STBY:   if ( ~almost_full )
                    nxt = S0;
                else
                    nxt = STBY;
        default:nxt = HALT;
    endcase
end

/* 読み出し用アドレスカウンタ */
always @( posedge CLK ) begin
    if ( RST )
        addrcnt <= 18'h0;
    else if ( cur==HALT )
        addrcnt <= 18'h0;
    else if ( cur==S3 )
        if ( addrend )
            addrcnt <= 18'h0;
        else
            addrcnt <= addrcnt + 18'h1;
end

parameter DISPSIZE = 640*480/2;
assign    DMEMADDR = disppage * DISPSIZE + addrcnt;

endmodule
