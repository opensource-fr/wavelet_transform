#include <stdio.h>
#include <stdlib.h>

#include "Vtop.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

int tickcount = 0;
Vtop *tb;
VerilatedVcdC *tfp;

void tick(void) {
  tickcount++;

  tb->eval();
  if (tfp) tfp->dump(tickcount * 10 - 2);
  tb->i_clk = 1;
  tb->eval();
  if (tfp) tfp->dump(tickcount * 10);
  tb->i_clk = 0;
  tb->eval();
  if (tfp) {
    tfp->dump(tickcount * 10 + 5);
    tfp->flush();
  }
}

int main(int argc, char **argv) {
  int last_led, last_state = 0, state = 0;

  // Call commandArgs first!
  Verilated::commandArgs(argc, argv);

  // Instantiate our design
  tb = new Vtop;

  // Generate a trace
  Verilated::traceEverOn(true);
  tfp = new VerilatedVcdC;
  tb->trace(tfp, 99);  // what does the 99 mean i the tb->trace ?
  tfp->open("top.vcd");

  for (int cycle = 0; cycle < 100; cycle++) {
    // Wait 5 clocks

    /* printf("data is %8lx\n", tb->top__DOT__fir_1__DOT__filter);  // read zero for now */
    tick();
  }
  tfp->close();
  delete tfp;
  delete tb;
}
