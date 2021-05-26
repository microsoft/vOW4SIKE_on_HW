#include <stdint.h>

#include <murax_hex.h>

void print_hex(char *str){
	while(*str){
		uart_write(UART,*(str++));
	}
}

void main() {
	volatile uint32_t a = 1, b = 2, c = 3;
	uint32_t result = 0;

	interruptCtrl_init(TIMER_INTERRUPT);
	prescaler_init(TIMER_PRESCALER);
	timer_init(TIMER_A);

	TIMER_PRESCALER->LIMIT = 12000-1; //1 ms rate

	TIMER_A->LIMIT = 1000-1;  //1 second rate
	TIMER_A->CLEARS_TICKS = 0x00010002;

	TIMER_INTERRUPT->PENDINGS = 0xF;
	TIMER_INTERRUPT->MASKS = 0x1;

	GPIO_A->OUTPUT_ENABLE = 0x000000FF;
	GPIO_A->OUTPUT = 0x00000000;

	GPIO_HEX->OUTPUT_ENABLE = 0x000000FF;
	GPIO_HEX->OUTPUT = 0x00000000;

	GPIO_HEX2->OUTPUT_ENABLE = 0x000000FF; 
	GPIO_HEX2->OUTPUT = 0x00000000;

	UART->STATUS = 2; //Enable RX interrupts
	UART->DATA = 'C';

	//HEX->STATUS = 2; //Enable RX interrupts
	//HEX->DATA = 'B';

	print_hex("Hello !\n");

	while(1){
		result += a;
		result += b + c;
		for(uint32_t idx = 0;idx < 50000;idx++) asm volatile("");
		GPIO_A->OUTPUT = (GPIO_A->OUTPUT & ~0x3F) | ((GPIO_A->OUTPUT + 1) & 0x3F);  //Counter on LED[5:0]
		if (GPIO_A->INPUT & 0x00000001){
		GPIO_HEX->OUTPUT = (GPIO_HEX->OUTPUT + 7) & 0xFFFFFFFF; //(GPIO_HEX->OUTPUT & ~0xFFFF) | ((GPIO_HEX->OUTPUT + 1) & 0xFFFF); //Counter on LED[7:0]
		}
		if (GPIO_A->INPUT & 0x00000001){
		GPIO_HEX2->OUTPUT = (GPIO_HEX2->OUTPUT + 1) & 0xFFFFFFFF; //(GPIO_HEX2->OUTPUT & ~0xFFFF) | ((GPIO_HEX2->OUTPUT + 1) & 0xFFFF); //Counter on LED[7:0]
		}
		//HEX->DATA = 10;//(HEX->DATA & ~0x3F) | ((HEX->DATA + 1) & 0x3F);  //Counter on LED[5:0]
	}
}

void irqCallback(){
	if(TIMER_INTERRUPT->PENDINGS & 1){  //Timer A interrupt
		GPIO_A->OUTPUT ^= 0x80; //Toogle led 7
		GPIO_HEX->OUTPUT ^= 0x40; //Toogle led 6
		TIMER_INTERRUPT->PENDINGS = 1;
	}
	while(UART->STATUS & (1 << 9)){ //UART RX interrupt
		//UART->DATA = ((UART->DATA) + (HEX->DATA)) & 0xFF; //(65) & 0xFF; //(UART->DATA) & 0xFF;
		UART->DATA = (UART->DATA + (GPIO_A->INPUT & 0x00000001) )  & 0xFF; //(UART->DATA) & 0xFF;
		//UART->DATA = (UART->DATA) & 0xFF;
	}
	//while(HEX->STATUS & (1 << 9)){ //HEX RX interrupt
	//	HEX->DATA = (HEX->DATA) & 0xFF;
	//}
}



