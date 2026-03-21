/* Copyright(C) 2020 Cobac.Net All Rights Reserved. */
/* chapter: 第6章             */
/* project: blink_mb          */
/* outline: LED点滅プログラム */

#include "xparameters.h"
#include "xil_printf.h"

#define LED      *((volatile unsigned int*) (XPAR_GPIO_0_BASEADDR + 0x00))
#define LED_ctrl *((volatile unsigned int*) (XPAR_GPIO_0_BASEADDR + 0x04))

int main()
{
    int i, j;

    LED_ctrl = 0x0; /* 全ビットを出力に設定 */
    xil_printf("Hello FPGA World!\r\n");
    while(1) {
        for ( i=0; i<5; i++ ) {
            xil_printf("i=%d\r\n", i);
            switch ( i ) {
                case  0: LED = 0x4; break;
                case  1: LED = 0x2; break;
                case  2: LED = 0x1; break;
                case  3: LED = 0x7; break;
                case  4: LED = 0x0; break;
                default: LED = 0x0;
            }
            for ( j=0; j<40000000; j++); /* 遅延を作成（MicroBlazeでは遅すぎ） */
        }
    }

    return 0;
}
