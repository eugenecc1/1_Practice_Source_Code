/* 第３章課題　時刻あわせ機能つき24時間時計の拡張   */
/* Copyright(C) 2013 Cobac.Net All Rights Reserved. */

module KADAI3(
    input   CLK100, RST,
    input   [2:0]   BTN,
    output  [7:0]   LED,
    output  [7:0]   nSEG,
    output  [3:0]   nAN
);

/* CLK(50MHz)の作成 */
reg CLK;

always @( posedge CLK100 ) begin
    CLK <= ~CLK;
end

wire    CASEC, CAMIN;
wire    MODE,   SELECT, ADJUST;
wire    SECCLR, MININC, HOURINC;
wire    SECON,  MINON,  HOURON;
wire    EN1HZ,  SIG2HZ;
wire    [3:0]   SECL, MINL, HOURL;
wire    [2:0]   SECH, MINH;
wire    [1:0]   HOURH;
wire    H10EN, T_SIG, MODE24;

assign H10EN = HOURON && (HOURH!=2'h0); /* 10時桁のゼロサプレス */
assign T_SIG = (MINH==3'h0 && MINL==4'h0 && SECH==3'h0 && SECL==4'h0) & ~SIG2HZ; /* 時報 */

/* 各ブロックの接続 */
CNT1SEC CNT1SEC( .CLK(CLK), .RST(RST), .EN1HZ(EN1HZ), .SIG2HZ(SIG2HZ) );

BTN_IN  BTN_IN ( .CLK(CLK), .RST(RST), .BIN(BTN),
                 .BOUT({MODE, SELECT, ADJUST}) );

SECCNT   SEC ( .CLK(CLK), .RST(RST), .EN(EN1HZ), .CLR(SECCLR),
               .QH(SECH), .QL(SECL), .CA(CASEC) );

MINCNT   MIN ( .CLK(CLK), .RST(RST), .EN(CASEC), .INC(MININC),
               .QH(MINH), .QL(MINL), .CA(CAMIN) );

HOURCNT HOUR ( .CLK(CLK), .RST(RST), .EN(CAMIN), .INC(HOURINC),
               .MODE24(MODE24), .QH(HOURH),.QL(HOURL) );

STATE  STATE ( .CLK(CLK), .RST(RST), .SIG2HZ(SIG2HZ),
               .MODE(MODE),     .SELECT(SELECT), .ADJUST(ADJUST),
               .SECCLR(SECCLR), .MININC(MININC), .HOURINC(HOURINC),
               .SECON(SECON),   .MINON(MINON),   .HOURON(HOURON),
               .MODE24(MODE24) );

/* 時桁、分桁の表示 */
LEDDISP LEDDISP( .CLK(CLK), .RST(RST),
    .nSEG(nSEG), .nAN(nAN),
    .DIG3({2'b00, HOURH}), .DIG2(HOURL), .DIG1({1'b0, MINH}), .DIG0(MINL),
    .DP({2'b01, T_SIG, T_SIG}), .EN({H10EN, HOURON, MINON, MINON}) );

/* 秒桁の表示 */
assign LED[3:0] = (SECON==1'b1) ? SECL: 4'h0;
assign LED[6:4] = (SECON==1'b1) ? SECH: 3'h0;
assign LED[7]   = MODE24; /* MODE24信号を単体LEDの一番左に表示 */

endmodule
