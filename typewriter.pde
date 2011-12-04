/*
 * Copyright © 2009 Scott Perry
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associapted documentation
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

/*
 * preprocessor macros
 */

#define DUEMILANOVE

// disables use of Serial in the reading functions
//#define DEBUG_WRITES

/*
 * disables flooding the typewriter's lines to prevent passing keys when there
 * is nothing being actively written.
 */
//#define KEYBOARD_PASSTHROUGH

/*
 * TODO: though I'm tempted to throw the metapass idea out, it would still be
 * interesting to see why it's broken. it doesn't make a lot of sense.
 */
//#define METAPASS

// TODO: do a final review of plswrite, maybe even improve it

/*
 * system status (LED)
 * in the future this can be used for flow control (with STS).
 */
#define LED 13

// measured in scans, more or less arbitrarily chosen.
#define KEYPRESS_DURATION 3
#define KEYPRESS_GAP 2

// measured in ms
#define SCANLINE_INTERVAL 6

// measured in… baud
#define BAUD 115200

// helper functions
#define LONIBBLE(x) ((x) & 0x0F)
#define HINIBBLE(x) (((x) >> 4) & 0x0F)
#define LOHINIBBLE(x) (((x) >> 8) & 0x0F)
#define BIT(x) (0x01 << (x))
#define MASK(x) (~(0x01 << (x)) & 0xFF)

/*
 * includes
 */

// functions for interacting with the scan/signal lines. no logic.
#include "signals.h"

// tables of key codes for reading and writing
#include "keycodes.h"

// debouncer for tracking scanline state
#include "debounce.h"

/*
 * global state
 */

// loop-local persistant state
struct {
  // debouncer for catching scanline changes
 debounceState debouncer;

  // the time of the last scanline transition, in ms
  uint32_t scanedge;
} loopstate;

// input signal state
uint8_t signal_tracker[] = {
  0xFF, 0xFF, 0xFF, 0xFF,
  0xFF, 0xFF, 0xFF, 0xFF
};

// bitfield of width 3.  what a waste
uint8_t meta_key_state;

#ifdef PLSWRITE
/*
 * key code the read side would like to be written by the write side
 */
uint8_t plswrite;
#endif

// write-local persistant state
struct {
  // counts how long the current write cycle has been, or 0 when not writing
  uint8_t writing;

  // the character being written, 0 when not writing
  uint8_t character;

  // meta key(s) associated with character.  stale when character is 0
  uint8_t meta:4;

  // scan line associated with character.  stale when character is 0
  uint8_t scan:3;

  // signal line associated with character.  stale when character is 0
  uint8_t signal:3;
} writestate;


/*
 * read_keydown --
 *    actions to be taken when a key is pressed.  includes:
 *      * meta key state tracking
 *      * serial output of appropriate codes based on previous state
 *
 * args:
 *    keycode - the keycode for the key held down
 */
void read_keydown(uint8_t keycode) {
  // meta key states
  if(HINIBBLE(keycode) == 0x01) {
    if(keycode == SHIFT_LOCK) {
      keycode = SHIFT;
    }

#ifdef METAPASS
#ifdef PLSWRITE
    // update the typewriter's display to reflect the shift key being held
    if(keycode == SHIFT) {
      plswrite = SHIFT_LOCK;
    }
#endif
#endif

    meta_key_state |= LONIBBLE(keycode);
  }

#ifndef DEBUG_WRITES
  Serial.print(keycode);
#endif
}

/*
 * read_keyheld --
 *    actions to be taken while a key is held.
 *
 * args:
 *    keycode - the keycode for the key held down
 */
void read_keyheld(uint8_t keycode) {
  return;
}

/*
 * read_keyup --
 *    actions to be taken when a key is released.  currently:
 *      * meta key state tracking
 *
 * args:
 *    keycode - the keycode for the key held down
 */
void read_keyup(uint8_t keycode) {
  // meta key states
  if(HINIBBLE(keycode) == 0x01 && keycode != SHIFT_LOCK)
    meta_key_state &= 0x0F ^ LONIBBLE(keycode);

#ifdef PLSWRITE
#ifdef METAPASS
  // reset the typewriter's display to reflect shift not held
  if(keycode == SHIFT)
    plswrite = SHIFT;
#endif

  switch(keycode) {
    case RESET:
      plswrite = RESET;
      break;
  }
#endif

#ifndef DEBUG_WRITES
  Serial.print(keycode);
#endif

  return;
}

/*
 * read_getsignals --
 *    delivers the intentional signal state. this is ensured by detecting if
 *    the possibility of a current loop exists between 4 or more keycodes.
 *
 * args:
 *    scannum: the number of the scanline that the typewriter is polling
 *
 * returns:
 *    if multiple scanlines are down and multiple signal lines on the current
 *    scan are down, a cached value is used as the signal, otherwise the
 *    actual signal is used.
 */
uint8_t read_getsignals(uint8_t scannum) {
  uint8_t scans = read_scans();
  uint8_t signs = read_signs();
  int8_t numscans;
  uint8_t i;

  // if only one scanline is down, we don't have to do anything fancy.
  if((~scans & (~scans - 1) & 0xFF) == 0)
    return signs;

  /*
   * if scanline 7 is one of the lines down, don't worry—only shift and
   * shift lock live on it.
   *
   * NB: this is done in advance because the counting loop clobbers scans
   */
  if(~scans & BIT(7))
    numscans--;

  // count the number of scanlines that are lowered
  for(i = ~scans, numscans = 0; i > 0; i >>= 1)
    if(i & 0x01)
      numscans++;

  /*
   * phantom keys only appear when multiple signals are down as well as
   * multiple scans.
   */
  if(numscans > 1 && (~signs & (~signs - 1) & 0xFF)) {
    signs = signal_tracker[scannum];
  }

  return signs;

  /*
   * BUT WAIT!
   *
   * there is even more we can do here.
   *
   * RESET          >
   * x--------------x
   * |              |
   * x--------------x
   * <              NC
   *
   * in the case above, where RESET, >, and < are held (with the CODE meta
   * key also held) it is clear that all three are intentional keypresses
   * because the phantom press is an NC (Not Connected) keycode.
   *
   * searching all paths to ensure that every rectangle of sunk lines
   * contains one NC key solves the multiple-scanline problem, but is only
   * necessary when the meta keys ALT and CODE are used—in regular typing
   * the only NC keys are on the same scanline as SHIFT and SHIFT_LOCK, so
   * the more efficient approach of not counting scanline 7 when counting
   * how many scanlines are down is effective in the vast majority of cases.
   */
}

/*
 * do_read --
 *    performs a scan of the active (down) scanlines and correspondingly active
 *    signallines and reports (over Serial) the changes.
 *
 * args:
 *    scans - the current state of the scanlines, to prevent an unnecessary poll
 */
void do_read(uint8_t scans) {
  uint8_t scannum, signs;

  // avoid getting called out of range
  if(scans == 0xFF) return;
  // get the active scanline
  for(scannum = 0; (BIT(scannum) & ~scans & 0xFF) == 0; scannum++);

  signs = read_getsignals(scannum);

  for(uint8_t j = 1, signum = 0; j > 0; j <<= 1, signum++) {
    uint8_t keycode;

    // common case: no key down.
    if((j & signs) && (j & signal_tracker[scannum]))
      continue;

    // do the keycode lookup here since all execution paths need it
    keycode = pgm_read_word_near((uint8_t *)keycodes + ((meta_key_state << 6) | (scannum * 8 + signum)));

    // next most common: key held down
    if(!(j & signs) && !(j & signal_tracker[scannum]))
      read_keyheld(keycode);
    // key pressed and key raised are equally uncommon
    else if(!(j & signs) && (j & signal_tracker[scannum]))
      read_keydown(keycode);
    else
      read_keyup(keycode);
  }

  // remember the new state
  signal_tracker[scannum] = signs;

  return;
}

/*
 * write_getcodes --
 *    looks up the writestate character's meta key requirements, signal, and
 *    scan. if the character is not supported by the typewriter, ? is used.
 *
 *    this is the only function that writes to the writestate's meta, signal,
 *    and scan members.
 */
void write_getcodes() {
    uint16_t *bank;
    uint16_t entry;
    uint8_t index;

    /*
     * not convinced this switch is necessary. we should just drop all
     * instructions to press meta keys.
     */
    switch(writestate.character) {
      case SHIFT:
        writestate.meta = 0;
        writestate.signal = 0;
        writestate.scan = 7;
        return;
      case SHIFT_LOCK:
        writestate.meta = 0;
        writestate.signal = 1;
        writestate.scan = 7;
        return;
      case CODE:
      case ALT:
        writestate.character = 0;
        writestate.writing = 0;
        writestate.meta = 0;
        return;
    }

    // get the lookup table and index for the char in question
    if(writestate.character < 0x80) {
      bank = (uint16_t *)ascii;
      index = writestate.character;
    }
    else if(writestate.character <= HALF && writestate.character >= CENT) {
      bank = (uint16_t *)extended;
      index = writestate.character - CENT;
    }
    else if(writestate.character <= OPERATE && writestate.character >= EXPR) {
      bank = (uint16_t *)control;
      index = writestate.character - EXPR;
    }

    // if not found, use ? instead!
    if (!bank || pgm_read_word_near(bank + index) == NC16) {
      writestate.character = '?';
      write_getcodes();
      return;
    }

    entry = pgm_read_word_near(bank + index);

    // for more detail on the lookup table's organization, see keycodes.h
    writestate.meta = LOHINIBBLE(entry);
    writestate.signal = HINIBBLE(entry);
    writestate.scan = LONIBBLE(entry);

    return;
}

/*
 * write_consume --
 *    consume input from the reading code or Serial, if available.
 *    set up state for writing—meta keys to hold, scan/signal lines,
 *    and write status.
 *
 *    write_consume DOES NOT BLOCK
 */
void write_consume(void) {
#ifdef PLSWRITE
  if(plswrite) {
    writestate.character = plswrite;
    plswrite = 0;
  }
  else
#endif
  if(Serial.available()) {
    writestate.character = Serial.read();
  }

  if(writestate.character) {
    // populate the writestate
    writestate.writing = 1;
    write_getcodes();

    // sanity check. if this condition is true there is a serious problem.
    if(writestate.meta > 0x07) {
      writestate.character = 0;
      writestate.writing = 0;
      Serial.print(ERR);
    }
  }

  return;
}

/*
 * write_metagen --
 *    based on the desired meta key state and the current scanline state,
 *    return the signal state needed to hold the meta keys down.
 *
 * args:
 *    meta - the meta key state, either for an character we are printing, or
 *           the meta_key_state from the read logic.
 *    scans - the current state of the scanlines
 */
uint8_t write_metagen(uint8_t meta, uint8_t scans) {
  uint8_t signals = 0xFF;

  // only the lower three bits are valid
  if(meta & 0xF8) return signals;

  // SHIFT
  if(meta & BIT(0) && scans == MASK(7))
    signals &= MASK(0);

  // CODE
  if(meta & BIT(1) && scans == MASK(6))
    signals &= MASK(7);

  // ALT
  if(meta & BIT(2) && scans == MASK(6))
    signals &= MASK(4);

  return signals;
}

/*
 * do_write --
 *    based upon the state of the scanlines, pulls down the appropriate
 *    signallines in order to type text read from Serial. this is called every
 *    time the scanlines change and settle into a new state.
 *
 * args:
 *    scans - the current state of the scanlines
 */
void do_write(uint8_t scans) {
  uint8_t signals = 0xFF;

#ifdef KEYBOARD_PASSTHROUGH
  if(!writestate.writing)
    init_read();
#endif

  /*
   * the best time to consume input is when all the scanlines are high.
   * it happens often enough—every 16ms—and nothing much is happening on
   * our end: it's 2ms of totally free time in which to do our extra work.
   */
  if(scans == 0xFF) {
    if(!writestate.writing)
      write_consume();
    else
      writestate.writing++;

    return;
  }

  if(writestate.character) {
    // hold down the appropriate meta key(s)
    if(writestate.meta)
      signals &= write_metagen(writestate.meta, scans);

    // after the meta key(s) (if applicable) have been held long enough, type the character
    if(writestate.writing > KEYPRESS_DURATION * !!writestate.meta)
      if(scans == MASK(writestate.scan))
        signals &= MASK(writestate.signal);

    // stop holding the keys, but continue blocking writes
    if(writestate.writing == KEYPRESS_DURATION * (1 + !!writestate.meta)) {
      writestate.character = 0;
    }
  }

#ifdef KEYBOARD_PASSTHROUGH
  if(writestate.writing)
#endif
  write_signs(signals);

  /*
   * wait long enough that the next keystroke, if the same, won't be
   * interpreted by the typewriter as a held key
   */
  if(writestate.writing == KEYPRESS_DURATION * (1 + !!writestate.meta) + KEYPRESS_GAP)
    writestate.writing = 0;

  return;
}

/*
 * setup --
 *    standard Arduino function.  initialize pins, ports, Serial.
 */
void setup(void) {
  // pin 2 is used for timing instrumentation
  pinMode(2, OUTPUT);

  Serial.begin(BAUD);

  /*
   * the LED pin is not connected to the typewriter's signal or scan lines
   * because it is used as output during boot, which can cause phantom keystrokes
   * on the typewriter.  that's ok, since we're using the LED pin to emit state.
   */
  digitalWrite(LED, HIGH);

  init_scans();
  init_read();
  write_signs(0xFF);

  digitalWrite(LED, LOW);
}

/*
 * loop --
 *    standard Arduino function.
 */
void loop(void) {
  uint8_t scans = read_scans();
  uint8_t changes = debounce(scans, &loopstate.debouncer);

  if(changes) {
    loopstate.scanedge = millis();

    /*
     * ensure that only one (or zero!) scanline is down
     */
    if(~loopstate.debouncer.state & (~loopstate.debouncer.state - 1) & 0xFF)
      return;


    digitalWrite(LED, HIGH);

    init_read();
    write_signs(0xFF);
    do_read(scans);

    init_write();
    do_write(scans);

    digitalWrite(LED, LOW);
  }

  /*
   * in normal operation, the scanlines change every 2ms, with a range reliably
   * between 1950 and 2050 µs. if we've waited much longer than that for a
   * change, it is safe to assume that the typewriter is resetting and has
   * pulled down the scanline for the limit switch so it can respond as
   * quickly as possible when the carriage hits it.
   *
   * when this is happening we cannot be in write mode. driving the signal
   * lines will drown out the switch when it does trigger, causing the
   * typewriter to grind the gearing on the carriage motor.
   */
  if(millis() - loopstate.scanedge >= SCANLINE_INTERVAL) {
    digitalWrite(LED, HIGH);
    init_read();
    write_signs(0xFF);

    while(loopstate.debouncer.state == read_scans());
    /*
     * sometimes there is a little bit of noise that could cause us to
     * mistakenly start polling in read/write mode. this 1ms delay should
     * be plenty to avoid the blips of noise that occur pretty rarely.
     */
    delay(1);
  }
}
