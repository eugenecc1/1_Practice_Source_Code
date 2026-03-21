/* Copyright(C) 2020 Cobac.Net All Rights Reserved. */
/* chapter: 第7章課題                      */
/* project: chardisp                       */
/* outline: 反転、点滅付き文字表示回路本体 */

module chardisp(
    /* AXI4-Lite信号 */
    input           CLK, RST,
    input   [15:0]  WRADDR,
    input   [3:0]   BYTEEN,
    input           WREN,
    input   [31:0]  WRDATA,
    input   [15:0]  RDADDR,
    input           RDEN,
    output  [31:0]  RDDATA,
    /* VGA出力 */
    output          PCK,
    output  [3:0]   VGA_R, VGA_G, VGA_B,
    output          VGA_HS, VGA_VS,
    output  reg     VGA_DE
);

/* VGA(640×480)用パラメータ読み込み */
`include "vga_param.vh"

wire    [9:0]   HCNT;
wire    [9:0]   VCNT;

/* syncgen接続 */
syncgen syncgen (
    .CLK    (CLK),
    .RST    (RST),
    .PCK    (PCK),
    .VGA_HS (VGA_HS),
    .VGA_VS (VGA_VS),
    .HCNT   (HCNT),
    .VCNT   (VCNT)
);

/* 内部での参照用にカウント値を変換 */
wire [9:0] iHCNT = HCNT - HFRONT - HWIDTH - HBACK + 10'd8;
wire [9:0] iVCNT = VCNT - VFRONT - VWIDTH - VBACK - 10'd40;

/* VRAM接続信号 */
wire [23:0] vramout;
wire [11:0] addra;
wire [11:0] vramaddr;

assign addra = (RDEN) ? RDADDR[13:2]: WRADDR[13:2];
assign RDDATA[31:24] = 8'h00;
wire [2:0] wea = {3{WREN}} & BYTEEN[2:0];

/* VRAM接続 */
VRAM VRAM (
    .clka   (CLK),
    .wea    (wea),
    .addra  (addra),
    .dina   (WRDATA[23:0]),
    .douta  (RDDATA[23:0]),
    .clkb   (PCK),
    .web    (3'b0),
    .addrb  (vramaddr),
    .dinb   (24'h0),
    .doutb  (vramout)
);

wire [2:0] vdotcnt;
wire [7:0] cgout;

/* 反転及び点滅ビットの宣言 */
reg revbit, bnkbit;

/* 点滅用カウンタ */
reg [23:0]  cnt24;
wire hz2en = (cnt24 == 24'd12499999);

always @( posedge PCK ) begin
    if ( RST )
        cnt24 <= 24'h0;
    else if ( hz2en )
        cnt24 <= 24'h0;
    else
        cnt24 <= cnt24 + 24'h1;
end

/* 点滅用、1Hz、デューティ50%信号 */
reg blink;

always @( posedge PCK ) begin
    if ( RST )
        blink <= 1'b0;
    else if ( hz2en )
        blink <= ~blink;
end

/* 文字反転ビット */
wire reverse = (bnkbit==1'b1) ? blink: revbit;

/* CGROM接続 */
CGROM CGROM (
    .addra  ({vramout[6:0], vdotcnt}),
    .douta  (cgout),
    .clka   (PCK)
);

/* HCNとVCNTを文字とドットのカウンタとして分けて考える */
wire [6:0] hchacnt = iHCNT[9:3];  /* 水平文字カウンタ   */
wire [2:0] hdotcnt = iHCNT[2:0];  /* 水平ドットカウンタ */
wire [5:0] vchacnt = iVCNT[8:3];  /* 垂直文字カウンタ   */
assign     vdotcnt = iVCNT[2:0];  /* 垂直ドットカウンタ */

/* VRAMのアドレス生成  vramaddr ← vchacnt ＊ 80 ＋ hchacnt */
assign vramaddr = (vchacnt<<6) + (vchacnt<<4) + hchacnt;

/* シフトレジスタ */
reg [7:0] sreg;
wire sregld = (hdotcnt==3'h6 && iHCNT<10'd640);

always @( posedge PCK ) begin
    if ( RST )
        sreg <= 8'h00;
    else if ( sregld )
        sreg <= cgout;
    else
        sreg <= {sreg[6:0], 1'b0};
end

/* 色情報をsregのLDと同時に取り込む */
reg [11:0] color;

always @( posedge PCK ) begin
    if ( RST ) begin
        color  <= 12'h000;
        revbit <= 1'b0;
        bnkbit <= 1'b0;
    end
    else if ( sregld ) begin
        color  <= vramout[19:8];
        revbit <= vramout[20];
        bnkbit <= vramout[21];
    end
end

/* 水平、垂直表示イネーブル信号 */
wire hdispen = (10'd7<=iHCNT && iHCNT<10'd647);
wire vdispen = (iVCNT<9'd400);

/* RGB出力信号作成 */
reg [11:0] vga_rgb;

always @( posedge PCK ) begin
    if ( RST )
        vga_rgb <= 12'h000;
    else
        vga_rgb <= color & {12{hdispen & vdispen & (sreg[7] ^ reverse)}};
end

assign {VGA_R, VGA_G, VGA_B} = vga_rgb;

/* VGA_DE作成 */
always @( posedge PCK ) begin
    if ( RST )
        VGA_DE <= 1'b0;
    else
        VGA_DE <= hdispen & (9'd45<=VCNT); /* 上下の黒表示部分も含める */
end

endmodule
