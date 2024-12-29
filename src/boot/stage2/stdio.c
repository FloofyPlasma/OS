#include "stdio.h"
#include "x86.h"

void print_character(char c)
{
    x86_Print_String(c, 0);
}

void print_string(const char *str)
{
    while (*str != '\0')
    {
        print_character(*str);
        str++;
    }
}