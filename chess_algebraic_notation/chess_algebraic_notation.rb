#!/usr/bin/ruby

# Chess Algebraic Notation Cipher

# Written mostly by ChatGPT, with a little help and cleanup by Dustin D. Trammell

class ChessAlgebraicNotationCipher
	attr_reader :trans, :decode_trans

	def initialize(seed)
		# Seed the random number generator so that the translation table is deterministic
		random = Random.new(seed)

		# Build the encoding translation table
		chess_pieces = %w(K Q R N B P)
		coordinates = ('a'..'h').to_a.product((1..8).to_a)
		characters = (('A'..'Z').to_a + ('0'..'9').to_a + %w(! " # $ % & ' ( ) * + , - . : ; < = > ? @ [ ] ^ _ ` ~) + [' '] )
		@trans = Hash[characters.shuffle(random: random).zip(coordinates.map { |c| chess_pieces.sample(random: random) + c.join }).to_h]

		# The decoding translation table is the inverse of the encoding table
		@decode_trans = @trans.invert
	end

	# Encode plaintext
	def encode(plaintext)
		encoded = ""

		# Step through the plaintext characters, translated to uppercase
		plaintext.upcase.each_char do |c|
			# Encode the character with its translation
			if @trans[c]
				encoded += @trans[c] + " "
			else
				# Skip any characters we can't encode
			end
		end
		return encoded.chop
	end

	# Decode ciphertext
	def decode(ciphertext)
		decoded = ""

		# Step through the ciphertext one value at a time
		ciphertext.scan(/\w+/) do |c|
			# Decode the character to ASCII
			if @decode_trans[c]
				decoded += @decode_trans[c]
			else
				# Error if there is no translation for the value
				raise "ERROR: Sequence '%s' not found in translation table." % [ c ]
			end
		end
		return decoded
	end
end

# Ensure there are two commandline arguments
raise "USAGE: #{$0} [-e | -d] \"String to be encoded or decoded\"" if ARGV.size < 2

# Instantiate the encoder
chess = ChessAlgebraicNotationCipher.new( seed = 3 ) # Change seed to get a different translation table

if $DEBUG
	puts "Translation Table:"
	pp chess.trans
	puts ""
	puts "Decode Table:"
	pp chess.decode_trans
end

case ARGV[0]
when '-e'
	# Encode
	puts "Encoding:   \"#{ARGV[1]}\""
	ciphertext = chess.encode( ARGV[1] )
	puts "Ciphertext: \"#{ciphertext}\""
when '-d'
	# Decode
	puts "Decoding:  \"#{ARGV[1]}\""
	cleartext = chess.decode( ARGV[1] )
	puts "Cleartext: \"#{cleartext}\""
else
	raise "ERROR: First argument must be either -e or -d for encode or decode, respectively." if mode != '-e' || mode != '-d'
end

