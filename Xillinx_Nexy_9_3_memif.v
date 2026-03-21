/* Cellular RAMインターフェース                     */
/* Copyright(C) 2013 Cobac.Net All Rights Reserved. */

module MEMIF(
    input   CLK, RST,
    /* メモリ端子 */
    output  reg [23:1]  MEMADDR,
    inout       [15:0]  MEMDQ,
    output  reg         MEMnOE, MEMnWE, MEMnUB, MEMnLB,
    /* I/Oバス */
    input       [31:0]  IO_Address, IO_Write_Data,
    input       [3:0]   IO_Byte_Enable,
    input               IO_Addr_Strobe, IO_Read_Strobe,
    /* バス・インターフェース */
    input               WRMEM,  WRREG,
    output      [31:0]  RDATA0, RDATA1,
    output              MEMIORDY,
    /* グラフィック表示回路 */
    input       [23:1]  DMEMADDR,
    /* キャプチャ回路 */
    input       [23:1]  CMEMADDR,
    input       [15:0]  CMEMDOUT,
    input               CMEMnWE_asrt, CMEMnWE_deas,
    /* MODE信号のLED表示用 */
    output  reg [1:0]   MODE
);

/* メモリアクセス・モード設定レジスタ */
parameter DISPMODE=2'b00, CAPTMODE=2'b01, MCSMODE=2'b10;

always @( posedge CLK ) begin
    if ( RST )
        MODE <= 2'h0;
    else if ( WRREG & IO_Byte_Enable[0] )
        MODE <= IO_Write_Data[1:0];
end

assign RDATA1 = {30'b0, MODE};

/* メモリ読み出し信号 */
wire RDMEM = (IO_Address[31:24]==8'hc0) & IO_Addr_Strobe & IO_Read_Strobe;

/* MCSモード時のメモリ信号 */
reg  [23:1]  MMEMADDR;
reg          MMEMnOE, MMEMnWE, MMEMnUB, MMEMnLB;

/* メモリ信号切り替え */
always @* begin
    case ( MODE )
        DISPMODE:   begin
                        MEMADDR = DMEMADDR;
                        MEMnOE  = 1'b0;
                        MEMnUB  = 1'b0;
                        MEMnLB  = 1'b0;
                    end
        CAPTMODE:   begin
                        MEMADDR = CMEMADDR;
                        MEMnOE  = 1'b1;
                        MEMnUB  = 1'b0;
                        MEMnLB  = 1'b0;
                    end
        MCSMODE:    begin
                        MEMADDR = MMEMADDR;
                        MEMnOE  = MMEMnOE;
                        MEMnUB  = MMEMnUB;
                        MEMnLB  = MMEMnLB;
                    end
        default:    begin
                        MEMADDR = 23'b0;
                        MEMnOE  = 1'b1;
                        MEMnUB  = 1'b1;
                        MEMnLB  = 1'b1;
                    end
    endcase
end

/* ReadおよびWriteの状態信号 */
reg [3:0]   status;

parameter HALT=4'd0,   WRLOW=4'd1, FIRSTRD=4'd4, CHGADDR=4'd5,
          WRHIGH=4'd6, IORDY=4'd9, RDWREND=4'd10;

always @( posedge CLK ) begin
    if ( RST )
        status <= HALT;
    else if ( WRMEM | RDMEM )
        status <= 4'd1;
    else if ( status!=HALT )
        if ( status == RDWREND )
            status <= HALT;
        else
            status <= status + 1'd1;
end

assign MEMIORDY = (status==IORDY);

/* 読み出しデータ */
reg [15:0]  rdata_low;

always @( posedge CLK ) begin
    if ( RST )
        rdata_low <= 16'h0;
    else if ( status==FIRSTRD )
        rdata_low <= MEMDQ;
end

assign RDATA0 = {MEMDQ, rdata_low};

/* 書き込みデータ */
reg [15:0] wrdata;

always @( posedge CLK ) begin
    if ( RST )
        wrdata <= 16'h0;
    else if ( WRMEM )
        wrdata <= IO_Write_Data[15:0];
    else if ( status==CHGADDR )
        wrdata <= IO_Write_Data[31:16];
end

/* 書き込み信号およびトライステート制御 */
reg writemode;

always @( posedge CLK ) begin
    if ( RST )
        writemode <= 1'b0;
    else if ( WRMEM )
        writemode <= 1'b1;
    else if ( status == RDWREND )
        writemode <= 1'b0;
end

assign MEMDQ = (writemode && MODE==MCSMODE)  ? wrdata: 
                            (MODE==CAPTMODE) ? CMEMDOUT: 16'hzzzz;

/* MCSモード時のMEMnLB, MEMnUB信号                  */
/* Read時：ともに0、Write時：IO_Byte_Enableを反映 */
always @( posedge CLK ) begin
    if ( RST )
        {MMEMnUB, MMEMnLB} <= 2'b11;
    else if ( RDMEM )
        {MMEMnUB, MMEMnLB} <= 2'b00;
    else if ( WRMEM )
        {MMEMnUB, MMEMnLB} <= ~IO_Byte_Enable[1:0];
    else if ( writemode & (status==CHGADDR) )
        {MMEMnUB, MMEMnLB} <= ~IO_Byte_Enable[3:2];
    else if ( status == RDWREND )
        {MMEMnUB, MMEMnLB} <= 2'b11;
end

/* MCSモード時のMEMADDR */
always @( posedge CLK ) begin
    if ( RST )
        MMEMADDR <= 23'b0;
    else if ( WRMEM | RDMEM )
        MMEMADDR <= {IO_Address[23:2], 1'b0};
    else if ( status==CHGADDR )
        MMEMADDR <= {IO_Address[23:2], 1'b1};
end

/* MCSモード時のMEMnOE */
always @( posedge CLK ) begin
    if ( RST )
        MMEMnOE <= 1'b1;
    else if ( RDMEM )
        MMEMnOE <= 1'b0;
    else if ( status == RDWREND )
        MMEMnOE <= 1'b1;
end

/* MEMnWE */
always @( posedge CLK ) begin
    if ( RST )
        MEMnWE <= 1'b1;
    else if ( MODE==CAPTMODE ) begin
        if ( CMEMnWE_asrt )
            MEMnWE <= 1'b0;
        else if ( CMEMnWE_deas )
            MEMnWE <= 1'b1;
    end
    else if ( MODE==MCSMODE ) begin
        if ( writemode & (status==WRLOW || status==WRHIGH)  )
            MEMnWE <= 1'b0;
        else if ( status==FIRSTRD || status==IORDY )
            MEMnWE <= 1'b1;
    end
    else
        MEMnWE <= 1'b1;
end

endmodule
