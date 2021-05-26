#ifndef HEX_H_
#define HEX_H_


typedef struct
{
  //volatile uint32_t DATA;
  //volatile uint32_t STATUS;
  volatile uint32_t INPUT;
  volatile uint32_t OUTPUT;
  volatile uint32_t OUTPUT_ENABLE;
} Hex_Reg;


/*static uint32_t hex_writeAvailability(Hex_Reg *reg){
	return (reg->STATUS >> 16) & 0xFF;
}
static uint32_t hex_readOccupancy(Hex_Reg *reg){
	return reg->STATUS >> 24;
}

static void hex_write(Hex_Reg *reg, uint32_t data){
	while(hex_writeAvailability(reg) == 0);
	reg->DATA = data;
}
static uint32_t hex_read(Hex_Reg *reg){
	return reg->DATA;
}
*/

#endif /* HEX_H_ */


