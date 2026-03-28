/* プッシュボタンのチャタリング除去                 */
/* Copyright(C) 2013 Cobac.Net All Rights Reserved. */

module BTN_IN (
    input   CLK, RST,
    input       [2:0]   BIN,
    output reg  [2:0]   BOUT
);

/* 50MHzを1250000分周して40Hzを作る              */
/* en40hzはシステムクロック1周期分のパルスで40Hz */
reg [20:0] cnt;

wire en40hz = (cnt==1250000-1);

always @( posedge CLK ) begin
    if ( RST )
        cnt <= 21'b0;
    else if ( en40hz )
        cnt <= 21'b0;
    else
        cnt <= cnt + 21'b1;
end


/*  ボタン入力をFF2個で受ける*/
reg [2:0] ff1, ff2;

always @( posedge CLK ) begin
    if ( RST ) begin
        ff2 <=3'b0;
        ff1 <=3'b0;
    end
    else if ( en40hz ) begin
        ff2 <= ff1;
        ff1 <= BIN;
    end
end

/* ボタンは押すと1なので、立上がりを検出 */
wire [2:0] temp = ff1 & ~ff2 & {3{en40hz}};


/* 念のためFFで受ける */
always @( posedge CLK ) begin
    if ( RST )
        BOUT <=3'b0;
    else
        BOUT <=temp;
end

endmodule
