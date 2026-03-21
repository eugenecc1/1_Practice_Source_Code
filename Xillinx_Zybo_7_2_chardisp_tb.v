/* Copyright(C) 2020 Cobac.Net All Rights Reserved. */
/* chapter: 第7章                      */
/* project: chardisp                   */
/* outline: 文字表示回路のテストベンチ */

module chardisp_tb;

/* クロック周期とSimクロック数を定義 */
localparam STEP = 10;
localparam CLKNUM = (800*525+12000)*4;

/* 接続信号の宣言 */
reg             CLK, RST;
reg     [15:0]  RDADDR;
reg     [15:0]  WRADDR;
reg     [3:0]   BYTEEN;
reg             WREN, RDEN;
reg     [31:0]  WRDATA;
wire    [31:0]  RDDATA;
wire    [3:0]   VGA_R, VGA_G, VGA_B;
wire            VGA_HS, VGA_VS, VGA_DE;
wire            PCK;

/* 文字表示回路本体の接続 */
chardisp chardisp(
    .CLK        (CLK),
    .RST        (RST),
    .WRADDR     (WRADDR),
    .BYTEEN     (BYTEEN),
    .WREN       (WREN),
    .WRDATA     (WRDATA),
    .RDADDR     (RDADDR),
    .RDEN       (RDEN),
    .RDDATA     (RDDATA),
    .PCK        (PCK),
    .VGA_R      (VGA_R),
    .VGA_G      (VGA_G),
    .VGA_B      (VGA_B),
    .VGA_HS     (VGA_HS),
    .VGA_VS     (VGA_VS),
    .VGA_DE     (VGA_DE)
);

/* クロックの生成 */
always begin
    CLK = 0; #(STEP/2);
    CLK = 1; #(STEP/2);
end

/* VRAMへの書き込みをするタスク */
task write_vram;
    input   [15:0]  wraddr;
    input   [3:0]   byteen;
    input   [23:0]  wrdata;
begin
    WRADDR = wraddr;
    BYTEEN = byteen;
    WRDATA = wrdata;
    WREN   = 1;
    #STEP;
    WREN   = 0;
    #STEP;
end
endtask

/* 各種変数 */
integer fd, i;

/* 検証対象への入力を作成 */
initial begin
    RST = 0; WRADDR = 0; BYTEEN = 0; WRDATA = 0; WREN = 0;
    RDADDR = 0; RDEN = 0;
    fd = $fopen("imagedata.raw", "wb");
    #(STEP*500) RST = 1;
    #(STEP*10)  RST = 0;
    /* VRAMに各色で各文字を書き込む */
    for ( i=0; i<4000; i=i+1 )
        write_vram(i<<2, 4'hf, (i<<8) | (8'hff & i));
    #(STEP*CLKNUM);
    $fclose(fd);
    $stop;
end

/* ファイル出力 */
always @(posedge PCK) begin
    if ( VGA_DE ) begin
        $fwrite(fd, "%c", {VGA_R, VGA_R});
        $fwrite(fd, "%c", {VGA_G, VGA_G});
        $fwrite(fd, "%c", {VGA_B, VGA_B});
    end
end

endmodule
