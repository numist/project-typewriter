project-typewriter
==================

Background
----------

This code implements the project described in my [blog post](http://numist.net/post/2010/project-typewriter.html) of converting a Brother typewriter into a teletype using an Arduino.

Organization
------------

* [`debounce.h`](https://github.com/numist/project-typewriter/blob/master/debounce.h) - simple, fast 2-bit debouncer
* [`keycodes.h`](https://github.com/numist/project-typewriter/blob/master/keycodes.h) - keyboard layout map in terms of scan and signal lines
* [`loremipsum.py`](https://github.com/numist/project-typewriter/blob/master/loremipsum.py) - userspace program for testing printing over serial
* [`signals.h`](https://github.com/numist/project-typewriter/blob/master/signals.h) - provides signal mappings for current board and functions for writing them
* [`signals_duemilanove.h`](https://github.com/numist/project-typewriter/blob/master/signals_duemilanove.h) - signal mappings for using the Arduino Duemilanove (and other Arduino-compliant boards based on the ATmega168 and ATmega328)
* [`signals_mega.h`](https://github.com/numist/project-typewriter/blob/master/signals_mega.h) - signal mappings for using the Arduino Mega (and other Arduino-compliant boards based on the ATmega1280)
* [`typewriter.pde`](https://github.com/numist/project-typewriter/blob/master/typewriter.pde) - core logic

PROGMEM
-------

People often find this project searching for how to use PROGMEM. There's not enough space in RAM for for the key lookup tables on the ATmega168, so PROGMEM is used in [`keycodes.h`](https://github.com/numist/project-typewriter/blob/master/keycodes.h#L87) to keep them in program memory. To access data that's in PROGMEM, [`typewriter.pde` uses `pgm_read_word_near`](https://github.com/numist/project-typewriter/blob/master/typewriter.pde#L308) (you can also use `pgm_read_byte_near`) to read the data.

For more information about PROGMEM, see the [Arduino Reference](http://www.arduino.cc/en/Reference/PROGMEM).

History
-------

This code was finished in 2010 and hasn't been developed much since. At the time of publishing there were no known bugs, and the only feature missing was flow control (hence the timing delays in [`loremipsum.py`](https://github.com/numist/project-typewriter/blob/master/loremipsum.py#L21)). 

However, any project with external dependencies will break as the world turns, so it is not guaranteed to work. I haven't reflashed the typewriter in over a year, so at this point the code is academic.

Credits
-------

The code in `debouncer.h` was originally provided by [Ben Holt](http://twitter.com/bjh). My modifications were mostly superficial in nature, though I did add a few optimizations.

The more tricky debugging (like diagnosing the RAM overflow bug that necessitated using PROGMEM on the ATmega168) was assisted by [Micah Scott](http://scanlime.org/).

Thanks to Cindy for putting up with me when I ignored everything except my desk for a few days. Again.
