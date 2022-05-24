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
            defaultDir = fullFile(ourData,'assets');
        case 'lights'
            defaultDir = fullFile(ourData,'lights');
        case 'imageTextures'
            defaultDir = fullFile(ourData,'imageTextures');
        case 'lens'
            defaultDir = fullFile(ourData,'lens');
    end
end

