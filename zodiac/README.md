# Zodiac Cipher

A binary substitution cipher that encodes text as a string of astrological zodiac symbols (♈︎ ♉︎ ♊︎ ...). Each bit of the message is represented by a *randomly chosen* symbol from one of two groups — the six "positive"-polarity signs or the six "negative"-polarity signs — so the same bit can come out as a different glyph every time you encode, while still decoding back to the correct bit.

## How It Works

The cipher defines the 12 zodiac signs, each tagged with a `:polarity` of either `:positive` or `:negative` (six signs per polarity, alternating around the zodiac wheel — Aries positive, Taurus negative, Gemini positive, Cancer negative, and so on):

| Polarity | Signs |
| --- | --- |
| `:positive` | Aries ♈︎, Gemini ♊︎, Leo ♌︎, Libra ♎︎, Sagittarius ♐︎, Aquarius ♒︎ |
| `:negative` | Taurus ♉︎, Cancer ♋︎, Virgo ♍︎, Scorpio ♏︎, Capricorn ♑︎, Pisces ♓︎ |

(Only Aries and Taurus carry the full metadata block in the source — house, gloss, sun-sign dates, modality, triplicity, season, ruler — the other ten signs just have `:sign`, `:house`, `:symbol`, and `:polarity`. Only `:polarity` and `:symbol` are actually used by the cipher; the extra metadata isn't read by any code path.)

**Encoding:**
1. The plaintext is unpacked into its raw bit representation (`unpack('B*')`) — every byte of the (UTF-8) string becomes 8 bits, in order, MSB first.
2. Each bit is encoded independently: a `1` picks a *random* sign from the six `:positive` signs; a `0` picks a *random* sign from the six `:negative` signs. Which specific sign gets picked is irrelevant to decoding — only its polarity matters — so the same bit value can render as any of six different symbols from one encoding run to the next.
3. The chosen signs' symbols are concatenated together with no separator to form the ciphertext.

**Decoding** reverses this: each symbol in the ciphertext is looked up to find its polarity (`:positive` → `1`, `:negative` → `0`), rebuilding the bitstring one symbol at a time. The bitstring is then chunked into 8-bit groups and each group is converted back to its byte value to reconstruct the original text.

Because decoding only cares about polarity and not which specific sign was used, **encoding is non-deterministic (every run produces different ciphertext for the same input) but always decodes correctly** — the randomness is a red herring for anyone trying to spot patterns, not information the receiver needs to know.

### A note on the symbols themselves

Each zodiac glyph in the table is actually **two Unicode characters**: the astrological symbol itself (e.g. `♈` U+2648) followed by a variation selector (`︎` U+FE0E, "text presentation selector," which just tells renderers to draw the plain glyph instead of an emoji-style one). The decoder explicitly skips over `U+FE0E` characters (`next if c.ord == 65038`) so the presentation selector doesn't get mistaken for a data symbol.

### Worked Example

```
$ ruby zodiac.rb -e "A"
Encoding:   "A"
Ciphertext: "♓︎♒︎♏︎♍︎♏︎♉︎♍︎♌︎"
```

`"A"` is `01000001` in binary. Run with debug output (`ruby -d`) to see the bit-by-bit choices for this exact run:

```
Bitstring:  01000001
Bit: 0 = ♓︎ (Pisces, negative)
Bit: 1 = ♒︎ (Aquarius, positive)
Bit: 0 = ♏︎ (Scorpio, negative)
Bit: 0 = ♍︎ (Virgo, negative)
Bit: 0 = ♏︎ (Scorpio, negative)
Bit: 0 = ♉︎ (Taurus, negative)
Bit: 0 = ♍︎ (Virgo, negative)
Bit: 1 = ♌︎ (Leo, positive)
```

Each `0` bit picked a different random sign from the six negative-polarity signs (Pisces, Scorpio, Virgo, Scorpio again, Taurus, Virgo again), and each `1` bit picked a different random sign from the six positive-polarity signs (Aquarius, Leo) — decoding only reads back the polarity, so this all correctly decodes to `01000001` = `"A"` regardless of which specific signs were rolled.

Round-tripping a full sentence — note the different, randomly-chosen symbols on every encoding run, and that mixed case survives the round trip intact (unlike some of the other ciphers in this repo, this one operates on raw bits rather than uppercasing the input first):

```
$ ruby zodiac.rb -e "Attack at Dawn!"
Encoding:   "Attack at Dawn!"
Ciphertext: "♍︎♎︎♓︎♓︎♍︎♓︎♓︎♐︎♏︎♎︎♎︎♌︎♋︎♊︎♉︎♓︎♋︎♒︎♌︎♒︎♏︎♈︎♏︎♉︎♍︎♒︎♈︎♑︎♑︎♍︎♉︎♎︎♏︎♒︎♌︎♑︎♍︎♍︎♈︎♈︎♓︎♎︎♈︎♍︎♐︎♏︎♌︎♒︎♑︎♓︎♊︎♓︎♑︎♉︎♉︎♓︎♏︎♒︎♈︎♏︎♋︎♏︎♋︎♒︎♓︎♐︎♒︎♈︎♏︎♒︎♑︎♑︎♉︎♍︎♌︎♍︎♏︎♓︎♏︎♋︎♑︎♈︎♍︎♉︎♋︎♒︎♏︎♍︎♋︎♊︎♈︎♋︎♉︎♓︎♍︎♐︎♑︎♈︎♌︎♐︎♉︎♈︎♐︎♈︎♉︎♊︎♊︎♉︎♊︎♌︎♈︎♋︎♑︎♍︎♐︎♓︎♓︎♉︎♏︎♊︎"

$ ruby zodiac.rb -d "♍︎♎︎♓︎♓︎♍︎♓︎♓︎♐︎♏︎♎︎♎︎♌︎♋︎♊︎♉︎♓︎♋︎♒︎♌︎♒︎♏︎♈︎♏︎♉︎♍︎♒︎♈︎♑︎♑︎♍︎♉︎♎︎♏︎♒︎♌︎♑︎♍︎♍︎♈︎♈︎♓︎♎︎♈︎♍︎♐︎♏︎♌︎♒︎♑︎♓︎♊︎♓︎♑︎♉︎♉︎♓︎♏︎♒︎♈︎♏︎♋︎♏︎♋︎♒︎♓︎♐︎♒︎♈︎♏︎♒︎♑︎♑︎♉︎♍︎♌︎♍︎♏︎♓︎♏︎♋︎♑︎♈︎♍︎♉︎♋︎♒︎♏︎♍︎♋︎♊︎♈︎♋︎♉︎♓︎♍︎♐︎♑︎♈︎♌︎♐︎♉︎♈︎♐︎♈︎♉︎♊︎♊︎♉︎♊︎♌︎♈︎♋︎♑︎♍︎♐︎♓︎♓︎♉︎♏︎♊︎"
Decoding:  "♍︎♎︎♓︎♓︎♍︎♓︎♓︎♐︎♏︎♎︎♎︎♌︎♋︎♊︎♉︎♓︎♋︎♒︎♌︎♒︎♏︎♈︎♏︎♉︎♍︎♒︎♈︎♑︎♑︎♍︎♉︎♎︎♏︎♒︎♌︎♑︎♍︎♍︎♈︎♈︎♓︎♎︎♈︎♍︎♐︎♏︎♌︎♒︎♑︎♓︎♊︎♓︎♑︎♉︎♉︎♓︎♏︎♒︎♈︎♏︎♋︎♏︎♋︎♒︎♓︎♐︎♒︎♈︎♏︎♒︎♑︎♑︎♉︎♍︎♌︎♍︎♏︎♓︎♏︎♋︎♑︎♈︎♍︎♉︎♋︎♒︎♏︎♍︎♋︎♊︎♈︎♋︎♉︎♓︎♍︎♐︎♑︎♈︎♌︎♐︎♉︎♈︎♐︎♈︎♉︎♊︎♊︎♉︎♊︎♌︎♈︎♋︎♑︎♍︎♐︎♓︎♓︎♉︎♏︎♊︎"
Cleartext: "Attack at Dawn!"
```

## Usage

```
ruby zodiac.rb [-e | -d] "String to be encoded or decoded"
```

- `-e` — encode the given plaintext string into zodiac symbols
- `-d` — decode a string of zodiac symbols back to plaintext

Both arguments are required; the script raises an error and prints a usage message if either is missing.

### Debug and Verbose Modes

Run with Ruby's `-d` (debug) flag to see each bit being encoded/decoded and which sign was chosen for it:

```
ruby -d zodiac.rb -e "HI"
```

Run with `-w` (which sets Ruby's `$VERBOSE`) to see just the intermediate bitstring without the full per-bit trace:

```
ruby -w zodiac.rb -e "HI"
```

## Notable Properties, Quirks & Limitations

- **Non-deterministic ciphertext, deterministic plaintext.** Because `rand()` isn't seeded and any of the six same-polarity signs can represent a given bit, encoding the same message twice produces two different-looking ciphertexts — but both decode back to the identical original message. This adds a bit of homophonic noise on top of a straightforward binary substitution, making naive symbol-frequency analysis less useful than it would be against a strict 1:1 substitution cipher (like `chess_algebraic_notation`), though the underlying scheme is still just 1 bit of information per symbol.
- **Case and all bytes are preserved.** Unlike some other ciphers in this repo, this one doesn't uppercase or otherwise transform the input first — it operates on the raw bits of whatever string you give it, so punctuation, case, and byte values round-trip exactly (for ASCII/single-byte input — see the bug below for multi-byte characters).
- **Multi-byte UTF-8 characters do not round-trip correctly.** The decoder converts each 8-bit chunk back into a character using `String#concat` with an integer, which treats that integer as a Unicode *codepoint* rather than a raw *byte*. For plain ASCII text, byte value and codepoint are the same number, so this works fine. But for any character that `unpack('B*')` splits into multiple UTF-8 bytes (accented letters, emoji, etc.), each byte gets reassembled as its own separate (wrong) Unicode character on decode instead of being recombined into the original multi-byte character — producing mojibake. For example, encoding and decoding `"café 🎉"` comes back as garbled text rather than the original string. Stick to ASCII input for reliable round-tripping.
- **Decoding an unrecognized symbol crashes.** `decode_binary` raises a generic `RuntimeError` ("ERROR: End of method reached without returning a bit.") if it's given a character that isn't one of the 12 zodiac symbols (or the variation-selector character it explicitly skips) — there's no friendlier error message identifying what the bad input was.
- **The `-e`/`-d` mode-selection error path has the same bug as `chess_algebraic_notation`**: passing an unrecognized first argument (anything other than `-e` or `-d`) raises a `NameError` (`undefined local variable or method 'mode'`) instead of the intended usage error, because the `else` branch references an undefined variable. Always pass exactly `-e` or `-d`.
- **Only two of the twelve zodiac sign entries carry full astrological metadata** (house, gloss, sun-sign date range, modality, triplicity, season, ruler) — Aries and Taurus. The remaining ten signs only have `:sign`, `:house`, `:symbol`, and `:polarity`. This has no effect on the cipher's behavior since only `:polarity` and `:symbol` are read, but it means the data table is inconsistent/incomplete if anyone tries to build on it for astrology purposes beyond the cipher itself.
