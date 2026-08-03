# Spongemock Cipher

A steganographic encoder that hides a binary message inside ordinary text by alternating the *case* of letters — the same visual trick as "mocking spongebob" meme text (`lIkE tHiS`), repurposed to carry a hidden payload. The message itself is invisible unless you know to look at which letters are upper- and lowercase.

## How It Works

1. **Get a bitstring.** If the message you give it looks like a string of only `0`s and `1`s, it's used directly as the binary payload. Otherwise, the message is treated as ASCII text and unpacked into its 8-bit-per-character binary representation (most-significant-bit first — `unpack('B*')`), e.g. `"HI"` becomes `0100100001001001` (`H` = `01001000`, `I` = `01001001`).
2. **Walk the covertext one character at a time.** For every character in the covertext:
   - If it's **not a letter** (space, digit, punctuation, etc.), it's copied through unchanged and does **not** consume a bit.
   - If it **is a letter** (`a`-`z` or `A`-`Z`), the next unused bit of the message decides its case: `1` → uppercase, `0` → lowercase.
3. **Loop the message if there's covertext left over.** Once every bit of the message has been consumed, the bit pointer resets to the start and the message starts repeating across the remaining letters of the covertext — so a short message can be stamped into a long covertext multiple times.
4. **Warnings, not errors, for length mismatches.** If the covertext doesn't have enough letters to hold the whole message once, you get a `Not enough cover text to encode all binary!` warning (the ciphertext is simply truncated to whatever covertext length is available). If the covertext runs out partway through a repeat pass of the message, you get a `Binary repeated but covertext ended before full repititon.` warning.

The output — the covertext with its letter casing rewritten — is the ciphertext. To anyone skimming it, it just looks like a message that's obnoxiously and inconsistently capitalized.

### Worked Example

Encoding the ASCII message `"HI"` into the covertext `"the quick brown fox jumps over the lazy dog"` (which has 35 letters — more than the 16 bits needed, so the message repeats):

```
$ ruby spongemock.rb "HI" "the quick brown fox jumps over the lazy dog"
Encoding:   "HI"
Covertext:  "the quick brown fox jumps over the lazy dog"
Message Binary: 0100100001001001
WARNING: Binary repeated but covertext ended before full repititon.
Ciphertext: "tHe qUick bRowN foX jUmpS over The LazY dOg"
```

`H` (`01001000`) and `I` (`01001001`) concatenate to `0100100001001001`. Reading the case of each letter in the ciphertext (`t`=0, `H`=1, `e`=0, `q`=0, `u`=1, `i`=0, `c`=0, `k`=0, `b`=0, `r`=1, `o`=0, `w`=0, `n`=1, `f`=0, `o`=0, `x`=1) reproduces those same 16 bits exactly — then the pattern starts over from `0100100001001001` again for the remaining letters (`jUmpS over The LazY dOg`), stopping partway through the second pass once the covertext runs out (hence the warning).

A tighter example, where the covertext has exactly enough letters for one clean pass with no repeat:

```
$ ruby spongemock.rb "HI" "abcdefghijklmnop"
Encoding:   "HI"
Covertext:  "abcdefghijklmnop"
Message Binary: 0100100001001001
Ciphertext: "aBcdEfghiJklMnoP"
```

## Usage

```
ruby spongemock.rb "message" "covertext"
```

- **First argument** — the message to hide. Give it plain ASCII text (it will be converted to binary automatically) or a literal string of `0`s and `1`s to encode raw binary directly.
- **Second argument** — the covertext to hide the message inside. Only its letters carry the payload; everything else (spaces, digits, punctuation) passes through unchanged.

There is **no decode mode** — see Limitations below.

### Examples

Encoding a binary payload directly instead of ASCII text:

```
$ ruby spongemock.rb "0100100001101001" "the quick brown fox"
Encoding:   "0100100001101001"
Covertext:  "the quick brown fox"
Binary message detected...
Message Binary: 0100100001101001
Ciphertext: "tHe qUick bROwN foX"
```

Covertext too short to hold the message even once:

```
$ ruby spongemock.rb "HELLO" "abc"
Encoding:   "HELLO"
Covertext:  "abc"
Message Binary: 0100100001000101010011000100110001001111
WARNING: Not enough cover text to encode all binary!
WARNING: Binary repeated but covertext ended before full repititon.
Ciphertext: "aBc"
```

### Debug Mode

Run with Ruby's `-d` flag to print each covertext character alongside the message bit being encoded into it:

```
ruby -d spongemock.rb "HI" "abcdefghijklmnop"
```

## Manually Decoding

The script has no working decode path (see below), but decoding by hand is straightforward given how the cipher works:

1. Read the ciphertext letter by letter, ignoring non-letters.
2. For each letter: uppercase → `1`, lowercase → `0`.
3. Group the resulting bits into bytes of 8 and unpack them as ASCII (MSB first) to recover the original text — or just read the raw bitstring if the payload wasn't ASCII to begin with.

## Notable Properties, Quirks & Limitations

- **Decoding is not implemented.** `SpongemockEncoder#decode` exists in the source as an empty method stub, and there is no CLI path or flag that calls it. This tool is currently encode-only; recovering a hidden message requires manually reversing the case pattern as described above.
- **No argument validation.** Unlike some of the other ciphers in this repo, there's no upfront check that both arguments were supplied. Running the script with zero or one argument crashes with an unhelpful `NoMethodError` (`undefined method 'match?' for nil` or `undefined method 'length' for nil`) rather than a usage message.
- **An empty string as the message is treated as valid.** `""` matches the "looks like binary" check (`/^[01]*$/` matches an empty string), so it's accepted as a zero-length binary payload — the covertext is returned completely unchanged, silently.
- **The message can repeat across the covertext.** If the covertext has more usable letters than the message has bits, the bit pointer wraps around and the message is stamped in again, potentially multiple times, filling as much of the covertext as available.
- **Non-letter characters are free real estate for the attacker/observer, not the payload.** Spaces, digits, and punctuation in the covertext pass through unchanged and don't hide anything — only the actual letters carry bits, which affects how much payload a given covertext can hold.
- **This hides data, but doesn't encrypt it.** Anyone who suspects mixed-case text and knows the scheme (or just notices oddly patterned capitalization) can decode it instantly by hand — it's steganography for fun/novelty, not confidentiality.
