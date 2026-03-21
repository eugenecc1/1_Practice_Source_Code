/* Copyright(C) 2020 Cobac.Net All Rights Reserved. */
/* chapter: 第9章                                */
/* project: display                              */
/* outline: グラフィック表示回路IPのテストベンチ */

`timescale 1ns/1ps

import axi_vip_pkg::*;
import design_1_axi_vip_0_0_pkg::*;

module disp_ip_tb;

/* 接続信号の宣言 */
logic ACLK;
logic ARESETN;
logic [7:0]     VGA_R,  VGA_G,  VGA_B;
logic           VGA_HS, VGA_VS, VGA_DE;
logic [29:0]    DISPADDR;
logic           PCK, DISPON, VBLANK, CLRVBLNK;
logic           FIFO_OVER, FIFO_UNDER;

/* 検証対象の接続 */
design_1_wrapper dut (.*);

/* クロックの生成 */
localparam integer STEP  = 10;
localparam CLKNUM = (800*525+12000)*4;

always begin
    ACLK = 0; #(STEP/2);
    ACLK = 1; #(STEP/2);
end

/* VRAMの先頭アドレス */
localparam MEMBASE = 32'h1000_0000;

/* テストベンチ本体 */
integer fd;

initial begin
    fd = $fopen("imagedata.raw", "wb");
    ARESETN = 1;
    DISPON = 0;
    DISPADDR = MEMBASE;
    CLRVBLNK = 0;
    #(STEP*200) ARESETN = 0;
    #(STEP*20)  ARESETN = 1;
    #(STEP*20)  DISPON  = 1;
    #(STEP*CLKNUM);
    $fclose(fd);
    $stop;
end

/* ファイル出力 */
always @(posedge PCK) begin
    if ( VGA_DE ) begin
        $fwrite(fd, "%c", VGA_R);
        $fwrite(fd, "%c", VGA_G);
        $fwrite(fd, "%c", VGA_B);
    end
end

/* VIP Slave用のエージェントを宣言しスレーブを起動 */
design_1_axi_vip_0_0_slv_mem_t agent;

initial begin
    agent = new("AXI Slave Agent", dut.design_1_i.axi_vip_0.inst.IF);
    agent.start_slave();
    meminit_incr();
end

/* 初期値0で1画素ごとに+1したデータを書く */
task meminit_incr();
begin
    for( integer i=0; i<640*480; i++ ) begin
        agent.mem_model.backdoor_memory_write_4byte
                                        ( MEMBASE+i*4, i, 4'b1111 );
    end
end
endtask

endmodule
