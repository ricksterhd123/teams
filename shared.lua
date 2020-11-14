function RGBToHex(red, green, blue, alpha)
	-- Make sure RGB values passed to this function are correct
	if( ( red < 0 or red > 255 or green < 0 or green > 255 or blue < 0 or blue > 255 ) or ( alpha and ( alpha < 0 or alpha > 255 ) ) ) then
		return nil
	end
	-- Alpha check
	if alpha then
		return string.format("#%.2X%.2X%.2X%.2X", red, green, blue, alpha)
	else
		return string.format("#%.2X%.2X%.2X", red, green, blue)
	end
end

function HexToRGB(hexstr)
    local r, g, b = hexstr:match("#(..)(..)(..)")
    return tonumber(r, 16) , tonumber(g, 16), tonumber(b, 16)
end