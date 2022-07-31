function resourceDir = piDirGet(resourceType)
% Returns default directory of a resource type.
%
% Synopsis
%   resourceDir = piDirGet(resourceType)
%
% Input
%   resourceType - One of
%     {'data','assets', 'lights', 'imageTextures', 
%     'lens', 'scenes','local',
%     'server local'}
%
% Output
%   resourceDir
%
% Description:
%   Most of these resources are in directories within iset3d-v4.  The
%   lens resources are in isetcam.
%
%
% D.Cardinal -- Stanford University -- May, 2022
% See also
%

% Example:
%{
  piDirGet('help')
  piDirGet('lens')
  piDirGet('assets')
%}

%% Parse
valid = {'data','assets', 'lights', 'imageTextures', ...
    'lens', 'scenes','local','server local'};

if isequal(resourceType,'help')
    disp(valid);
    return;
end

if isempty(resourceType) || ~ischar(resourceType) || ~ismember(resourceType,valid)
    fprintf('Valid resources are\n\n');
    disp(valid);
    error("%s is not a valid resource type",resourceType);
end

%% Set these resource directories once, here, in case we ever need to change them

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
        % Changed July 30, 2020 - now in isetcam
        resourceDir = fullfile(isetRootPath,'data','lens');
    case 'scenes'
        resourceDir = fullfile(ourData,'scenes');
    case 'local'
        resourceDir = fullfile(ourRoot,'local');
    case 'server local'
        % should really be someplace else!
        resourceDir = '/iset/iset3d-v4/local'; % default
end


end
