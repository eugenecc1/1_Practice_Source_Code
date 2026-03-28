/* VGA文字表示回路                                  */
/* Copyright(C) 2013 Cobac.Net All rights reserved. */

module VGAIF(
    /* IO module */
    input           CLK, RST,
    input   [31:0]  IO_Address, IO_Write_Data,
    input           WR,
    output  [31:0]  RDATA,
    /* VGA出力 */
    output  reg [2:0]   VGA_R, VGA_G,
    output  reg [1:0]   VGA_B,
    output              VGA_HS, VGA_VS
);

wire    [9:0]   HCNT;
wire    [9:0]   VCNT;
wire            PCK;

/* HVカウンタを接続 */
HVGEN HVGEN( .CLK(CLK), .RST(RST), .PCK(PCK),
  .VGA_HS(VGA_HS), .VGA_VS(VGA_VS), .HCNT(HCNT), .VCNT(VCNT) );

/* 内蔵RAM接続信号 */
wire [15:0] vramout, vramout_a;
wire [11:0] vramaddr;

assign RDATA = {16'h0000, vramout_a};

/* 読み書きはクロック（CLKの立上がり）同期 */
/* ポートAはMCS側、ポートBは表示側         */
vram    vram (
    .clka(CLK),
    .wea(WR),
    .addra(IO_Address[13:2]),
    .dina(IO_Write_Data[15:0]),
    .douta(vramout_a),
    .clkb(PCK),
    .web(1'b0),
    .addrb(vramaddr),
    .dinb(16'h0),
    .doutb(vramout)
);

wire [2:0] vdotcnt;
wire [7:0] cgout;

/* 読み出しはクロック同期 */
cgrom   cgrom (
    .clka( PCK ),
    .addra( {vramout[6:0], vdotcnt} ),
    .douta( cgout )
    );

/* HCNTとVCNTを文字とドットのカウンタとして分けて考える */
wire [6:0] hchacnt = HCNT[9:3];  /* 水平文字カウンタ   */
wire [2:0] hdotcnt = HCNT[2:0];  /* 水平ドットカウンタ */
wire [5:0] vchacnt = VCNT[8:3];  /* 垂直文字カウンタ   */
assign     vdotcnt = VCNT[2:0];  /* 垂直ドットカウンタ */

/* VRAMのアドレス生成  vramaddr ← vchacnt ＊ 80 ＋ hchacnt */
assign vramaddr = (vchacnt<<6) + (vchacnt<<4) + hchacnt;

/* シフトレジスタ */
reg [7:0] sreg;
wire sregld = (hdotcnt==3'h6 && HCNT<10'd640);

always @( posedge PCK ) begin
    if ( RST )
        sreg <= 8'h00;
    else if ( sregld )
        sreg <= cgout;
    else
        sreg <= {sreg[6:0], 1'b0};
end

/* 色情報をsregのLDと同時に取り込む */
reg [7:0] rgb;

always @( posedge PCK ) begin
    if ( RST )
        rgb <= 8'h00;
    else if ( sregld )
        rgb <= vramout[15:8];
end

/* 水平、垂直表示イネーブル信号 */
wire hdispen = (10'd7<=HCNT && HCNT<10'd647);
wire vdispen = (VCNT<9'd400);

/* RGB出力信号作成 */
always @( posedge PCK ) begin
    if ( RST )
        {VGA_R, VGA_G, VGA_B} <= 8'h00;
    else
        {VGA_R, VGA_G, VGA_B} <=
            rgb & {8{hdispen & vdispen}} & {8{sreg[7]}};
end

endmodule
