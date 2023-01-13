#!/usr/bin/ruby

class ZodiacCipher

$ZODIAC = [
	{
		:sign       => 'Aries',
		:house      => 1,
		:symbol     => '♈︎',
		:gloss      => 'Ram',
		:sunsigndates => {
			:begin => '03-21',
			:end   => '04-19'
		},
		:polarity   => :positive,
		:modality   => :cardinal,
		:triplicity => :fire,
		:season     => {
			:northern => :spring,
			:southern => :autumn
		},
		:ruler      => {
			:modern  => :mars,
			:classic => :mars
		}
	},
	{
		:sign       => 'Taurus',
		:house      => 2,
		:symbol     => '♉︎',
		:gloss      => 'Bull',
		:sunsigndates => {
			:begin => '04-20',
			:end   => '05-20'
		},
		:polarity   => :negative,
		:modality   => :fixed,
		:triplicity => :earth,
		:season     => {
			:northern => :spring,
			:southern => :autumn
		},
		:ruler      => {
			:modern  => :venus,
			:classic => :venus
		}
	},
	{
		:sign     => 'Gemini',
		:house    => 3,
		:symbol   => '♊︎',
		:polarity => :positive,
	},
	{
		:sign     => 'Cancer',
		:house    => 4,
		:symbol   => '♋︎',
		:polarity => :negative,
	},
	{
		:sign     => 'Leo',
		:house    => 5,
		:symbol   => '♌︎',
		:polarity => :positive,
	},
	{
		:sign     => 'Virgo',
		:house    => 6,
		:symbol   => '♍︎',
		:polarity => :negative,
	},
	{
		:sign     => 'Libra',
		:house    => 7,
		:symbol   => '♎︎',
		:polarity => :positive,
	},
	{
		:sign     => 'Scorpio',
		:house    => 8,
		:symbol   => '♏︎',
		:polarity => :negative,
	},
	{
		:sign     => 'Sagittarius',
		:house    => 9,
		:symbol   => '♐︎',
		:polarity => :positive,
	},
	{
		:sign     => 'Capricorn',
		:house    => 10,
		:symbol   => '♑︎',
		:polarity => :negative,
	},
	{
		:sign     => 'Aquarius',
		:house    => 11,
		:symbol   => '♒︎',
		:polarity => :positive,
	},
	{
		:sign     => 'Pisces',
		:house    => 12,
		:symbol   => '♓︎',
		:polarity => :negative,
	}
]

	# Return a random zodiac symbol that's parity matches the bit argument. 1 is :positive, 0 is :negative
	def encode_binary( bit )
		raise "ERROR: bit argument (#{bit}) is neither 1 nor 0." if (bit != 1 && bit != 0)

		# Identify if we are targeting positive or negative zodiac signs
		target = bit == 1 ? :positive : :negative

		# Choose a random zodiac sign from the 6 available for the polarity
		r = rand(6) + 1
		num = r.dup

		# Step through the zodiac set until we find the one that was randomly selected
		$ZODIAC.each { |z| 
			r -= 1 if z[:polarity] == target
			if r == 0
				puts "Bit: #{bit} = #{z[:symbol]}" if $DEBUG
				puts "Chose Zodiac ##{num}: #{z[:symbol]}" if $DEBUG
				return z[:symbol].dup
			end
		}	
	
		raise "ERROR: End of method reached without returning a symbol."
	end # encode_binary

	# Return the bit associated with a zodiac symbol. :positive is 1, :negative is 0
	def decode_binary( char )

		# Search the zodiac for the symbol
		$ZODIAC.each { |z|
			# Step through the astrology symbols until there is a match
			puts "Matching: '#{char}' (#{char.ord}) == '#{z[:symbol]} (#{z[:symbol].ord})'" if $DEBUG
			if char.ord == z[:symbol].ord
				puts "MATCH!!!" if $DEBUG

				# Return polarity as binary. :positive is 1, :negative is 0
				case z[:polarity]
				when :positive
					puts 'Symbol is POSITIVE: 1' if $DEBUG
					return 1
				when :negative
					puts 'Symbol is NEGATIVE: 1' if $DEBUG
					return 0
				else
					raise 'ERROR: Zodiac polarity is neither positive nor negative'
				end
			end
		}

		raise "ERROR: End of method reached without returning a bit."
	end # decode_binary

	def encode( cleartext )
		# Unpack the string into binary, represent as a string of 1's and 0's
		bitstring = cleartext.unpack('B*').join
		puts "Bitstring:  #{bitstring}" if $VERBOSE

		# Encode
		ciphertext = ''
		bitstring.split('').each { |c|
			puts "Encoding: #{c}" if $DEBUG
			s = self.encode_binary( c.to_i )
			puts "Encoded:  #{s}" if $DEBUG

			ciphertext << s
		}

		return ciphertext
	end # encode

	# Decode string of astrology symbols
	def decode( ciphertext )
		# Step through characters and convert to bitstring
		bitstring = ''
		ciphertext.chars.each { |c|
			# Skip the variation selector characters
			next if c.ord == 65038

			puts "Matching: %s" % [ c ] if $DEBUG

			# Translate the symbol into a bit and add it to the bitstring
			b = self.decode_binary( c )
			bitstring << b.to_s if b

			puts "Bitstring: %s" % [ bitstring ] if $DEBUG
		}
		puts "Bitstring: #{bitstring}" if $VERBOSE

		# Pack the decoded binary back into an ascii string
		# TODO: Figure out how to do this with pack
#		binary = bitstring.to_i(2)
#		result = binary.pack('b*')

		cleartext = ''
		bitstring.scan(/[01]{8}/).map { |e|
			e.to_i(2)
		}.inject cleartext, &:concat

		return cleartext
	end # decode

end # Class ZodiacCipher

# Ensure there are two commandline arguments
raise "USAGE: #{$0} [-e | -d] \"String to be encoded or decoded\"" if ARGV.size < 2

# Instantiate the encoder
zodiac = ZodiacCipher.new

case ARGV[0]
when '-e'
	# Encode
	puts "Encoding:   \"#{ARGV[1]}\""
	ciphertext = zodiac.encode( ARGV[1] )
	puts "Ciphertext: \"#{ciphertext}\""
when '-d'
	# Decode
	puts "Decoding:  \"#{ARGV[1]}\""
	cleartext = zodiac.decode( ARGV[1] )
	puts "Cleartext: \"#{cleartext}\""
else
	raise "ERROR: First argument must be either -e or -d for encode or decode, respectively." if mode != '-e' || mode != '-d'
end

