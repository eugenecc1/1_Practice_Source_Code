/* Copyright(C) 2020 Cobac.Net All Rights Reserved. */
/* chapter: 第9章                          */
/* project: display                        */
/* outline: グラフィック表示回路最上位階層 */

module display #
  (
    parameter integer C_M_AXI_THREAD_ID_WIDTH = 1,
    parameter integer C_M_AXI_ADDR_WIDTH      = 32,
    parameter integer C_M_AXI_DATA_WIDTH      = 64
   )
  (
    // System Signals
    input wire        ACLK,
    input wire        ARESETN,

    // Master Interface Write Address
    input  wire                                  M_AXI_AWREADY,
    output wire                                  M_AXI_AWVALID,
    output wire [C_M_AXI_ADDR_WIDTH-1:0]         M_AXI_AWADDR,
    output wire [8-1:0]                          M_AXI_AWLEN,
    output wire [3-1:0]                          M_AXI_AWSIZE,
    output wire [2-1:0]                          M_AXI_AWBURST,
    output wire                                  M_AXI_AWLOCK,
    output wire [4-1:0]                          M_AXI_AWCACHE,
    output wire [3-1:0]                          M_AXI_AWPROT,
    output wire [4-1:0]                          M_AXI_AWQOS,
    output wire                                  M_AXI_AWUSER,
    output wire [C_M_AXI_THREAD_ID_WIDTH-1:0]    M_AXI_AWID,

    // Master Interface Write Data
    input  wire                                  M_AXI_WREADY,
    output wire                                  M_AXI_WVALID,
    output wire [C_M_AXI_DATA_WIDTH-1:0]         M_AXI_WDATA,
    output wire [C_M_AXI_DATA_WIDTH/8-1:0]       M_AXI_WSTRB,
    output wire                                  M_AXI_WLAST,
    output wire                                  M_AXI_WUSER,

    // Master Interface Write Response
    output wire                                  M_AXI_BREADY,
    input  wire                                  M_AXI_BVALID,
    input  wire [2-1:0]                          M_AXI_BRESP,
    input  wire                                  M_AXI_BUSER,
    input  wire [C_M_AXI_THREAD_ID_WIDTH-1:0]    M_AXI_BID,

    // Master Interface Read Address
    input  wire                                  M_AXI_ARREADY,
    output wire                                  M_AXI_ARVALID,
    output wire [C_M_AXI_ADDR_WIDTH-1:0]         M_AXI_ARADDR,
    output wire [8-1:0]                          M_AXI_ARLEN,
    output wire [3-1:0]                          M_AXI_ARSIZE,
    output wire [2-1:0]                          M_AXI_ARBURST,
    output wire                                  M_AXI_ARLOCK,
    output wire [4-1:0]                          M_AXI_ARCACHE,
    output wire [3-1:0]                          M_AXI_ARPROT,
    output wire [4-1:0]                          M_AXI_ARQOS,
    output wire                                  M_AXI_ARUSER,
    output wire [C_M_AXI_THREAD_ID_WIDTH-1:0]    M_AXI_ARID,

    // Master Interface Read Data
    output wire                                  M_AXI_RREADY,
    input  wire                                  M_AXI_RVALID,
    input  wire [C_M_AXI_DATA_WIDTH-1:0]         M_AXI_RDATA,
    input  wire [2-1:0]                          M_AXI_RRESP,
    input  wire                                  M_AXI_RLAST,
    input  wire                                  M_AXI_RUSER,
    input  wire [C_M_AXI_THREAD_ID_WIDTH-1:0]    M_AXI_RID,

    /* VGA/HDMIアダプタ接続信号 */
    output              PCK,
    output  [7:0]       VGA_R,  VGA_G,  VGA_B,
    output              VGA_HS, VGA_VS, VGA_DE,

    /* GPIOに接続 */
    input   [29:0]      DISPADDR,
    input               DISPON, CLRVBLNK,
    output              VBLANK,

    /* FIFOフラグ */
    output              FIFO_OVER, FIFO_UNDER
    );

/* AXI出力信号の固定 */
// Write Address (AW)
assign M_AXI_AWVALID = 1'b0;
assign M_AXI_AWADDR  = 32'h0;
assign M_AXI_AWLEN   = 8'd0;
assign M_AXI_AWSIZE  = 3'd0;
assign M_AXI_AWBURST = 2'b01;
assign M_AXI_AWLOCK  = 1'b0;
assign M_AXI_AWCACHE = 4'b0011;
assign M_AXI_AWPROT  = 3'h0;
assign M_AXI_AWQOS   = 4'h0;
assign M_AXI_AWUSER  = 1'b0;
assign M_AXI_AWID    = 1'b0;
// Write Data(W)
assign M_AXI_WVALID  = 1'b0;
assign M_AXI_WDATA   = 64'h0;
assign M_AXI_WSTRB   = 8'h0;
assign M_AXI_WLAST   = 1'b0;
assign M_AXI_WUSER   = 1'b0;
// Write Response (B)
assign M_AXI_BREADY  = 1'b0;
// Read Address (AR)
assign M_AXI_ARLEN   = 8'd15; // 16 beats
assign M_AXI_ARSIZE  = 3'd3;  // 64bit, 8Byte
assign M_AXI_ARBURST = 2'b01;
assign M_AXI_ARLOCK  = 1'b0;
assign M_AXI_ARCACHE = 4'b0011;
assign M_AXI_ARPROT  = 3'h0;
assign M_AXI_ARQOS   = 4'h0;
assign M_AXI_ARUSER  = 1'b0;
assign M_AXI_ARID    = 1'b0;

/* ACLKで同期化したリセット信号ARSTの作成 */
reg [1:0]   arst_ff;

always @( posedge ACLK ) begin
    arst_ff <= { arst_ff[0], ~ARESETN };
end

wire ARST = arst_ff[1];

/* PCKで同期化したリセット信号PRSTの作成 */
reg [1:0]   prst_ff;

always @( posedge PCK ) begin
    prst_ff <= { prst_ff[0], ~ARESETN };
end

wire PRST = prst_ff[1];

/* ブロック間接続信号 */
wire            AXISTART;
wire            FIFORD;
wire    [23:0]  FIFOOUT;
wire    [9:0]   HCNT;
wire    [9:0]   VCNT;
wire    [8:0]   wrcnt;

wire FIFOREADY = (wrcnt<9'd384);

disp_ctrl disp_ctrl (
    .ACLK       (ACLK),
    .ARST       (ARST),
    .ARADDR     (M_AXI_ARADDR),
    .ARVALID    (M_AXI_ARVALID),
    .ARREADY    (M_AXI_ARREADY),
    .RLAST      (M_AXI_RLAST),
    .RVALID     (M_AXI_RVALID),
    .RREADY     (M_AXI_RREADY),
    .AXISTART   (AXISTART),
    .DISPON     (DISPON),
    .DISPADDR   (DISPADDR),
    .FIFOREADY  (FIFOREADY)
);

disp_fifo disp_fifo(
  .rst          (~VGA_VS),
  .wr_clk       (ACLK),
  .rd_clk       (PCK),
  .din          ({M_AXI_RDATA[23:0], M_AXI_RDATA[55:32]}),
  .wr_en        (M_AXI_RVALID),
  .rd_en        (FIFORD),
  .dout         (FIFOOUT),
  .full         (),
  .overflow     (FIFO_OVER),
  .empty        (),
  .underflow    (FIFO_UNDER),
  .wr_data_count(wrcnt)
);

disp_out disp_out (
    .PCK        (PCK),
    .PRST       (PRST),
    .DISPON     (DISPON),
    .FIFORD     (FIFORD),
    .FIFOOUT    (FIFOOUT),
    .HCNT       (HCNT),
    .VCNT       (VCNT),
    .AXISTART   (AXISTART),
    .VGA_R      (VGA_R),
    .VGA_G      (VGA_G),
    .VGA_B      (VGA_B),
    .VGA_DE     (VGA_DE)
);

disp_flag disp_flag (
    .ACLK       (ACLK),
    .ARST       (ARST),
    .VGA_VS     (VGA_VS),
    .CLRVBLNK   (CLRVBLNK),
    .VBLANK     (VBLANK)
);

syncgen syncgen (
    .CLK        (ACLK),
    .RST        (PRST),
    .PCK        (PCK),
    .VGA_HS     (VGA_HS),
    .VGA_VS     (VGA_VS),
    .HCNT       (HCNT),
    .VCNT       (VCNT)
);

endmodule
