/* Copyright(C) 2020 Cobac.Net All Rights Reserved. */
/* chapter: ‘æ10Í‰Û‘è               */
/* project: avgminmax                */
/* outline: •½‹Ï’lAMINAMAX‚ğ‹‚ß‚é */

#define SIZE 16

void avgminmax( int din[SIZE], int *average, int *min, int *max )
{
    int i, tempmin, tempmax;
    long long tempavg=0;

    tempmin = din[0];
    tempmax = din[0];
    calc_loop:for ( i=0; i<SIZE; i++ ) {
        tempavg += din[i];
        if (tempmin > din[i]) {
            tempmin = din[i];
        }
        if (tempmax < din[i]) {
            tempmax = din[i];
        }
    }

    *average = tempavg/SIZE;
    *min     = tempmin;
    *max     = tempmax;
}
