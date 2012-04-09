#include <stdio.h>

int 
main(int argc, char *argv[])
{
    unsigned char xx[] = { 0x01, 0x02, 0x03, 0x04 };

    printf("char[] inited as big endian=%x.%x.%x.%x\n", xx[0], xx[1], xx[2], xx[3]);

    unsigned short ss = 0x0102;
    unsigned char *sp = (unsigned char *) &ss;

    /* force the short into a char array */
    printf("short shown in char[] order=%x.%x\n", sp[0], sp[1]);

    unsigned int ii = 0x01020304;
    unsigned char *ip = (unsigned char *) &ii;

    /* force the int into a char array */
    printf("int shown in char[] order=%x.%x.%x.%x\n", ip[0], ip[1], ip[2], ip[3]);
}
