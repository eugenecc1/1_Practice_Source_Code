/* スライドスイッチ入力による7セグメントLED表示     */
/* Copyright(C) 2013 Cobac.Net All Rights Reserved. */

module SEG7DEC(
    input       [3:0]   SW,
    output  reg [7:0]   nSEG,
    output      [3:0]   nAN
);

/* コモン端子の固定 */
assign nAN = 4'b1110;

/* 7セグメント表示デコーダ              */
/* 各セグメントはgfedcbaの並びで0で点灯 */
always @* begin
    case ( SW )
        4'h0:   nSEG = 8'b11000000;
        4'h1:   nSEG = 8'b11111001;
        4'h2:   nSEG = 8'b10100100;
        4'h3:   nSEG = 8'b10110000;
        4'h4:   nSEG = 8'b10011001;
        4'h5:   nSEG = 8'b10010010;
        4'h6:   nSEG = 8'b10000010;
        4'h7:   nSEG = 8'b11011000;
        4'h8:   nSEG = 8'b10000000;
        4'h9:   nSEG = 8'b10010000;
        4'ha:   nSEG = 8'b10001000;
        4'hb:   nSEG = 8'b10000011;
        4'hc:   nSEG = 8'b11000110;
        4'hd:   nSEG = 8'b10100001;
        4'he:   nSEG = 8'b10000110;
        4'hf:   nSEG = 8'b10001110;
        default:nSEG = 8'bxxxxxxxx;
    endcase
end

endmodule
