/* VGA文字表示回路の最上位階層                      */
/* Copyright(C) 2013 Cobac.Net All Rights Reserved. */

module VGA(
    input   CLK100, RST,
    output  [7:0]   nSEG,
    output  [3:0]   nAN,
    output  [2:0]   VGA_R, VGA_G,
    output  [1:0]   VGA_B,
    output  VGA_HS, VGA_VS,
    output  TXD
);

/* CLK(50MHz)の作成 */
reg CLK;

always @( posedge CLK100 ) begin
    CLK <= ~CLK;
end

/* 7セグメントLED出力の固定 */
assign nSEG = 8'hff;
assign nAN  = 4'hf;

/* 内部信号宣言 */
wire [31:0] IO_Address, IO_Write_Data, IO_Read_Data;
wire [3:0]  IO_Byte_Enable;
wire        IO_Addr_Strobe, IO_Read_Strobe, IO_Write_Strobe;
wire        IO_Ready;
wire [31:0] RDATA4;
wire [7:0]  WR;

/* バンク番号の設定 */
parameter CELLRAM=3'h0, MEMMODE=3'h1, LEDBANK=3'h2, PS2BANK=3'h3,
          VGABANK=3'h4,   GRAPH=3'h5,  CAMPIC=3'h6, CAMCTRL=3'h7;

/* 各モジュールの接続 */
mcs mcs_0 (
    .Clk            (CLK),
    .Reset          (RST),
    .IO_Addr_Strobe (IO_Addr_Strobe),
    .IO_Read_Strobe (IO_Read_Strobe),
    .IO_Write_Strobe(IO_Write_Strobe),
    .IO_Address     (IO_Address),
    .IO_Byte_Enable (IO_Byte_Enable),
    .IO_Write_Data  (IO_Write_Data),
    .IO_Read_Data   (IO_Read_Data),
    .IO_Ready       (IO_Ready),
    .UART_Tx        (TXD)
);

BUSIF BUSIF(
    .CLK            (CLK),
    .RST            (RST),
    .IO_Address     (IO_Address),
    .IO_Read_Data   (IO_Read_Data),
    .IO_Addr_Strobe (IO_Addr_Strobe),
    .IO_Read_Strobe (IO_Read_Strobe),
    .IO_Write_Strobe(IO_Write_Strobe),
    .IO_Ready       (IO_Ready),
    .WR             (WR),
    .RDATA4         (RDATA4), 
    .RDATA0(32'b0), .RDATA1(32'b0),
    .RDATA2(32'b0), .RDATA3(32'b0), 
                    .RDATA5(32'b0),
    .RDATA6(32'b0), .RDATA7(32'b0),
    .MEMIORDY       (1'b0)
);

VGAIF VGAIF(
    .CLK            (CLK),
    .RST            (RST),
    .IO_Address     (IO_Address),
    .IO_Write_Data  (IO_Write_Data),
    .WR             (WR[VGABANK]),
    .RDATA          (RDATA4),
    .VGA_R          (VGA_R),
    .VGA_G          (VGA_G),
    .VGA_B          (VGA_B),
    .VGA_HS         (VGA_HS),
    .VGA_VS         (VGA_VS)
);

endmodule
