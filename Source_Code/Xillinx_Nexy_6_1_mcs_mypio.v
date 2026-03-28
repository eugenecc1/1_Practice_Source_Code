/* ©ìƒpƒ‰ƒŒƒ‹I/O‚ğÚ‘±‚µ‚½ÅãˆÊŠK‘w               */
/* Copyright(C) 2013 Cobac.Net, All rights reserved. */

module MCS_MYPIO(
    input           CLK100, RST,
    input   [3:0]   SW,
    output  [7:0]   nSEG,
    output  [3:0]   nAN,
    output          TXD
);

assign nAN = 4'b1110;

/* CLK(50MHz)‚Ìì¬ */
reg CLK;

always @( posedge CLK100 ) begin
    CLK <= ~CLK;
end

wire [31:0] IO_Address, IO_Write_Data, IO_Read_Data;
wire [3:0]  IO_Byte_Enable;
wire        IO_Addr_Strobe, IO_Read_Strobe, IO_Write_Strobe;
wire        IO_Ready;

mcs mcs_0 (
    .Clk            (CLK),
    .Reset          (RST),
    .IO_Address     (IO_Address),
    .IO_Addr_Strobe (IO_Addr_Strobe),
    .IO_Byte_Enable (IO_Byte_Enable),
    .IO_Write_Data  (IO_Write_Data),
    .IO_Write_Strobe(IO_Write_Strobe),
    .IO_Read_Data   (IO_Read_Data),
    .IO_Read_Strobe (IO_Read_Strobe),
    .IO_Ready       (IO_Ready),
    .UART_Tx        (TXD)
);

MYPIO MYPIO (
    .CLK            (CLK),
    .RST            (RST),
    .IO_Address     (IO_Address),
    .IO_Addr_Strobe (IO_Addr_Strobe),
    .IO_Byte_Enable (IO_Byte_Enable),
    .IO_Write_Data  (IO_Write_Data),
    .IO_Write_Strobe(IO_Write_Strobe),
    .IO_Read_Data   (IO_Read_Data),
    .IO_Read_Strobe (IO_Read_Strobe),
    .IO_Ready       (IO_Ready),
    .SW             (SW),
    .nSEG           (nSEG)
);

endmodule
