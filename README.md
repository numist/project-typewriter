project-typewriter
==================

Background
----------

This code implements the project described on my (surprisingly popular) [blog post](http://numist.net/post/2010/project-typewriter.html) on the topic of converting a Brother typewriter into a teletype using an Arduino.

Organization
------------

* `debounce.h` - simple, fast 2-bit debouncer
* `keycodes.h` - keyboard layout map in terms of scan and signal lines
* `loremipsum.py` - userspace program for testing printing over serial
* `signals.h` - provides signal mappings for current board and functions for writing them
* `signals_duemilanove.h` - signal mappings for using the Arduino Duemilanove (and other Arduino-compliant boards based on the ATmega168 and ATmega328)
* `signals_mega.h` - signal mappings for using the Arduino Mega (and other Arduino-compliant boards based on the ATmega1280)
* `typewriter.pde` - core logic

PROGMEM
-----

Often people come to this project searching for how to use PROGMEM. In the case of this project, there's not enough space in RAM for for the key lookup tables on the ATmega168, so PROGMEM is used in `keycodes.h` to keep them in program memory. To access data that's in PROGMEM, `typewriter.pde` uses `pgm_read_word_near` (you can also use `pgm_read_byte_near`) to read the data.

The best place for more detail on using PROGMEM is probably the [Arduino Reference](http://www.arduino.cc/en/Reference/PROGMEM).

History
-------

This code was finished in 2010 and hasn't been developed much since. At the time of publishing there were no known bugs, and the only feature missing was flow control (hence the timing delays in `loremipsum.py`). However, any project with external dependencies will break as the world moves forward (this project is here on github because of a retired Subversion server), so it is not guaranteed to work. I haven't needed to reflash the typewriter in over a year, so at this point this code is academic.

Credits
-------

The code in `debouncer.h` was originally provided by [Ben Holt](http://twitter.com/bjh). My modifications were mostly superficial in nature, though I did add a few optimizations.

Some of the more tricky debugging (including diagnosing the RAM overflow bug that necessitated using PROGMEM on the ATmega168) was assisted by [Beth Scott](http://scanlime.org/).

Thanks to Cindy for putting up with me when I ignored everything except my desk for a few days.