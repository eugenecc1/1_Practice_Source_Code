/* Copyright(C) 2020 Cobac.Net All Rights Reserved. */
/* chapter: 第2章課題                            */
/* project: blinkpat                             */
/* outline: プッシュSWで色のパターンを切り替える */

module blinkpat (
    input               CLK,
    input               RST,
    input       [0:0]   BTN,
    output  reg [2:0]   LED_RGB
);

/* チャタリング除去回路を接続 */
wire btnon;

debounce d0 (.CLK(CLK), .RST(RST), .BTNIN(BTN), .BTNOUT(btnon));

/* 色パターン切り替え信号 */
reg colpat;

always @( posedge CLK ) begin
    if ( RST )
        colpat <= 1'b0;
    else if ( btnon )
        colpat <= ~colpat;
end

/* システムクロックを分周 */
reg [25:0] cnt26;

always @( posedge CLK ) begin
    if ( RST )
        cnt26 <= 26'h0;
    else
        cnt26 <= cnt26 + 26'h1;
end

wire ledcnten = (cnt26==26'h3ffffff);

/* LED用5進カウンタ */
reg [2:0] cnt3;

always @( posedge CLK ) begin
    if ( RST )
        cnt3 <= 3'h0;
    else if ( ledcnten )
        if ( cnt3==3'd4)
            cnt3 <=3'h0;
        else
            cnt3 <= cnt3 + 3'h1;
end

/* 色のパターンを切り替え */
wire [2:0] col0 = (colpat==1'b0) ? 3'b100: 3'b110;
wire [2:0] col1 = (colpat==1'b0) ? 3'b010: 3'b011;
wire [2:0] col2 = (colpat==1'b0) ? 3'b001: 3'b101;

/* LEDデコーダ */
always @* begin
    case ( cnt3 )
        3'd0:   LED_RGB = col0;
        3'd1:   LED_RGB = col1;
        3'd2:   LED_RGB = col2;
        3'd3:   LED_RGB = 3'b111;
        3'd4:   LED_RGB = 3'b000;
        default:LED_RGB = 3'b000;
    endcase
end

endmodule
