#include <neorv32.h>

/** UART BAUD rate */
#define BAUD_RATE     19200

int main() {
  uint32_t gpio;
  int x;
  int matrix[2][100] = 
  {
    {23, 1, 57, 84, 16, 7, 10, 73, 32, 42, 69, 66, 94, 50, 36, 58, 14, 46, 12, 90, 87, 26, 5, 77, 19, 62, 18, 80, 38, 48, 21, 96, 75, 91, 61, 35, 55, 81, 52, 44, 98, 40, 33, 78, 25, 95, 79, 60, 70, 85, 97, 56, 45, 29, 22, 71, 28, 65, 13, 31, 86, 39, 89, 54, 88, 67, 6, 41, 99, 68, 17, 9, 3, 51, 11, 30, 47, 53, 8, 63, 59, 27, 76, 24, 72, 37, 15, 43, 82, 92, 64, 34, 93, 49, 4, 83, 20, 2},
    {56, 33, 8, 63, 70, 28, 10, 79, 68, 94, 12, 27, 88, 31, 25, 74, 80, 20, 19, 92, 97, 40, 59, 77, 17, 61, 24, 36, 37, 81, 91, 48, 43, 38, 65, 47, 35, 86, 99, 11, 45, 21, 53, 60, 6, 85, 29, 15, 54, 42, 50, 69, 66, 46, 95, 72, 64, 7, 52, 4, 18, 90, 89, 9, 62, 73, 55, 75, 2, 98, 67, 16, 5, 78, 96, 34, 51, 14, 76, 30, 44, 22, 84, 39, 1, 87, 71, 49, 23, 57, 41, 3, 26, 58, 82, 32}
  };
  
  // Check UART0 availability and set it up
  if (neorv32_uart0_available() == 0) {
    return 1;
  }
  neorv32_uart0_setup(BAUD_RATE, 0);
  
  // clear GPIO output (set all bits to 0)
  neorv32_gpio_port_set(0);
  
  gpio = neorv32_gpio_port_get();
  x = 0;
  for (uint8_t i = 0; i < 2; i++)
  {
    for (uint8_t j = 0; j < 10; j++)
    {
      x += matrix[i][j] * matrix[i][100 - j - 1] * (gpio + 33);
    }
  }
  
  if (x == 0)
  {
    neorv32_gpio_port_set(0x0F);
    neorv32_uart0_printf("\n\nEND OF SIMULATION\n\n");
  }
  else
  {    
    neorv32_gpio_port_set(0xFF);
    neorv32_uart0_printf("\n\nEND OF SIMULATION\n\n");
  } 
  
  while(1)
  {
    continue;
  }
  
  // this should never be reached
  return 0;
}