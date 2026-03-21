/* Copyright(C) 2020 Cobac.Net All Rights Reserved. */
/* chapter: 第9章 コラムI          */
/* project: display                */
/* outline: SDカード読み出しテスト */

#include "xparameters.h"
#include "xsdps.h"
#include "xil_printf.h"
#include "ff.h"

int main()
{
    FIL fil;
    FATFS fatfs;
    FRESULT Res;
    UINT NumBytesRead;
    u32 FileSize = 8*1024;
    TCHAR *Path = "0:/";

    char FileName[32] = "display.xdc";
    unsigned char buff[8200];
    int i;
    /* SDカードのマウント */
    Res = f_mount(&fatfs, Path, 0);
    if (Res != FR_OK) {
        xil_printf("ERROR(%d): f_mount\n", Res);
        return XST_FAILURE;
    }
    /* ファイルのオープン */
    Res = f_open(&fil, FileName, FA_READ);
    if (Res != FR_OK) {
        xil_printf("ERROR(%d): f_open\n", Res);
        return XST_FAILURE;
    }
    while(1) {
        /* ファイルの読み出し */
        Res = f_read(&fil, buff, FileSize, &NumBytesRead);
        if (Res != FR_OK) {
            xil_printf("ERROR(%d): f_read\n", Res);
            return XST_FAILURE;
        }
        /* 文字で表示 */
        for ( i=0; i<NumBytesRead; i++ ) {
            xil_printf("%c", buff[i]);
        }
        if ( NumBytesRead<FileSize )
            break;
    }
    /* ファイルのクローズ */
    Res = f_close(&fil);
    if (Res != FR_OK) {
        xil_printf("ERROR(%d): f_close\n", Res);
        return XST_FAILURE;
    }

    return XST_SUCCESS;
}
