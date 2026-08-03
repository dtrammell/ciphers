#!/usr/bin/env ruby
# frozen_string_literal: true

# Jumpsled Cipher
# Designed by I)ruid & NOVA, 2026-08-03
#
# The Jumpsled Cipher is a puzzle cipher that walks around a circular array
# of letters. At each step it jumps forward by the current letter's value;
# if that slot has already been rotated, it "sleds" linearly forward until
# it finds the next unrotated slot. Hence the name "jumpsled".
#
# Rules of the cipher:
#   * Letters are A-Z only; all other characters are stripped and input is upcased.
#   * A=1, B=2, ..., Z=26.
#   * rot(letter, v) shifts the letter forward v positions in the alphabet,
#     wrapping mod 26. v=26 is a no-op.
#   * Encoding rotates every letter exactly once. The first plaintext letter
#     supplies the initial jump value (the "seed") but is itself rotated later
#     when the walk lands on it.
#   * Decoding replays the same walk using the seed, records the rotations,
#     then reverses each one.
#   * Cracking brute-forces all 26 possible seeds and keeps those that are
#     self-consistent (candidate[0]'s value matches the seed and re-encoding
#     reproduces the ciphertext).

# Strip non-alphabetic characters and upcase the text.
def clean(text)
  text.upcase.gsub(/[^A-Z]/, "")
end

# Letter value: A=1, B=2, ..., Z=26.
def val(letter)
  letter.ord - "A".ord + 1
end

# Rotate a letter forward by v positions.
def rot(letter, v)
  return letter if v == 26

  (((val(letter) - 1 + v) % 26) + "A".ord).chr
end

# Rotate a letter backward by v positions.
def rot_back(letter, v)
  (((val(letter) - 1 - v) % 26) + "A".ord).chr
end

# Encode plaintext. Returns [ciphertext, seed_letter].
def encode(plaintext)
  s = clean(plaintext).chars
  n = s.length
  raise "empty plaintext" if n.zero?

  seed = s[0]
  done = Array.new(n, false)
  pos = 0
  v = val(s[0])

  until done.all?
    t = (pos + v) % n
    t = (t + 1) % n while done[t]
    s[t] = rot(s[t], v)
    done[t] = true
    v = val(s[t])
    pos = t
  end

  [s.join, seed]
end

# Decode ciphertext using the original first-letter seed.
def decode(ciphertext, seed_letter)
  s = clean(ciphertext).chars
  n = s.length
  raise "empty ciphertext" if n.zero?

  done = Array.new(n, false)
  pos = 0
  v = val(seed_letter)
  ops = []

  until done.all?
    t = (pos + v) % n
    t = (t + 1) % n while done[t]
    done[t] = true
    ops << [t, v]
    v = val(s[t])
    pos = t
  end

  plain = s.dup
  ops.each do |idx, jump|
    plain[idx] = rot_back(plain[idx], jump)
  end

  plain.join
end

# Brute-force all 26 seeds and return consistent (seed, plaintext) pairs.
def crack(ciphertext)
  results = []

  ("A".."Z").each do |seed|
    candidate = decode(ciphertext, seed)
    next unless val(candidate[0]) == val(seed)

    encoded, = encode(candidate)
    results << [seed, candidate] if encoded == ciphertext
  end

  results
end

def usage
  puts "Usage:"
  puts "  ruby jumpsled.rb encode \"plaintext\""
  puts "  ruby jumpsled.rb decode CIPHERTEXT SEED"
  puts "  ruby jumpsled.rb crack CIPHERTEXT"
end

case ARGV[0]
when "encode"
  if ARGV.length != 2
    usage
    exit 1
  end
  ciphertext, seed = encode(ARGV[1])
  puts "#{ciphertext} #{seed}"
when "decode"
  if ARGV.length != 3
    usage
    exit 1
  end
  puts decode(ARGV[1], ARGV[2])
when "crack"
  if ARGV.length != 2
    usage
    exit 1
  end
  crack(ARGV[1]).each do |seed, plaintext|
    puts "#{seed} #{plaintext}"
  end
else
  usage
  exit 1
end
