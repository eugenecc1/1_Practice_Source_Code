/* Copyright(C) 2020 Cobac.Net All Rights Reserved. */
/* chapter: 第7章課題           */
/* project: chardisp            */
/* outline: 1文字表示関数の作成 */

#include <stdio.h>
#include "xparameters.h"
#include "xil_printf.h"

#define VRAM   ((volatile unsigned int  *) XPAR_CHARDISP_IP_V1_0_0_BASEADDR)
#define CR 0x0d
#define LF 0x0a
#define XSIZE 80
#define YSIZE 50
#define DEFAULT_COLOR 0x00f000
#define CLEAR (DEFAULT_COLOR | ' ')

/* プロトタイプ宣言 */
void disp( char c );
void scroll( void );

/* カーソル位置 */
int xpos, ypos;

int main()
{

    int i;

    xpos = ypos = 0;

    /* 画面クリア */
    for ( i=0; i<4000; i++ ) {
        VRAM[i] = CLEAR;
    }

    while (1) {
        disp( getc(stdin)&0xff );
//        xil_printf("%c", getc(stdin));
    }

    return 0;
}



void disp( char c )
{
    switch ( c ) {
        case CR: xpos = 0;
                 break;
        case LF: ypos++;
                 if ( ypos>=YSIZE ) {
                     ypos = YSIZE-1;
                     scroll();
                 }
                 break;
        default: if ( 0x20<=c && c<=0x7e ) {
                     VRAM[xpos+ypos*XSIZE] = DEFAULT_COLOR | c;
                     xpos++;
                     if ( xpos>=XSIZE ) {
                         xpos = 0;
                         ypos++;
                         if ( ypos>=YSIZE ) {
                             ypos = YSIZE-1;
                             scroll();
                         }
                     }
                 }
    }
}


void scroll( void )
{
    int i;
    for ( i=0; i<XSIZE*(YSIZE-1); i++ ) {
        VRAM[i] = VRAM[i+XSIZE];
    }
    for ( i=0; i<XSIZE; i++ ) {
        VRAM[XSIZE*(YSIZE-1)+i] = CLEAR;
    }
}
