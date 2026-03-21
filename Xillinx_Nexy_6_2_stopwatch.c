/* ストップウォッチのプログラム                      */
/* Copyright(C) 2013 Cobac.Net, All rights reserved. */

#include <stdio.h>
#include "platform.h"
#include "IO_Module.h"
#include "mb_interface.h"

#define LED *((volatile unsigned int *) 0xc2000000)
#define FIT1_int 0x80
#define SW GPI1

#define SW1_MASK 0x01
#define SW2_MASK 0x02

/* 内部関数定義 */
void timer_int_handler( void * );
void disp( void );

static unsigned long system_timer;
unsigned long nowtime;
unsigned char SwPort_25ms;
int running;

int main()
{
    unsigned char pre_sw, now_sw;
    init_platform();

    nowtime = system_timer = running = 0;
    pre_sw = now_sw = 0;

    microblaze_register_handler(timer_int_handler, (void *)0);
    microblaze_enable_interrupts();
    IRQ_ENABLE = FIT1_int;

    while(1) {
        /* LED表示 */
        disp();
        /* スイッチ入力チェック */
        pre_sw = now_sw;
        now_sw = SwPort_25ms;
        if ( (pre_sw & SW1_MASK)==0 && (now_sw & SW1_MASK)!=0 )
            running ^= 1;
        if ( (pre_sw & SW2_MASK)==0 && (now_sw & SW2_MASK)!=0 )
            nowtime = 0;
    }

    cleanup_platform();
    return 0;
}

/* 割り込み処理 */
void timer_int_handler( void *arg )
{
    /* 1msごとにカウントアップ */
    system_timer++;
    /* 25msごとにスイッチポートを取り込む */
    if ( (system_timer % 25) == 0 )
        SwPort_25ms = SW;
    /* 計時カウンタのインクリメントと上限チェック */
    if ( (system_timer % 10) == 0 && running == 1 ) {
        if ( nowtime++ >= 6000 )
            nowtime = 0;
    }
    IRQ_ACK = FIT1_int;
}

/* LED表示関数 */
void disp( void )
{
    unsigned int pioout;
    pioout = ( nowtime/1000   << 12) | ((nowtime/100)%10 << 8) |
             ((nowtime/10)%10 <<  4) |   nowtime%10;
    LED = 0xf40000 | pioout;
}
