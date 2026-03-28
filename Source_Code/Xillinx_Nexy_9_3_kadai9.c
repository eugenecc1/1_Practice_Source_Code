/* 第９章課題　高画質キャプチャ                     */
/* Copyright(C) 2013 Cobac.Net All rights reserved. */

#include <stdio.h>
#include "platform.h"
#include "ov7670.h"

#define MODEREG  *((volatile unsigned int *) 0xc1000000)
#define DISPMODE 0
#define CAPTMODE 1
#define MCSMODE  2

#define DISPPAGE *((volatile unsigned int *) 0xc5000000)
#define DBLANK   *((volatile unsigned int *) 0xc5000004)

#define CAPTPAGE *((volatile unsigned int *) 0xc6000000)
#define CAPTREG  *((volatile unsigned int *) 0xc6000004)
#define CBLANK   1
#define CAPTON   2

#define SCCBREG  *((volatile unsigned int *) 0xc7000000)
#define SCCBSTAT *((volatile unsigned int *) 0xc7000004)
#define SCCBBUSY 1

#define MEMS     ((volatile unsigned short *) 0xc0000000)
#define PICT     ((volatile unsigned char  *) 0xc0800000)

#define XSIZE 600
#define YSIZE 480

void wait_dblank( void );
void wait_cblank( void );
void sccb_write( int );
void ov7670_init( void );

int main()
{
    int i, temp;
    init_platform();

    ov7670_init();

    MODEREG  = DISPMODE;
    DISPPAGE = 0;
    CAPTPAGE = 0;
    CAPTREG  = 0;

    /* キャプチャ開始                     */
    /* ブレークポイントを置いて一呼吸待つ */
    xil_printf("Capturing...\n");
    wait_cblank();
    MODEREG = CAPTMODE;
    CAPTREG |= CAPTON;    // キャプチャ開始
    wait_cblank();
    CAPTREG &= ~CAPTON;   // キャプチャ終了

    MODEREG = MCSMODE;
    xil_printf("Converting format...\n");

    /* RAWフォーマットの作成 */
    for (i=0; i<XSIZE*YSIZE; i++) {
        temp = MEMS[i];
        PICT[i*3]   = (temp << 4) & 0xf0;  // R
        PICT[i*3+1] = (temp     ) & 0xf0;  // G
        PICT[i*3+2] = (temp >> 4) & 0xf0;  // B
    }

    xil_printf("End.\n");

    cleanup_platform();

    return 0;
}

/* 画面表示の終了を待つ */
void wait_dblank( void )
{
    DBLANK = 0;
    while ( DBLANK == 0 );
}

/* 画面取り込み終了を待つ */
void wait_cblank( void )
{
    CAPTREG &= ~CBLANK;
    while ( (CAPTREG & CBLANK) == 0 );
}


/* SCCB経由でカメラの設定レジスタに書き込み */
void sccb_write( int data )
{
    while ((SCCBSTAT & SCCBBUSY) != 0);
    SCCBREG = data;
}

/* センサーチップOV7670の初期化 */
void ov7670_init( void )
{
    int i=0;
    int data=init_data[0];

    while ( data!=0xffff ) {
        sccb_write( data );
        data = init_data[++i];
    }
    while ((SCCBSTAT & SCCBBUSY) != 0);
}
