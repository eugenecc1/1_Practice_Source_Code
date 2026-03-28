/* 60進カウンタを2つ並べて1時間計を作る             */
/* Copyright(C) 2013 Cobac.Net All Rights Reserved. */

module CLOCK1(
    input   CLK100, RST,
    input   [2:0]   BTN,
    output  [7:0]   nSEG,
    output  [3:0]   nAN
);

/* CLK(50MHz)の作成 */
reg CLK;

always @( posedge CLK100 ) begin
    CLK <= ~CLK;
end

/* スイッチ入力回路の接続 */
wire    clr, minup, secup;
BTN_IN BTN_IN( .CLK(CLK), .RST(RST),
               .BIN(BTN), .BOUT({clr, minup, secup}) );

/* 1Hzイネーブル回路の接続 */
wire    en1hz;
CNT1SEC CNT1SEC( .CLK(CLK), .RST(RST), .EN1HZ(en1hz));

/* 60進カウンタの接続 */
wire    [3:0]   min1,  sec1;
wire    [2:0]   min10, sec10;
wire    cout, dummy;

CNT60 SECCNT( .CLK(CLK),   .RST(RST),  .CLR(clr), .EN(en1hz),
              .INC(secup), .QH(sec10), .QL(sec1), .CA(cout) );
CNT60 MINCNT( .CLK(CLK),   .RST(RST),  .CLR(clr), .EN(cout),
              .INC(minup), .QH(min10), .QL(min1), .CA(dummy));

/* 7セグメントデコーダの接続 */
LEDDISP LEDDISP( .CLK(CLK), .RST(RST), .nSEG(nSEG), .nAN(nAN),
    .DIG3({1'b0, min10}), .DIG2(min1),
    .DIG1({1'b0, sec10}), .DIG0(sec1),
    .DP(4'b0100), .EN(4'b1111) );

endmodule
