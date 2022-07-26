function resourceDir = piDirGet(resourceType)
%PIGETDIR Returns default directory of a resource type.
%
% Synopsis
%   resourceDir = piDirGet(resourceType)
%
% Input
%   resourceType - One of assets, lights, imageTextures, lens, scenes
% 
% Output
%   resourceDir
%
% D.Cardinal -- Stanford University -- May, 2022
%
% See also
%

if isempty(resourceType) || ~ischar(resourceType)
    error("Please pass a valid asset or resource type");
else

    % Set these once, in case we ever need to change them
    ourRoot = piRootPath();
    ourData = fullfile(ourRoot,'data');

    % Now we can locate specific types of resources
    switch (resourceType)
        case 'data'
            resourceDir = ourData;
        case 'assets'
            resourceDir = fullfile(ourData,'assets');
        case 'lights'
            resourceDir = fullfile(ourData,'lights');
        case 'imageTextures'
            resourceDir = fullfile(ourData,'imageTextures');
        case {'lens', 'lenses'}
            resourceDir = fullfile(ourData,'lens');
        case 'scenes'
            resourceDir = fullfile(ourData,'scenes');
        case 'local'
            resourceDir = fullfile(ourRoot,'local');
        case 'server root'
                % should really be someplace else!
                resourceDir = '/iset/iset3d-v4'; % default
    end
end

