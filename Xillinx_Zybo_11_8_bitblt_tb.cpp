/* Copyright(C) 2020 Cobac.Net All Rights Reserved.          */
/* chapter: 第11章課題                                       */
/* project: bitblt_trans_ip                                  */
/* outline: 透過処理付きビットブロック描画回路のテストベンチ */

#include <stdio.h>
#include <ap_int.h>
#include "bitblt.h"

#define WIDTH  160
#define HEIGHT 120

/* 読み出し元と書き込み先の先頭アドレス */
#define SRC0 (  0 +   0 * XSIZE)
#define SRC1 (160 +   0 * XSIZE)
#define DST0 (  0 +   0 * XSIZE)
#define DST1 ( 80 +  60 * XSIZE)
#define DST2 (  0 + 240 * XSIZE)
#define DST3 ( 80 + 300 * XSIZE)

/* VRAMとテクスチャで2画面分の配列を用意 */
u32 VRAM[XSIZE*YSIZE];
u32  TEX[XSIZE*YSIZE];

void bitblt(volatile u32*, volatile u32*, volatile u32*, u8, u11, u11, u8);
void patblt(volatile u32*, u11, u11, u11, u11, u32);

int main()
{
    /* VRAMクリア */
    patblt(VRAM, 0, 0, XSIZE, YSIZE, 0);
    /* テクスチャ画面左上に赤青の箱を書く */
    patblt(&TEX[SRC0], 0, 0, WIDTH, HEIGHT, 0x00ff0000);
    patblt(&TEX[SRC1], 0, 0, WIDTH, HEIGHT, 0xff0000ff);
    /* 青箱左上のα=0、それ以外α=0xff */
    for (int y=0; y<60; y++) {
        for(int x=0; x<80; x++) {
            TEX[SRC1 + x + y*XSIZE] &= 0x00ffffff;
        }
    }

    /* テクスチャ1個目書き込み */
    bitblt(&TEX[SRC0], &VRAM[DST0], &VRAM[DST0], 255, WIDTH, HEIGHT, 0);

    /* テクスチャ2個目と背景を読み込み画素間演算 */
    bitblt(&TEX[SRC1], &VRAM[DST1], &VRAM[DST1], 128, WIDTH, HEIGHT, 0);

    /* テクスチャ3個目書き込み */
    bitblt(&TEX[SRC0], &VRAM[DST2], &VRAM[DST2], 255, WIDTH, HEIGHT, 0);

    /* テクスチャ4個目の透過処理を行い背景に書く */
    bitblt(&TEX[SRC1], &VRAM[DST3], &VRAM[DST3], 128, WIDTH, HEIGHT, 1);

    /* ファイル出力 */
    FILE *fd = fopen("imagedata.raw", "wb");

    for (int y=0; y<YSIZE; y++) {
        for (int x=0; x<XSIZE; x++) {
            int temp = VRAM[y*XSIZE+x];
            fprintf( fd, "%c", (temp>>16) & 0xff );
            fprintf( fd, "%c", (temp>>8 ) & 0xff );
            fprintf( fd, "%c", (temp    ) & 0xff );
        }
    }
    fclose(fd);

    return 0;

}
