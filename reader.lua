-- Not using slow metatables here because we need it fast
local FLOAT_PRECISION = 24
local Reader = {}

function Reader.new(bytecode)
	local stream = buffer.fromstring(bytecode)
	local cursor = 1  -- Start from index 1 (Lua convention)

	local self = {}

	function self:len()
		return buffer.len(stream)
	end

	function self:nextByte()
		local result = buffer.readu8(stream, cursor)
		cursor = cursor + 1
		return result
	end
	function self:nextSignedByte()
		local result = buffer.readi8(stream, cursor)
		cursor = cursor + 1
		return result
	end
	function self:nextBytes(count)
		local result = {}
		for i = 1, count do
			table.insert(result, self:nextByte())
		end
		return result
	end

	function self:nextChar()
		local result = string.char(self:nextByte())
		return result
	end

	function self:nextUInt32()
		local result = buffer.readu32(stream, cursor)
		cursor = cursor + 4
		return result
	end
	function self:nextInt32()
		local result = buffer.readi32(stream, cursor)
		cursor = cursor + 4
		return result
	end

	function self:nextFloat()
		local result = buffer.readf32(stream, cursor)
		cursor = cursor + 4
		return tonumber(string.format(`%0.{FLOAT_PRECISION}f`, result))
	end

	function self:nextVarInt()
		local result = 0
		local shift = 0
		local byte
		repeat
			byte = self:nextByte()
			result = result + ((byte % 128) * (2 ^ shift)) -- Simulate bitwise OR and left shift
			shift = shift + 7
		until (byte < 128) or (shift >= 32) -- Check if the MSB is 0 or shift exceeds 32 bits
		return result
	end

	function self:nextString(len)
		len = len or self:nextVarInt()
		if len == 0 then
			return ""
		else
			local result = buffer.readstring(stream, cursor, len)
			cursor = cursor + len
			return result
		end
	end

	function self:nextDouble()
		local result = buffer.readf64(stream, cursor)
		cursor = cursor + 8
		return result
	end

	return self
end

function Reader:Set(precision)
	FLOAT_PRECISION = precision or 24  -- Default value
end

return Reader
