-- Improved Reader

local FLOAT_PRECISION = 99

local Reader = {}

function Reader.new(bytecode)
	local stream = buffer.fromstring(bytecode)
	local cursor = 0
	-- Initialize the object
	local self = {}

	-- Get the length of the stream
	function self:len()
		return buffer.len(stream)
	end

	-- Read the next byte from the stream
	function self:nextByte()
		local result = buffer.readu8(stream, cursor)
		cursor += 1
		return result
	end

	-- Read the next signed byte
	function self:nextSignedByte()
		local result = buffer.readi8(stream, cursor)
		cursor += 1
		return result
	end

	-- Read the specified number of bytes into a table
	function self:nextBytes(count)
		local result = {}
		for i = 1, count do
			result[i] = self:nextByte()
		end
		return result
	end

	-- Read the next character (1 byte as a character)
	function self:nextChar()
		return string.char(self:nextByte())
	end

	-- Read the next 32-bit unsigned integer
	function self:nextUInt32()
		local result = buffer.readu32(stream, cursor)
		cursor += 4
		return result
	end

	-- Read the next 32-bit signed integer
	function self:nextInt32()
		local result = buffer.readi32(stream, cursor)
		cursor += 4
		return result
	end

	-- Read the next float (32-bit) with specified precision
	function self:nextFloat()
		local result = buffer.readf32(stream, cursor)
		cursor += 4
		return tonumber(string.format(`%0.${FLOAT_PRECISION}f`, result))
	end

	-- Read a variable-length integer
	function self:nextVarInt()
		local result = 0
		for i = 0, 4 do
			local byte = self:nextByte()
			result = bit32.bor(result, bit32.lshift(bit32.band(byte, 0x7F), i * 7))
			if not bit32.btest(byte, 0x80) then
				break
			end
		end
		return result
	end

	-- Read a string of a specified length (or use a VarInt for length)
	function self:nextString(len)
		len = len or self:nextVarInt()
		if len == 0 then
			return ""
		end
		local result = buffer.readstring(stream, cursor, len)
		cursor += len
		return result
	end

	-- Read the next double (64-bit float)
	function self:nextDouble()
		local result = buffer.readf64(stream, cursor)
		cursor += 8
		return result
	end

	-- Set precision for floating-point numbers
	function self:Set(precision)
		FLOAT_PRECISION = precision
	end

	return self
end

return Reader
