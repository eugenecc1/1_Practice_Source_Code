/* Copyright(C) 2020 Cobac.Net All Rights Reserved. */
/* chapter: 第10章課題                       */
/* project: avgminmax                        */
/* outline: 平均値、MIN、MAX算出回路のテスト */

#include <stdio.h>
#include <stdlib.h>
#include "xparameters.h"
#include "xavgminmax.h"

#define SIZE 16

/* インスタンス変数の宣言 */
XAvgminmax Instance;

int main()
{
    u32 din[SIZE];
    int i, expmin, expmax;
    long long expavg=0;
    int average, min, max;

    /* 初期化 */
    if ( XAvgminmax_Initialize(&Instance,
                XPAR_XAVGMINMAX_0_DEVICE_ID)!=XST_SUCCESS ) {
        xil_printf("Init Error!\n");
        return XST_FAILURE;
    }
    
    /* 配列dinに乱数を代入 */
    for ( i=0; i<SIZE; i++ ) {
        din[i] = rand();
        xil_printf("din[%2d]=%d\n", i, din[i]);
    }
    /* 期待値を作成 */
    expmin = din[0];
    expmax = din[0];
    for ( i=0; i<SIZE; i++ ) {
        expavg += din[i];
        if (expmin > din[i]) {
            expmin = din[i];
        }
        if (expmax < din[i]) {
            expmax = din[i];
        }
    }
    expavg /= SIZE;

    /* ポートを経由して配列dinに書き込む */
    XAvgminmax_Write_din_Words(&Instance, 0, din, SIZE);

    /* 算出回路を起動 */
    XAvgminmax_Start(&Instance);
    while (XAvgminmax_IsDone(&Instance)==0);

    /* 演算結果を取得 */
    average = XAvgminmax_Get_average(&Instance);
    min     = XAvgminmax_Get_min(&Instance);
    max     = XAvgminmax_Get_max(&Instance);
    xil_printf("Average=%d  Minimum=%d  Maximum=%d\n", average, min, max);

    /* 演算結果を期待値と比較 */
    if ( average==expavg && min==expmin && max==expmax ) {
        xil_printf("OK.\n");
    }
    else {
        xil_printf("*** NG ***\n");
        xil_printf("expavg=%d  expmin=%d  expmax=%d\n", expavg, expmin, expmax);
    }

    return 0;
}
