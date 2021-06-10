#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>

#include <sys/stat.h>

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wunused-function"
#include <murax.h>
#pragma GCC diagnostic pop

 
int puts(const char *str)
{
  for (int i = 0; str[i] != 0; i++)
    uart_write(UART, str[i]);

  uart_write(UART, 0xa);
  uart_write(UART, 0xd);

  return EXIT_SUCCESS;
}


int _fstat (int file, struct stat *st)
{
  st->st_mode = S_IFCHR;
  return 0;
}

void *_sbrk (int nbytes)
{
  return  (void *) -1;
}

int _write (int file, char *buf, int   nbytes)
{
  int i;

  for (i = 0; i < nbytes; i++)
  {
    if (buf[i] == '\n')
    {
      uart_write(UART, 0xa);
      uart_write(UART, 0xd);
    }
    else
      uart_write(UART, buf[i]);
  }

  return nbytes;
}

 
void irqCallback(){
	if(TIMER_INTERRUPT->PENDINGS & 1){  // Timer A interrupt
		TIMER_INTERRUPT->PENDINGS = 1;    // Release interrupt
	}
  else
  {
    char data[6] = {'t', 'r', 'a', 'p', 0xa, 0xd};

    uart_write(UART, data[0]);
    uart_write(UART, data[1]);
    uart_write(UART, data[2]);
    uart_write(UART, data[3]);
    uart_write(UART, data[4]);
    uart_write(UART, data[5]);
  }
}

