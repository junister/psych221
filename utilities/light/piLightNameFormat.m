function newLghtName = piLightNameFormat(lghtName)
if ~isequal(lghtName(end-1:end), '_L') && ~isequal(lghtName, 'all')
    newLghtName = [lghtName, '_L'];
else
    newLghtName = lghtName;
end
end