/* Copyright(C) 2020 Cobac.Net All Rights Reserved.    */
/* chapter: 第8章                                      */
/* project: axisim                                     */
/* outline: AR#37425マスターとVIPスレーブを接続してSim */

`timescale 1ns/1ps

import axi_vip_pkg::*;
import design_1_axi_vip_0_0_pkg::*;

module axisim_tb;

/* 接続信号の宣言 */
logic ACLK, ARESETN, ERROR;

/* 検証対象の接続 */
design_1_wrapper dut (.*);

/* クロックの生成 */
localparam integer STEP  = 10;

always begin
    ACLK = 0; #(STEP/2);
    ACLK = 1; #(STEP/2);
end

/* 検証対象への入力を作成 */
initial begin
    ARESETN = 1;
    #(STEP*5);
    ARESETN = 0;
    #(STEP*20);
    ARESETN = 1;
    #(STEP*500);
    $stop;
end

/* VIP Slave用のエージェントを宣言し起動 */
design_1_axi_vip_0_0_slv_mem_t agent;

initial begin
    agent = new("AXI Slave Agent", dut.design_1_i.axi_vip_0.inst.IF);
    agent.start_slave();
end

endmodule
