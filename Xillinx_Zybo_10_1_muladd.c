/* Copyright(C) 2020 Cobac.Net All Rights Reserved. */
/* chapter: ‘æ10Í                       */
/* project: muladd                       */
/* outline: ‚ˆÊ‡¬‚Ì‘ÌŒ±iæ‰ÁZ‰ñ˜Hj */

#define SIZE 16

int muladd( int a[SIZE], int b[SIZE] )
{
    int i, temp=0;

    muladd_loop:for ( i=0; i<SIZE; i++ ) {
        temp += a[i] * b[i];
    }

    return temp;
}
