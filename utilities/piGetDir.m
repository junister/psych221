function defaultDir = piGetDir(dirType)
%PIGETDIR Return where files/assets of a given type are
% located by default
%
if isempty(dirType) || ~ischar(dirType)
    error("Please pass a valid asset or resource type");
else

    % Set these once, in case we ever need to change them
    ourRoot = piRootPath();
    ourData = fullfile(ourRoot,'data');

    % Now we can locate specific types of resources
    switch (dirType)
        case 'assets'
            defaultDir = fullfile(ourData,'assets');
        case 'lights'
            defaultDir = fullfile(ourData,'lights');
        case 'imageTextures'
            defaultDir = fullfile(ourData,'imageTextures');
        case 'lens'
            defaultDir = fullfile(ourData,'lens');
        case 'scenes'
            defaultDir = fullfile(ourData,'V4'); % remove the V4 entry if we promote or move scenes
        case 'local'
            defaultDir = fullfile(piRootPath(), 'local');
    end
end

