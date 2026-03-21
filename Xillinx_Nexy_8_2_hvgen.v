/* HVカウンタ                                       */
/* Copyright(C) 2013 Cobac.Net All rights reserved. */

module HVGEN(
    input           CLK, RST,
    output  reg     PCK, VGA_HS, VGA_VS,
    output  reg [9:0]   HCNT,
    output  reg [9:0]   VCNT
);

/* ピクセルクロック(25MHz) */
always @( posedge CLK ) begin
    if ( RST )
        PCK <= 1'b0;
    else
        PCK <= ~PCK;
end

/* 水平カウンタ */
parameter HMAX = 800;
wire hcntend = (HCNT==HMAX-10'h001);

always @( posedge PCK ) begin
    if ( RST )
        HCNT <= 10'h000;
    else if ( hcntend )
        HCNT <= 10'h000;
    else
        HCNT <= HCNT + 10'h001;
end

/* 垂直カウンタ */
parameter VMAX = 525;

always @( posedge PCK ) begin
    if ( RST )
        VCNT <= 10'h000;
    else if ( hcntend ) begin
        if ( VCNT==VMAX-10'h001 )
            VCNT <= 10'h000;
        else
            VCNT <= VCNT + 10'h001;
    end
end

/* 同期信号 */
parameter HSSTART = 663;
parameter HSEND   = 759;
parameter VSSTART = 449;
parameter VSEND   = 451;

always @( posedge PCK ) begin
    if ( RST )
        VGA_HS <= 1'b1;
    else if ( HCNT==HSSTART )
        VGA_HS <= 1'b0;
    else if ( HCNT==HSEND )
        VGA_HS <= 1'b1;
end

always @( posedge PCK ) begin
    if ( RST )
        VGA_VS <= 1'b1;
    else if ( HCNT==HSSTART ) begin
        if ( VCNT==VSSTART )
            VGA_VS <= 1'b0;
        else if ( VCNT==VSEND )
            VGA_VS <= 1'b1;
    end
end

endmodule
