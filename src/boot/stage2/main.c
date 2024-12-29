#include "stdint.h"
#include "stdio.h"

void _cdecl stage2_cmain_(u16 bootDrive)
{
    print_string("Ok!\r\n");
    print_string("-=Transitioned to C.=-\r\n");

    for (;;);
}