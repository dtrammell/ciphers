#!/usr/bin/ruby

class SpongemockEncoder

	# Encode ASCII
	def encode_ascii( covertext, message )
		# binary = message.unpack('b*').first # LSB
		binary = message.unpack('B*').first # MSB
		self.encode_bin( covertext, binary)
	end

	# Encode Binary
	def encode_bin( covertext, binary )
		puts "Message Binary: #{binary}"
		binary = binary.split('')

		puts "WARNING: Not enough cover text to encode all binary!" if covertext.length < binary.length

		ciphertext = ''

		covercount = 0
		bincount = 0

		# Encode each binary bit into a letter in the covertext
		covertext.split('').each do |c|
			puts "#{c} / #{binary[bincount]}" if $DEBUG

			# Reset bincount to loop binary if we've reached the end
			bincount = 0 if binary[bincount] == nil

			# Only use letters to encode binary
			if c =~ /[a-zA-Z]/
				case binary[bincount]
				when '1'
					# 1 equals uppercase
					ciphertext << c.upcase
				when '0'
					# 0 equals lowercase
					ciphertext << c.downcase
				else
					# nil or other remains the same
					ciphertext << c
				end

				# Increment the binary array counter
				bincount += 1
				# Increment the covertext counter
				covercount += 1
			else
				# Not a letter
				ciphertext << c
			end
		end

		puts "WARNING: Binary repeated but covertext ended before full repititon." if bincount != binary.length 

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
if cleartext.match? /^[01]*$/
	# Binary
	puts "Binary message detected..."
	ciphertext = spongemock.encode_bin( covertext, cleartext )
else
	# Assume ASCII
	ciphertext = spongemock.encode_ascii( covertext, cleartext )
end
puts "Ciphertext: \"#{ciphertext}\""

# Decode
#puts "Bitstring: #{second_bitstring}"

# Pack the decoded binary back into an ascii string
#result = bitstring.pack('a*')
#puts "Result:    \"#{result}\""


