# Chess Algebraic Notation Cipher

A substitution cipher that disguises plaintext as a sequence of chess moves. Each character of your message is mapped to a "move" — a chess piece letter plus a board coordinate (e.g. `Kd5`, `Qb7`, `Nf4`) — using a translation table built from a deterministic random seed. The output reads like a list of moves from a chess game, but it's actually your secret message.

## How It Works

The cipher builds two sets and randomly pairs them up:

1. **Chess "moves"** — every combination of a chess piece (`K`, `Q`, `R`, `N`, `B`, `P`) and a board coordinate (`a1` through `h8`), for 6 × 64 = 384 possible moves.
2. **Characters** — the uppercase alphabet (`A`-`Z`), digits (`0`-`9`), a set of common punctuation/special characters (`! " # $ % & ' ( ) * + , - . : ; < = > ? @ [ ] ^ _ \` ~`), and a space — 63 characters total.

A seeded `Random` instance shuffles the character set and assigns each character a randomly-sampled piece+coordinate move, building an encode table (character → move) and its inverse, the decode table (move → character). Because the random number generator is seeded (default: `3`), the same seed always produces the same translation table — encoding and decoding are only compatible when both sides use the same seed.

To encode, the plaintext is uppercased and each character is looked up in the table; the resulting moves are joined with spaces. Characters that aren't in the 63-character set (lowercase letters are uppercased first, but accented characters, most Unicode, etc. are not in the table) are silently dropped from the output.

To decode, the ciphertext is split on whitespace into individual move tokens, and each is looked up in the inverted table to recover the original character.

### Worked Example (seed 3, the default)

```
$ ruby chess_algebraic_notation.rb -e "HELLO WORLD"
Encoding:   "HELLO WORLD"
Ciphertext: "Kd5 Qb7 Nd3 Nd3 Nf4 Qf1 Qe8 Nf4 Bf2 Nd3 Ph5"

$ ruby chess_algebraic_notation.rb -d "Kd5 Qb7 Nd3 Nd3 Nf4 Qf1 Qe8 Nf4 Bf2 Nd3 Ph5"
Decoding:  "Kd5 Qb7 Nd3 Nd3 Nf4 Qf1 Qe8 Nf4 Bf2 Nd3 Ph5"
Cleartext: "HELLO WORLD"
```

Note that repeated letters map to the same move every time (`L` is always `Nd3` under seed 3), since the translation table is a fixed 1:1 substitution for a given seed — this is a simple substitution cipher, not a polyalphabetic one, so it inherits the usual weaknesses of substitution ciphers (frequency analysis, etc.) once an attacker has enough ciphertext.

## Usage

```
ruby chess_algebraic_notation.rb [-e | -d] "String to be encoded or decoded"
```

- `-e` — encode the given plaintext string
- `-d` — decode the given ciphertext string (space-separated moves)

Both arguments are required; the script raises an error and prints a usage message if either is missing.

### Examples

Encoding mixed-case text with punctuation:

```
$ ruby chess_algebraic_notation.rb -e "Attack at Dawn!"
Encoding:   "Attack at Dawn!"
Ciphertext: "Rh2 Kg8 Kg8 Rh2 Ke7 Kg7 Qf1 Rh2 Kg8 Qf1 Ph5 Rh2 Qe8 Kb2 Kd2"
```

Decoding it back:

```
$ ruby chess_algebraic_notation.rb -d "Rh2 Kg8 Kg8 Rh2 Ke7 Kg7 Qf1 Rh2 Kg8 Qf1 Ph5 Rh2 Qe8 Kb2 Kd2"
Decoding:  "Rh2 Kg8 Kg8 Rh2 Ke7 Kg7 Qf1 Rh2 Kg8 Qf1 Ph5 Rh2 Qe8 Kb2 Kd2"
Cleartext: "ATTACK AT DAWN!"
```

Decoding a token that isn't in the translation table raises an error naming the offending sequence:

```
$ ruby chess_algebraic_notation.rb -d "Zz9"
chess_algebraic_notation.rb: ... ERROR: Sequence 'Zz9' not found in translation table. (RuntimeError)
```

### Debug Mode

Run with Ruby's `-d` (debug) flag to dump the full encode and decode translation tables before the operation runs:

```
ruby -d chess_algebraic_notation.rb -e "TEST"
```

## Changing the Seed

The seed is hardcoded in the script (`chess = ChessAlgebraicNotationCipher.new( seed = 3 )`). Edit this value to generate a different translation table — but remember both the encoder and decoder must use the same seed for messages to round-trip correctly. There's currently no CLI flag for the seed; it's a code edit.

## Notable Properties, Quirks & Limitations

- **Deterministic per seed.** The same seed always yields the same translation table, so encoding/decoding is repeatable and shareable (just agree on a seed).
- **Case is not preserved.** Plaintext is uppercased before encoding, and decoded output comes back in uppercase, so `Attack` becomes `ATTACK` after a round trip.
- **Unsupported characters are silently dropped**, not errored, during encoding. Only `A`-`Z`, `0`-`9`, the space, and a specific punctuation set (`! " # $ % & ' ( ) * + , - . : ; < = > ? @ [ ] ^ _ \` ~`) are in the table. Accented letters, emoji, and most other Unicode input will vanish from the ciphertext without warning.
- **63 characters map onto 384 possible moves**, so most possible "moves" are never used in any given translation table — only 63 of them are assigned.
- **The `-e`/`-d` mode-selection error path has a bug**: passing an unrecognized first argument (anything other than `-e` or `-d`) raises a `NameError` (`undefined local variable or method 'mode'`) instead of the intended usage error, because the `else` branch references an undefined variable. Always pass exactly `-e` or `-d`.
- **Ciphertext looks plausible as chess notation** at a glance (piece letter + file + rank), which is the whole point — it's a novelty/puzzle cipher for hiding messages in something that looks like a chess move list, not a cryptographically strong cipher.
