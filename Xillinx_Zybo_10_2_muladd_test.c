/* Copyright(C) 2020 Cobac.Net All Rights Reserved. */
/* chapter: 第10章                         */
/* project: muladd                         */
/* outline: 高位合成した乗加算回路のテスト */

#include <stdio.h>
#include <stdlib.h>
#include "xil_printf.h"
#include "xparameters.h"
#include "xmuladd.h"

#define SIZE 16

/* インスタンス変数の宣言 */
XMuladd Instance;

int main()
{
	u32 a[SIZE], b[SIZE];
    int i, temp=0;

    /* 初期化 */
    if ( XMuladd_Initialize(&Instance,
                XPAR_XMULADD_0_DEVICE_ID)!=XST_SUCCESS ) {
        xil_printf("Init Error!\n");
        return XST_FAILURE;
    }
    /* 配列a、bに乱数を代入し期待値を作成 */
    for ( i=0; i<SIZE; i++ ) {
        a[i] = rand() & 0xffff;
        b[i] = rand() & 0xffff;
        temp += a[i] * b[i];
        xil_printf("a[%2d]=%04x  b[%2d]=%04x  temp=%08x\n",
                i, a[i], i, b[i], temp);
    }
    /* ポートを経由して配列a、bを書き込む */
    XMuladd_Write_a_Words(&Instance, 0, a, SIZE);
    XMuladd_Write_b_Words(&Instance, 0, b, SIZE);

    /* 乗加算回路を起動 */
    XMuladd_Start(&Instance);
    while (XMuladd_IsDone(&Instance)==0);

    /* 演算結果を期待値と比較 */
    if ( temp == XMuladd_Get_return(&Instance) ) {
        xil_printf("OK.\n");
    }
    else {
        xil_printf("*** NG ***\n");
    }

    return 0;
}
