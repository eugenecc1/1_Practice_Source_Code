/* Copyright(C) 2020 Cobac.Net All Rights Reserved. */
/* chapter: 第10章課題              */
/* project: avgminmax               */
/* outline: avgminmaxのテストベンチ */

#include <stdio.h>
#include <stdlib.h>
#define SIZE 16

void avgminmax( int [], int *, int *, int * );

int main( )
{
    int din[SIZE];
    int i, retval=0, expmin, expmax;
    long long expavg=0;
    int average, min, max;

    /* 配列dinに乱数を代入 */
    for ( i=0; i<SIZE; i++ ) {
        din[i] = rand();
        printf("din[%2d]=%d\n", i, din[i]);
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

    avgminmax(din, &average, &min, &max);
    printf("Average=%d  Minimum=%d  Maximum=%d\n", average, min, max);

    /* 演算結果を期待値と比較 */
    if ( average==expavg && min==expmin && max==expmax ) {
        printf("OK.\n");
    }
    else {
        printf("*** NG ***\n");
        retval = 1;
    }

    return retval;
}
