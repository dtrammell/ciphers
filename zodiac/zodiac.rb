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
		},
	},
	{
		:sign     => 'Taurus',
		:house    => 2,
		:symbol   => '♉︎',
		:polarity => :negative,
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
#		target = bit == 1 ? :positive : :negative
		if bit == 1 then
			target = :positive
		else
			target = :negative
		end

		# Choose a random zodiac sign from the 6 available for the polarity
		r = rand(6) + 1
#puts "Chose Zodiac ##{r}"

		# Step through the zodiac set until we find the one that was randomly selected
		$ZODIAC.each { |z| 
#pp z
			r -= 1 if z[:polarity] == target
			if r == 0
#puts "Bit: #{bit} = #{z[:symbol]}"
				return z[:symbol].dup
			end
		}	
	
		raise "ERROR: End of method reached without returning a symbol."
	end # get_binary_random_zodiac

	# Return the bit associated with a zodiac symbol. :positive is 1, :negative is 0
	def decode_binary( char )

		# Search the zodiac for the symbol
		$ZODIAC.each { |z|
puts "Matching: '#{char}' (#{char.ord}) == '#{z[:symbol]} (#{z[:symbol].ord})'"
#			if char == z[:symbol]
			if char.ord == z[:symbol].ord
				# Return polarity as binary. :positive is 1, :negative is 0
				case z[:polarity]
				when :positive
					return 1
				when :negative
					return 0
				else
					raise 'ERROR: Zodiac polarity is neither positive nor negative'
				end
			end
		}

		raise "ERROR: End of method reached without returning a bit."
	end

	def encode( cleartext )
		puts "Encoding:    \"#{cleartext}\""

		# Unpack the string into binary, represent as a string of 1's and 0's
		bitstring = cleartext.unpack('b*').join
		puts "Bitstring:   #{bitstring}"

		# Encode
		ciphertext = ''
		bitstring.split('').each { |c|
#puts "Encoding: #{c}"
			s = self.encode_binary( c.to_i )
#puts "Encoded:  #{s}"

			ciphertext << s
		}
		puts "Ciphertext: \"#{ciphertext}\""

		return ciphertext
	end

	# Decode string of astrology symbols
	def decode( ciphertext )
		bitstring = ''

		ciphertext.split('').each { |c|
			b = self.decode_binary( c )

			bitstring << b.to_s
		}
		puts "Bitstring: #{bitstring}"

		# Pack the decoded binary back into an ascii string
		result = bitstring.pack('a*')
		puts "Result:    \"#{result}\""

		return result
	end

end # Class ZodiacCipher

# Ensure there are two commandline arguments
raise "USAGE: #{$0} [-e | -d] \"String to be encoded or decoded\"" if ARGV.size < 2

# Instantiate the encoder
zodiac = ZodiacCipher.new

case ARGV[0]
when '-e'
	# Encode
	zodiac.encode( ARGV[1] )
when '-d'
	# Decode
	zodiac.decode( ARGV[1] )
else
	raise "ERROR: First argument must be either -e or -d for encode or decide, respectively." if mode != '-e' || mode != '-d'
end





