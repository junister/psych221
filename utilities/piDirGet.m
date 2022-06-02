function defaultDir = piDirGet(dirType)
%PIGETDIR Return where files/assets of a given type are
% located by default. This is to allow some filepath
% independence, compared to hard-coding paths
%
% D.Cardinal -- Stanford University -- May, 2022
%
if isempty(dirType) || ~ischar(dirType)
    error("Please pass a valid asset or resource type");
else

    % Set these once, in case we ever need to change them
    ourRoot = piRootPath();
    ourData = fullfile(ourRoot,'data');

    % Now we can locate specific types of resources
    switch (dirType)
        case 'data'
            defaultDir = ourData;
        case 'assets'
            defaultDir = fullfile(ourData,'assets');
        case 'lights'
            defaultDir = fullfile(ourData,'lights');
        case 'imageTextures'
            defaultDir = fullfile(ourData,'imageTextures');
        case {'lens', 'lenses'}
            defaultDir = fullfile(ourData,'lens');
        case 'scenes'
            defaultDir = fullfile(ourData,'V4'); % remove the V4 entry if we promote or move scenes
        case 'local'
            % Hard to make this one anything besides hard-coded,
            % at least for now
            if ispc
                defaultDir = fullfile(piRootPath(), 'local/');
            else
                defaultDir = '/iset/iset3d-v4/local/';
            end
    end
end

