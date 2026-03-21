/* Copyright(C) 2020 Cobac.Net All Rights Reserved. */
/* chapter: 第11章課題                              */
/* project: drawchar                                */
/* outline: 文字パターン描画回路のテストベンチ      */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "ap_int.h"

#define XSIZE 640
#define YSIZE 480

void drawchar(volatile ap_uint<32>*, ap_uint<11>, ap_uint<11>, ap_uint<8>, ap_uint<8>, ap_uint<32>);

ap_uint<32> VRAM[XSIZE*YSIZE];

/* テストベンチ本体 */
int main()
{
    /* 画面クリア */
    for (int i=0; i<XSIZE*YSIZE; i++) {
        VRAM[i] = 0;
    }

    /* 色と大きさを変えて3文字描画 */
    drawchar(VRAM,   0,   0, 'A', 10, 0x00ff0000);
    drawchar(VRAM,  80,  80, 'B',  5, 0x0000ff00);
    drawchar(VRAM, 160, 160, 'C', 20, 0x000000ff);

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
