# ciphers

A collection of puzzle and novelty cipher implementations by [Dustin D. Trammell (I)ruid)](https://github.com/dtrammell). These aren't meant to be cryptographically secure — they're fun, hobbyist takes on hiding and encoding messages, each with its own gimmick.

## Ciphers

| Cipher | Description |
| --- | --- |
| [`chess_algebraic_notation`](chess_algebraic_notation/) | Substitution cipher that disguises messages as a sequence of chess moves (e.g. `Kd5 Qb7 Nd3`). |
| [`spongemock`](spongemock/) | Steganographic encoder that hides binary data in text via alternating UPPER/lower case letters ("sponge mock" text). |
| [`zodiac`](zodiac/) | Binary substitution cipher that encodes bits as randomly-chosen zodiac symbols, using sign polarity (positive/negative) to carry each `1`/`0`. |
| [`jumpsled`](jumpsled/) | Cipher that walks a circular ring of letters, jumping forward by each letter's value and sliding past already-visited spots, rotating every letter exactly once. |

More ciphers will be documented and added to this index over time — see each subdirectory for details as its README lands.
