/* 自作パラレルI/O                                   */
/* Copyright(C) 2013 Cobac.Net, All rights reserved. */

module MYPIO(
    input           CLK, RST,
    input   [31:0]  IO_Address,
    input           IO_Addr_Strobe,
    input    [3:0]  IO_Byte_Enable,
    input   [31:0]  IO_Write_Data,
    input           IO_Write_Strobe,
    output  [31:0]  IO_Read_Data,
    input           IO_Read_Strobe,
    output  reg     IO_Ready,
    input           [3:0]   SW,
    output  reg     [7:0]   nSEG
);

parameter nSEG_ADDR = 32'hc000_0000;

/* 出力レジスタ */
wire write_en = (IO_Address==nSEG_ADDR) & IO_Byte_Enable[0] &
                 IO_Addr_Strobe & IO_Write_Strobe;

always @( posedge CLK ) begin
    if ( RST )
        nSEG <= 8'h0;
    else if ( write_en )
        nSEG <= IO_Write_Data[7:0];
end

/* 入力レジスタ */
assign IO_Read_Data = (IO_Address==nSEG_ADDR) ? {24'b0, nSEG}:
                                                {28'b0, SW};

/* IO_Ready */
always @( posedge CLK ) begin
    if ( RST )
        IO_Ready <= 1'b0;
    else
        IO_Ready <= IO_Addr_Strobe &
                   (IO_Write_Strobe | IO_Read_Strobe);
end

endmodule
