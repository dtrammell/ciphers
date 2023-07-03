#!/usr/bin/ruby

class SpongemockEncoder

	# Encode
	def encode( covertext, message )
		# binary = message.unpack('b*').first # LSB
		binary = message.unpack('B*').first # MSB
		puts "Message Binary: #{binary}"
		binary = binary.split('')

		ciphertext = ''

		# Encode each binary bit into a letter in the covertext
		bincount = 0
		covertext.split('').each do |c|
#puts "#{c} / #{binary[bincount]}"
			if c =~ /[a-zA-Z]/  # Only use letters to encode binary
				if binary[bincount] == '1'
					# 1 equals uppercase
					ciphertext << c.upcase
				else
					# 0 (or missing) equals lowercase
					ciphertext << c.downcase
				end

				# Increment the binary array counter
				bincount += 1
			else
				# Not a letter
				ciphertext << c
			end

		end

		puts "WARNING:  Not enough cover text to encode all binary!" if bincount < binary.length

		return ciphertext
	end

	def decode
	end

end # Class SpongemockEncoder



# Instantiate the encoder
spongemock = SpongemockEncoder.new

# Get the string to encode from the commandline
cleartext = ARGV[0]
puts "Encoding:   \"#{cleartext}\""
covertext = ARGV[1]
puts "Covertext:  \"#{covertext}\""


# Unpack the string into binary, represent as a string of 1's and 0's
#first_bitstring = cleartext.unpack('b*').join
#puts "Bitstring:   #{first_bitstring}"

# Encode
ciphertext = spongemock.encode( covertext, cleartext )
puts "Ciphertext: \"#{ciphertext}\""

# Decode
#puts "Bitstring: #{second_bitstring}"

# Pack the decoded binary back into an ascii string
#result = bitstring.pack('a*')
#puts "Result:    \"#{result}\""


