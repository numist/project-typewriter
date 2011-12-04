/*
 * Copyright © 2009 Benjamin Holt & Scott Perry
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

/////  Debouncer  //////
#ifndef _DEBOUNCE_H_
#define _DEBOUNCE_H_ 1
#include <stdint.h>

struct debounceState {
  uint8_t db0;    // counter bit 0
  uint8_t db1;    // counter bit 1
  uint8_t state;  // debounced state
};

/*
 * debounce --
 *    the debouncer is based on a stacked counter implementation, with each bit
 *    getting its own 2-bit counter.  when a bit changes, a call to debounce
 *    will increment that bit's counter. when it overflows, the change is
 *    comitted to the final debounced state.
 *
 * args:
 *    sample - the current state
 *    debouncer - the state variables of the debouncer
 *
 * returns: bits that have changed in the final debounced state
 */
uint8_t debounce(uint8_t sample, struct debounceState *debouncer) {
  uint8_t delta, changes;

  // Set delta to changes from last stable state
  delta = sample ^ debouncer->state;

  // Increment counters and reset any unchanged bits
  debouncer->db1 = ((debouncer->db1) ^ (debouncer->db0)) & delta;
  debouncer->db0  = ~(debouncer->db0) & delta;

  // update state & calculate returned change set
  changes = ~(~delta | (debouncer->db0) | (debouncer->db1));
  debouncer->state ^= changes;

  return changes;
}

#endif // _DEBOUNCE_H_
