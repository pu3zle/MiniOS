#include "logging.h"

void InitLogging()
{
    unsigned short divisor = 4;

    __outbyte(0x3FB, 0x80);
    __outbyte(0x3F8, (divisor >> 8) & 0x00FF);
    __outbyte(0x3F8, divisor & 0x00FF);

    __outbyte(0x3FB, 0x03);

    __outbyte(0x3FA, 0xC7);

    __outbyte(0x3FC, 0x03);
}

int
IsLineReady()
{
    return (__inbyte(0x3FD) & 0x60) == 0x60;
}

void Log(char * Message)
{
    QWORD i;

    i = 0;
    while (Message[i] != 0)
    {
        while (!IsLineReady()) {}
        __outbyte(0x3F8, Message[i]);
        i++;
    }
}