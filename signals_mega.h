/*
 * Copyright © 2010 Scott Perry
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following
 * conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 */

#ifndef _SIGNALS_PLATFORM_H_
#define _SIGNALS_PLATFORM_H_
#include <stdint.h>
#include "WProgram.h"

/*
 * THIS FILE DOES NOT CONTAIN ANY CONDITIONALS!
 * this is on purpose. logic does not belong here.
 */

// spare pin. this could be used with LED for hardware flow control.
#define STS 12

/*
 * signalline functions:
 * the signallines are connected to port C
 *
 * port manipulation is used throughout, as speed and synchronicity are
 * both important.
 */

/*
 * init_signals --
 *    initializes the port states
 *
 * args:
 *    states: bitmask for signal line states. 0 is read, 1 is write.
 */
void init_signals(uint8_t states) {
  DDRC = states;
}

/*
 * write_signs --
 *    write to the signallines, to communicate to the typewriter.
 *
 * args:
 *    signs - the signals to write to the signallines
 */
void write_signs(uint8_t signs) {
  PORTC = signs;
}

/*
 * read_signs --
 *    sample the signallines
 *
 * returns: state of the signallines
 */
uint8_t read_signs(void) {
  return PINC;
}

/*
 * init_scans --
 *    initializes port states for reading the scan lines
 */
void init_scans(void) {
  DDRA = 0x00
}

/*
 * read_scans --
 *    sample the scanlines
 *
 *    port manipulation is used, as speed and synchronicity are both important.
 *
 *    the scanlines are connected to port A
 *
 * returns: state of the scanlines
 */
uint8_t read_scans(void) {
  return PINA;
}

#endif // _SIGNALS_PLATFORM_H_
