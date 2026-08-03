# Jumpsled Cipher

A cipher that walks around a circular ring of letters, jumping forward by however far the current letter "counts," and rotating whatever it lands on. When a jump lands on a spot that's already been visited, it doesn't jump again — it slides forward one letter at a time (wrapping around the ring) until it finds an unrotated spot. That linear-probe slide is where the name comes from: it resembles a NOP sled, jumping and then sliding until it lands somewhere useful.

*Designed by I)ruid & NOVA, 2026-08-03.*

## How It Works

**Preprocessing:** the input is upcased and everything that isn't `A`-`Z` is stripped out. Letters are valued `A=1, B=2, ... Z=26`. The cleaned letters are laid out at positions `0` through `N-1` on a circular ring (position `N-1` wraps back around to position `0`).

**Encoding** walks the ring, rotating every letter exactly once:

1. Start at position `0`. The first letter's value becomes the initial jump value `v` — this letter is also the **seed** (see below).
2. Jump forward `v` positions (mod `N`) from the current position to get a target.
3. If the target has already been rotated, **slide** forward one position at a time (wrapping mod `N`) until an unrotated position is found. This is the "sled."
4. Rotate the letter at the target forward by `v` positions in the alphabet (mod 26; a jump value of exactly `26` is a no-op rotation, since shifting by a full alphabet returns the same letter).
5. Mark the target rotated. The **target's new (post-rotation) value** becomes the next jump value `v`, and the target becomes the current position.
6. Repeat until every letter has been rotated exactly once.

**The seed.** The walk's very first jump value comes from the first plaintext letter — but that same letter gets rotated later when the walk eventually lands back on position `0`, destroying the value that started everything. Without a separate record of it, there'd be no way to know what value kicked off the walk. So the original first letter is carried alongside the ciphertext as the **seed** (also called the key) — it's the one piece of information decoding needs that isn't recoverable from the ciphertext alone.

**Decoding is a forward replay, not a reversal.** Because every letter is rotated exactly once, its *final* ciphertext value is exactly the value that drove the *next* jump during encoding. So decoding starts back at position `0` with `v` set to the seed's value, replays the identical jump-and-slide walk against the ciphertext (tracking which positions have been visited, same as encoding), and records each `(position, rotation amount)` pair as it goes. Once the whole walk has been replayed, each letter is rotated *backward* by its recorded amount, recovering the plaintext.

**Cracking** doesn't need the seed at all — it brute-forces all 26 possible seed letters. For each candidate seed, it decodes the ciphertext and checks two self-consistency conditions: does the resulting candidate plaintext's first letter actually match the seed used to decode it, and does re-encoding that candidate plaintext reproduce the exact original ciphertext? Only self-consistent candidates are kept. Typically one or two seeds survive this filter — see below for why a false survivor can still show up, and how to tell it apart from the real message.

### Worked Example: Encoding `"ATTACKATDAWN"`

The cleaned plaintext has 12 letters, laid out at positions 0–11:

| pos | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| letter | A | T | T | A | C | K | A | T | D | A | W | N |

The seed is `A` (value 1). Here's the full walk, step by step:

| step | pos | v | raw target | landed on | note | rotation |
|---|---|---|---|---|---|---|
| 1 | 0 | 1 | 1 | 1 | — | `T`→`U` |
| 2 | 1 | 21 | 10 | 10 | — | `W`→`R` |
| 3 | 10 | 18 | 4 | 4 | — | `C`→`U` |
| 4 | 4 | 21 | 1 | 2 | pos 1 already rotated, slides forward one | `T`→`O` |
| 5 | 2 | 15 | 5 | 5 | — | `K`→`Z` |
| 6 | 5 | 26 | 7 | 7 | v=26 is a no-op rotation | `T`→`T` |
| 7 | 7 | 20 | 3 | 3 | — | `A`→`U` |
| 8 | 3 | 21 | 0 | 0 | — | `A`→`V` |
| 9 | 0 | 22 | 10 | 11 | pos 10 already rotated, slides forward one | `N`→`J` |
| 10 | 11 | 10 | 9 | 9 | — | `A`→`K` |
| 11 | 9 | 11 | 8 | 8 | — | `D`→`O` |
| 12 | 8 | 15 | 11 | 6 | pos 11 already rotated, slides all the way around to 6 | `A`→`P` |

After 12 steps, all 12 positions have been rotated exactly once, and the walk terminates. Reading the final rotated letters back off by position gives the ciphertext:

```
pos:    0  1  2  3  4  5  6  7  8  9  10 11
letter: V  U  O  U  U  Z  P  T  O  K  R  J
```

```
$ ruby jumpsled.rb encode "ATTACKATDAWN"
VUOUUZPTOKRJ A
```

Notice step 6: the jump value happens to be exactly `26` (`Z`'s letter, or one whose rotation lands the value at a multiple of 26), which means the rotation at that step is a no-op — `T` stays `T`, even though the position still gets marked as rotated and consumes its turn in the walk. Also notice steps 4, 9, and 12: as more positions fill up, jumps increasingly land on already-visited spots and have to slide — step 12 slides all the way from position 11 to position 6 because everything in between had already been claimed.

### Decoding

```
$ ruby jumpsled.rb decode VUOUUZPTOKRJ A
ATTACKATDAWN
```

Decoding replays the exact same walk (starting `v` = value of seed `A` = 1), which will visit positions in the identical order (1, 10, 4, 2, 5, 7, 3, 0, 11, 9, 8, 6) and record the same 12 rotation amounts — then un-rotates each ciphertext letter at those positions by those amounts to recover `ATTACKATDAWN`.

### Cracking

Since the seed is only a single letter, brute-forcing all 26 possibilities and checking which ones decode self-consistently is cheap:

```
$ ruby jumpsled.rb crack VUOUUZPTOKRJ
A ATTACKATDAWN
X XZZACKUTDAVO
```

Two seeds pass the self-consistency check here, but only one — `A` → `ATTACKATDAWN` — reads as an actual message. The other, `X` → `XZZACKUTDAVO`, is a **decoy**: it satisfies both consistency conditions (its first letter is `X`, and re-encoding it reproduces the same ciphertext) but the result is gibberish. This is a real, observed property of the cipher, not a bug — collisions like this are rare but not impossible with only 26 possible seeds, and it's part of what makes cracking a ciphertext by hand or by brute force an interesting little puzzle rather than a trivial lookup: you still have to use judgment (or a dictionary/frequency check) to pick the real plaintext out of the survivors.

Longer messages tend to have fewer (often zero) decoys, since there's more ciphertext constraining the self-consistency check:

```
$ ruby jumpsled.rb crack IFISKQTYRVRXXIKDIMAQEUVFWXNWLKGQQSOGNZZRTZNSHDL
L LOREMIPSUMDOLORSITAMETCONSECTETURADIPISCINGELIT
```

But decoys aren't rare edge cases limited to short messages either:

```
$ ruby jumpsled.rb crack JIAPYNZQWYOEVJAPSUZBGGICRASLHCBQDKDG
B BEYOURSELFEVERYONEELSEISALREADYTAKEN
F FAWOCBTJEFEVEYYONEELSEISALRIADUTDHEN
```

## Usage

```
ruby jumpsled.rb encode "plaintext"
ruby jumpsled.rb decode CIPHERTEXT SEED
ruby jumpsled.rb crack CIPHERTEXT
```

- `encode "plaintext"` — cleans and encodes the given text, printing the ciphertext and the seed letter, space-separated.
- `decode CIPHERTEXT SEED` — decodes ciphertext using the given single-letter seed, printing the recovered plaintext.
- `crack CIPHERTEXT` — brute-forces all 26 seeds without needing the key, printing every self-consistent `(seed, candidate plaintext)` pair found, one per line.

### Verified Examples

```
$ ruby jumpsled.rb encode "ATTACKATDAWN"
VUOUUZPTOKRJ A

$ ruby jumpsled.rb decode VUOUUZPTOKRJ A
ATTACKATDAWN

$ ruby jumpsled.rb crack VUOUUZPTOKRJ
A ATTACKATDAWN
X XZZACKUTDAVO

$ ruby jumpsled.rb encode "Lorem ipsum dolor sit amet consectetur adipiscing elit"
IFISKQTYRVRXXIKDIMAQEUVFWXNWLKGQQSOGNZZRTZNSHDL L

$ ruby jumpsled.rb decode IFISKQTYRVRXXIKDIMAQEUVFWXNWLKGQQSOGNZZRTZNSHDL L
LOREMIPSUMDOLORSITAMETCONSECTETURADIPISCINGELIT

$ ruby jumpsled.rb crack IFISKQTYRVRXXIKDIMAQEUVFWXNWLKGQQSOGNZZRTZNSHDL
L LOREMIPSUMDOLORSITAMETCONSECTETURADIPISCINGELIT

$ ruby jumpsled.rb encode "Be yourself everyone else is already taken"
JIAPYNZQWYOEVJAPSUZBGGICRASLHCBQDKDG B

$ ruby jumpsled.rb decode JIAPYNZQWYOEVJAPSUZBGGICRASLHCBQDKDG B
BEYOURSELFEVERYONEELSEISALREADYTAKEN

$ ruby jumpsled.rb crack JIAPYNZQWYOEVJAPSUZBGGICRASLHCBQDKDG
B BEYOURSELFEVERYONEELSEISALREADYTAKEN
F FAWOCBTJEFEVEYYONEELSEISALRIADUTDHEN
```

Note that decoding requires the exact cleaned (uppercased, letters-only) ciphertext and matching seed — see the plaintext preprocessing rules above.

## Notable Properties, Quirks & Limitations

- **Guaranteed termination in exactly N steps.** Every letter is rotated exactly once, no more and no less — the walk cannot loop forever or leave a letter untouched, because once a target is marked rotated it's permanently excluded from being a landing spot again, and there are only `N` positions to fill.
- **The keyspace is tiny — 26 possible seeds.** This is a puzzle cipher, not real cryptography: brute-forcing every seed and checking self-consistency (as `crack` does) is trivial. The interesting part isn't the search space, it's untangling the walk itself.
- **Single-letter changes avalanche through the whole walk.** Because each step's jump value depends on the *rotated* value of the previous target, changing even one letter of the plaintext changes that letter's rotated value, which changes the next jump distance, which changes which position gets landed on next, and so on — a small edit near the start of the message can completely rearrange the back half of the walk and produce a very different ciphertext.
- **Late-stage jumps degenerate into pure slides.** Early in the walk there's plenty of open ring to jump into, so slides are short or nonexistent. As more positions fill up, an increasing fraction of jumps land on already-rotated spots and have to slide — sometimes a long way, as seen in the worked example above where step 12 slides most of the way around the ring because nearly everything was already claimed.
- **A jump value of exactly 26 is a no-op rotation.** `rot(letter, 26)` returns the letter unchanged (see step 6 in the worked example: `T` rotated by 26 stays `T`) — but the position is still consumed and still counts as visited, it just doesn't change the letter that happens to land there.
- **Cracking can turn up "decoy" seeds** — self-consistent (seed, candidate) pairs that pass both checks (first letter matches, re-encoding round-trips) but decode to gibberish rather than the real message. These aren't a bug; they're a natural consequence of a 26-letter keyspace occasionally producing a coincidental match. When more than one candidate survives cracking, you need to eyeball the results (or run them through a language check) to pick out the real plaintext — see the `ATTACKATDAWN` and "Be yourself" examples above, both of which produced one real message and one decoy.
