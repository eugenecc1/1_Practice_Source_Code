/* ダイナミック点灯方式による7セグメントLED表示     */
/* Copyright(C) 2013 Cobac.Net All Rights Reserved. */

module LEDDISP(
    input   CLK, RST,
    output  reg [7:0]   nSEG,
    output  reg [3:0]   nAN = 4'b1110,  /* 初期値を設定 */
    input       [3:0]   DIG3, DIG2, DIG1, DIG0,
    input       [3:0]   DP, EN
);

/* 50MHzから500Hzのイネーブル信号を作成 */
reg [16:0]  cnt500;
parameter CNTMAX = 17'd100000 - 1; /* カウンタの最大値 */
wire    en500 = (cnt500==CNTMAX);

always @( posedge CLK ) begin
    if ( RST )
        cnt500 <= 17'h0;
    else if ( en500 )
        cnt500 <= 17'h0;
    else
        cnt500 <= cnt500 + 17'h1;
end

/* 7セグメント表示デコーダ              */
/* 各セグメントはgfedcbaの並びで0で点灯 */
function [6:0] segdec;
input   [3:0]   din;
input           en;
    if ( en )
        case ( din )
            4'h0:   segdec = 7'b1000000;
            4'h1:   segdec = 7'b1111001;
            4'h2:   segdec = 7'b0100100;
            4'h3:   segdec = 7'b0110000;
            4'h4:   segdec = 7'b0011001;
            4'h5:   segdec = 7'b0010010;
            4'h6:   segdec = 7'b0000010;
            4'h7:   segdec = 7'b1011000;
            4'h8:   segdec = 7'b0000000;
            4'h9:   segdec = 7'b0010000;
            4'ha:   segdec = 7'b0001000;
            4'hb:   segdec = 7'b0000011;
            4'hc:   segdec = 7'b1000110;
            4'hd:   segdec = 7'b0100001;
            4'he:   segdec = 7'b0000110;
            4'hf:   segdec = 7'b0001110;
            default:segdec = 7'bxxxxxxx;
        endcase
    else
        segdec = 7'b1111111;
endfunction

/* コモン信号作成 */
always @( posedge CLK ) begin
    if ( RST )
        nAN <= 4'b1110;
    else if ( en500 )
        nAN <= {nAN[2:0], nAN[3]};
end

/* セグメント信号生成 */
always @* begin
    case ( nAN )
        4'b1110:  nSEG = {~DP[0], segdec(DIG0, EN[0])};
        4'b1101:  nSEG = {~DP[1], segdec(DIG1, EN[1])};
        4'b1011:  nSEG = {~DP[2], segdec(DIG2, EN[2])};
        4'b0111:  nSEG = {~DP[3], segdec(DIG3, EN[3])};
        default:  nSEG = 8'hxx;
    endcase
end

endmodule
