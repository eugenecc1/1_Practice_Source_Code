/* Copyright(C) 2020 Cobac.Net All Rights Reserved. */
/* chapter: 第11章                               */
/* project: bitblt_ip                            */
/* outline: ビットブロック描画回路のテストベンチ */

#include <stdio.h>
#include <ap_int.h>
#include "bitblt.h"

#define WIDTH  320
#define HEIGHT 240

/* 読み出し元と書き込み先の先頭アドレス */
#define SRC0 (  0 +   0 * XSIZE)
#define SRC1 (320 +   0 * XSIZE)
#define DST0 ( 80 +  60 * XSIZE)
#define DST1 (240 + 180 * XSIZE)

/* VRAMとテクスチャで2画面分の配列を用意 */
u32 VRAM[XSIZE*YSIZE];
u32  TEX[XSIZE*YSIZE];

void bitblt(volatile u32*, volatile u32*, volatile u32*, u8, u11, u11);
void patblt(volatile u32*, u11, u11, u11, u11, u32);

int main()
{
    /* VRAMクリア */
    patblt(VRAM, 0, 0, XSIZE, YSIZE, 0);
    /* テクスチャ画面左上に赤青の箱を書く */
    patblt(&TEX[SRC0], 0, 0, WIDTH, HEIGHT, 0x00ff0000);
    patblt(&TEX[SRC1], 0, 0, WIDTH, HEIGHT, 0x000000ff);

    /* テクスチャ1個目書き込み */
    bitblt(&TEX[SRC0], &VRAM[DST0], &VRAM[DST0], 255, WIDTH, HEIGHT);

    /* テクスチャ2個目と背景を読み込み画素間演算 */
    bitblt(&TEX[SRC1], &VRAM[DST1], &VRAM[DST1], 128, WIDTH, HEIGHT);

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
