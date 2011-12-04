/*
 * Copyright © 2009 Scott Perry
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

#ifndef _SIGNALS_H_
#define _SIGNALS_H_
#include <stdint.h>
#include "WProgram.h"

/*
 * THIS FILE DOES NOT CONTAIN ANY CONDITIONALS!
 * this is on purpose. logic does not belong here.
 */

/*
 * platform-specific signals.h files must include the following definitions:
 *    void init_signals(uint8_t);
 *    void write_signs(uint8_t);
 *    uint8_t read_signs(void);
 *    void init_scans(void);
 *    uint8_t read_scans(void);
 */

#ifdef DUEMILANOVE
#include "signals_duemilanove.h"
#endif
#ifdef MEGA
#include "signals_mega.h"
#endif

/*
 * init_read --
 *    initializes port states for reading the signallines
 */
void init_read(void) {
  init_signals(0x00);
  return;
}

/*
 * init_write --
 *    initializes port-states for writing signallines
 *
 *    the typewriter's signal lines require not more than 9mA of sinking/sourcing
 */
void init_write(void) {
  init_signals(0xFF);
  return;
}

#endif // _SIGNALS_H_
