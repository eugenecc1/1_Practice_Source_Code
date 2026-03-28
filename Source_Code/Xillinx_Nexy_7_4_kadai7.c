/* 第７章課題　PS/2 & VGA文字表示回路制御プログラム */
/* Copyright(C) 2013 Cobac.Net All rights reserved. */

#include <stdio.h>
#include "platform.h"

#define PS2STATUS *((volatile unsigned int *) 0xc3000000)
#define PS2RDATA  *((volatile unsigned int *) 0xc3000004)
#define PS2WDATA  *((volatile unsigned int *) 0xc3000008)
#define VRAM       ((volatile unsigned int *) 0xc4000000)

/* 関数のプロトタイプ */
unsigned char chgcode( unsigned char code, int sftflag );
void vramclr( void );
void scroll( void );
void vramret( void );

/* 文字色：緑 */
#define GREEN 0x1c00

/* X, Yサイズ */
#define XSIZE 80
#define YSIZE 50

/* キーコード変換用配列 */
const unsigned char keytbl[128][3] = {
    {0x16, '1', '!'}, {0x1e, '2', '\"'},{0x26, '3', '#'}, {0x25, '4', '$'},
    {0x2e, '5', '%'}, {0x36, '6', '&'}, {0x3d, '7', '\''},{0x3e, '8', '('},
    {0x46, '9', ')'}, {0x45, '0', ' '}, {0x4e, '-', '='}, {0x55, '^', '~'},
    {0x6a, '\\', '|'},{0x15, 'q', 'Q'}, {0x1d, 'w', 'W'}, {0x24, 'e', 'E'},
    {0x2d, 'r', 'R'}, {0x2c, 't', 'T'}, {0x35, 'y', 'Y'}, {0x3c, 'u', 'U'},
    {0x43, 'i', 'I'}, {0x44, 'o', 'O'}, {0x4d, 'p', 'P'}, {0x54, '@', '`'},
    {0x5b, '[', '{'}, {0x1c, 'a', 'A'}, {0x1b, 's', 'S'}, {0x23, 'd', 'D'},
    {0x2b, 'f', 'F'}, {0x34, 'g', 'G'}, {0x33, 'h', 'H'}, {0x3b, 'j', 'J'},
    {0x42, 'k', 'K'}, {0x4b, 'l', 'L'}, {0x4c, ';', '+'}, {0x52, ':', '*'},
    {0x5d, ']', '}'}, {0x1a, 'z', 'Z'}, {0x22, 'x', 'X'}, {0x21, 'c', 'C'},
    {0x2a, 'v', 'V'}, {0x32, 'b', 'B'}, {0x31, 'n', 'N'}, {0x3a, 'm', 'M'},
    {0x41, ',', '<'}, {0x49, '.', '>'}, {0x4a, '/', '?'}, {0x51, '\\', '_'},
    {0x29, ' ', ' '} };

/* スキャン・キーコード */
#define ESC     0x76
#define SHIFT_L 0x12
#define SHIFT_R 0x59
#define ENTER   0x5A

#define PS2VALID 0x01
#define KYCDMAX  49  /* 配列に用意したキーコードの数 */

/* 書き込み位置 */
int xpos, ypos;

int main()
{
    int ps2in, code;
    int postF0=0, sftflag=0;

    vramclr();

    while(1) {
        while ( (PS2STATUS & PS2VALID)==0 );
        PS2STATUS = 0;
        ps2in = PS2RDATA & 0xff;
        if ( ps2in==0xf0 )  /* F0とその直後は表示しない */
            postF0 = 1;
        else if ( postF0==1 ) {
            postF0 = 0;
            if ( ps2in==SHIFT_L || ps2in==SHIFT_R )
                sftflag = 0;
        }
        else {
            switch ( ps2in ) {
                case ESC:     vramclr(); break;
                case SHIFT_L:
                case SHIFT_R: sftflag=1; break;
                case ENTER:   vramret(); break;
                default:
                    if ( (code=chgcode(ps2in, sftflag)) != 0x00 ) {
                        VRAM[xpos+ypos*XSIZE] = GREEN | code;
                        xpos++;
                        if ( xpos>=XSIZE ) {
                            vramret();
                        }
                    }
            }
        }
    }
    return 0;
}

/* キーコードの変換 */
unsigned char chgcode( unsigned char code, int sftflag )
{
    int i;

    for ( i=0; i<KYCDMAX; i++ ) {
        if ( keytbl[i][0]==code )
            break;
    }
    if ( i>=KYCDMAX )
        return 0x00;
    else
        return keytbl[i][1+sftflag];
}

/* VRAMのクリア */
void vramclr( void )
{
    int x;

    for ( x=0; x<XSIZE*YSIZE; x++ ) {
        VRAM[x] = GREEN | 0x20;
    }
    xpos = 0;
    ypos = 0;
}

/* スクロール */
void scroll( void )
{
    int x, y;

    for ( y=0; y<YSIZE; y++ ) {
        for ( x=0; x<XSIZE; x++ ){
            if ( y != YSIZE-1 ) {
                VRAM[x+y*XSIZE] = VRAM[x+(y+1)*XSIZE];
            }
            else
                VRAM[x+y*XSIZE] = GREEN | 0x20;
        }
    }
}

/* Enterキーの処理 */
void vramret( void )
{
    xpos = 0;
    ypos++;
    if ( ypos>=YSIZE ) {
        ypos = YSIZE-1;
        scroll();
    }
}
