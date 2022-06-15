function retVal = getPrefs(paramName)
% Retrieve and possibly print out the current Matlab prefs for 'docker'
%
% Syntax
%    dockerWrapper.getPrefs(paramName)
%
% Brief synopsis
%  Interface to setpref(), getpref().  The Matlab prefs are persistent
%    across Matlab sessions.  When these parameters are changed,
%    dockerWrapper.reset() is called.
%
% Inputs
%   verbosity
%   whichGPU
%   gpuRendering
%
%   remoteMachine
%   remoteUser
%   remoteRoot
%   remoteImage
%   remoteImageTag
%
%   localRoot
%   localRender
%   localVolumePath
%
% See also
%  dockerWrapper.setPrefs

if ~exist('paramName','var'), paramName = ''; end

if isempty(paramName) || isequal(paramName,'all') || isequal(paramName,'print')
    % Print a summary of all the params and return the struct
    retVal = getpref('docker');
    fields = fieldnames(retVal);
    fprintf('\n\ndockerWrapper defaults (getprefs(''docker''))\n________________\n\n');
    for ii=1:numel(fields)
        switch(class(retVal.(fields{ii})))
            case 'char'
                fprintf('\t%s\t\t''%s''\n',fields{ii},retVal.(fields{ii}));
            otherwise
                fprintf('\t%s\t\t%d\n',fields{ii},retVal.(fields{ii}));
        end
    end

    % Summarize configuration for the user
    processor = 'CPU';   if retVal.gpuRendering, processor = 'GPU'; end
    location = retVal.remoteMachine; if retVal.localRender, location='your local machine'; end
    fprintf('\nConfigured for rendering on %s using a %s.\n\n',location, processor);

else
    % Return the value.
    retVal = getpref('docker',paramName, '');
end

end

