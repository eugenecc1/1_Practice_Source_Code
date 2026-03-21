/* PS/2マウスのテストプログラム                     */
/* Copyright(C) 2013 Cobac.Net All Rights Reserved. */

#include <stdio.h>
#include "platform.h"

#define LED       *((volatile unsigned int *) 0xc2000000)
#define PS2STATUS *((volatile unsigned int *) 0xc3000000)
#define PS2RDATA  *((volatile unsigned int *) 0xc3000004)
#define PS2WDATA  *((volatile unsigned int *) 0xc3000008)

#define PS2VALID  0x01
#define PS2EMPTY  0x02

void putdata( int data );
int getdata(void);


int main()
{
    int data1, data2, data3, L, R;
    int posx=0, posy=0, dx, dy;
    int piodata=0xf00000;

    init_platform();
    LED = piodata;

    putdata(0xFF);      /* リセットコマンド送信 */
    data1 = getdata();  /* マウス応答を受信（チェックしない） */
    data2 = getdata();
    data3 = getdata();
//    xil_printf("res1=%x %x %x\n", data1, data2, data3);

    putdata(0xF4);      /* イネーブルコマンド送信 */
    data1 = getdata();  /* マウス応答を受信（チェックしない） */
//    xil_printf("res2=%x\n", data1);

    while(1) {
        /* マウスから3データ受信 */
        data1 = getdata();
        data2 = getdata();
        data3 = getdata();

        /* X、Yの符号ビットを取り出し、9ビットの移動量とする */
        if ( (data1 & 0x10) != 0)
            dx = data2 | 0xffffff00;
        else
            dx = data2;
        if ( (data1 & 0x20) != 0)
            dy = data3 | 0xffffff00;
        else
            dy = data3;

        /* 移動量を現在位置に加算 */
        posx = posx + dx;
        posy = posy + dy;

        /* 左右ボタンの検出 */
        L = ( (data1 & 0x01) != 0) ? 1: 0;
        R = ( (data1 & 0x02) != 0) ? 1: 0;

        /* 表示用のデータ作り */
        piodata = 0xf00000 | ((posx << 8) & 0xff00) | (posy & 0xff);
        if ( L==1 )
            piodata |= 0x040000;
        if ( R==1 )
            piodata |= 0x010000;
        if ( L==1 && R==1 )
            posx = posy = 0;    /* 両方押されたら現在位置をリセット */

        /* LED表示 */
        LED = piodata;
//        xil_printf("posx=%x posy=%x L=%x R=%x\n", posx, posy, L, R);
    }

    cleanup_platform();

    return 0;
}

/* マウスへ1バイト送出 */
void putdata( int data )
{
    while ( (PS2STATUS & PS2EMPTY)==0 );
    PS2WDATA = data;
}

/* マウスから1バイト受信 */
int getdata(void)
{
    while ( (PS2STATUS & PS2VALID)==0 );
    PS2STATUS = 0;
    return PS2RDATA;
}
