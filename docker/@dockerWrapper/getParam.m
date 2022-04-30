function retVal = getParam(paramName)
%GETPARM Retrieve a current dockerWrapper parameter
%
% for now our default params are simply saved as prefs
% so we just do a getpref(). That could change in the future
% so we have this wrapper function
    retVal = getpref('docker',paramName, '');
end

