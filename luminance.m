function lum = luminance()
cMatrix = ColorCal2('ReadColorMatrix');
s = ColorCal2('MeasureXYZ');
correctedValues = cMatrix(1:3,:) * [s.x s.y s.z]';
lum = correctedValues(2);