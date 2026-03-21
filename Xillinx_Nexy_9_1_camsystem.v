/* カメラシステムの最上位階層                       */
/* Copyright(C) 2013 Cobac.Net All rights reserved. */

module CAMSYSTEM(
    input   CLK100, RST,
    output  [7:0]   nSEG,
    output  [3:0]   nAN,
    output  [23:1]  MEMADDR,
    inout   [15:0]  MEMDQ,
    output          MEMnOE,  MEMnWE, MEMnCS, MEMnUB, MEMnLB,
    output          MEMnADV, MEMCLK, MEMCRE,
    output  [2:0]   VGA_R, VGA_G,
    output  [1:0]   VGA_B,
    output          VGA_HS, VGA_VS,
    output          TXD,
    output  [7:0]   LED,
    input           PCLK,
    input           HREF,
    input           VSYNC,
    output          XCLK,
    output          SCL,
    output          SDA,
    input   [7:0]   CAMDATA
);

/* CLK(50MHz)の作成 */
reg CLK;

always @( posedge CLK100 ) begin
    CLK <= ~CLK;
end

/* 7セグメントLED出力の固定 */
assign nSEG = 8'hff;
assign nAN  = 4'hf;

/* 端子の固定 */
assign MEMnCS   = 1'b0;
assign MEMnADV  = 1'b0;
assign MEMCLK   = 1'b0;
assign MEMCRE   = 1'b0;

/* 内部信号宣言 */
wire [31:0] IO_Address, IO_Write_Data, IO_Read_Data;
wire [3:0]  IO_Byte_Enable;
wire        IO_Addr_Strobe, IO_Read_Strobe, IO_Write_Strobe;
wire        IO_Ready;
wire [7:0]  WR;
wire [31:0] RDATA0, RDATA1, RDATA2, RDATA3,
            RDATA4, RDATA5, RDATA6, RDATA7;
wire        MEMIORDY;
wire [23:1] DMEMADDR, CMEMADDR;
wire [15:0] CMEMDOUT;
wire        CMEMnWE_asrt, CMEMnWE_deas;

/* MODE信号を単体LEDに表示 */
wire [1:0]  MODE;
assign LED[1:0] = MODE;

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
    .RDATA0         (RDATA0),
    .RDATA1         (RDATA1),
    .RDATA5         (RDATA5),
    .RDATA6         (RDATA6),
    .RDATA7         (RDATA7),
    .RDATA2(32'b0), .RDATA3(32'b0), 
    .RDATA4(32'b0),
    .MEMIORDY       (MEMIORDY)
);

DISPCTRL DISPCTRL(
    .CLK            (CLK),
    .RST            (RST),
    .IO_Address     (IO_Address),
    .IO_Byte_Enable (IO_Byte_Enable),
    .IO_Write_Data  (IO_Write_Data),
    .RDATA          (RDATA5),
    .WR             (WR[GRAPH]),
    .DMEMADDR       (DMEMADDR),
    .DMEMDIN        (MEMDQ),
    .MODE           (MODE),
    .VGA_R          (VGA_R),
    .VGA_G          (VGA_G),
    .VGA_B          (VGA_B),
    .VGA_HS         (VGA_HS),
    .VGA_VS         (VGA_VS),
    .OVFLAG         (/* 未接続 */),
    .UFFLAG         (/* 未接続 */)
);

MEMIF MEMIF(
    .CLK            (CLK),
    .RST            (RST),
    .MEMADDR        (MEMADDR),
    .MEMDQ          (MEMDQ),
    .MEMnOE         (MEMnOE),
    .MEMnWE         (MEMnWE),
    .MEMnUB         (MEMnUB),
    .MEMnLB         (MEMnLB),
    .IO_Address     (IO_Address),
    .IO_Write_Data  (IO_Write_Data),
    .IO_Byte_Enable (IO_Byte_Enable),
    .IO_Addr_Strobe (IO_Addr_Strobe), 
    .IO_Read_Strobe (IO_Read_Strobe),
    .WRMEM          (WR[CELLRAM]),
    .WRREG          (WR[MEMMODE]),
    .RDATA0         (RDATA0),
    .RDATA1         (RDATA1),
    .MEMIORDY       (MEMIORDY),
    .DMEMADDR       (DMEMADDR),
    .CMEMADDR       (CMEMADDR),
    .CMEMDOUT       (CMEMDOUT),
    .CMEMnWE_asrt   (CMEMnWE_asrt),
    .CMEMnWE_deas   (CMEMnWE_deas),
    .MODE           (MODE)
);

CAPTURE CAPTURE(
    .CLK            (CLK),
    .RST            (RST),
    .IO_Address     (IO_Address),
    .IO_Byte_Enable (IO_Byte_Enable),
    .IO_Write_Data  (IO_Write_Data),
    .RDATA          (RDATA6),
    .WR             (WR[CAMPIC]),
    .CMEMADDR       (CMEMADDR),
    .CMEMDOUT       (CMEMDOUT),
    .CMEMnWE_asrt   (CMEMnWE_asrt),
    .CMEMnWE_deas   (CMEMnWE_deas),
    .PCLK           (PCLK),
    .HREF           (HREF),
    .VSYNC          (VSYNC),
    .XCLK           (XCLK),
    .CAMDATA        (CAMDATA),
    .OVFLAG         (LED[3]),
    .UFFLAG         (LED[2]),
    .empty          (LED[4]),
    .STATE          (LED[7:5])
);

SCCB SCCB(
    .CLK            (CLK),
    .RST            (RST),
    .IO_Address     (IO_Address),
    .IO_Byte_Enable (IO_Byte_Enable),
    .IO_Write_Data  (IO_Write_Data),
    .RDATA          (RDATA7),
    .WR             (WR[CAMCTRL]),
    .SCL            (SCL),
    .SDA            (SDA)
);

endmodule
