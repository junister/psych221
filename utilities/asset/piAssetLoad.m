function asset = piAssetLoad(fname)
% Load a mat-file containing an asset recipe
%
% Synopsis
%   asset = piAssetLoad(fname)
%
% Input
%   fname - filename of the asset mat-file
%
% Output
%  asset - a struct containing the recipe and the mergeNode
%
%   asset.thisR     - recipe for the asset
%   asset.mergeNode - Node in the asset tree to be used for merging
%
% Description
%   We store certain assets as mat-files that contain a recipe.  These
%   recipes be loaded (piAssetLoad) and then merged into any other
%   scene recipe. 
% 
%   The assets are created and stored in the script s_assetsCreate. The
%   piRecipeMerge function combines the asset into the scene. The asset
%   recipe is stored along with the name of the critical node used for
%   merging. 
%
% See also
%   piRecipeMerge, piDirGet('assets'), piRootPath/data/assets
%

%%
if ~exist('fname','var') || isempty(fname)
    error('The asset name must be specified');
end

%% We need a mat-file, preferably from the data/assets directory
% Note: We are adding a large supply of characters, so we might
%       extend this to include data/assets/characters

% Check the extension
[p,n,e] = fileparts(fname);
if isempty(e), e = '.mat'; end
fname = fullfile(p,[n,e]);

% If the user did not specify a path, look in the data/assets directory
if isempty(p)
    % See if it exists in the data/assets directory.
    if exist(fullfile(piDirGet('assets'),[n e]),'file')
        fname = fullfile(piDirGet('assets'),[n e]);
    else
        % See if you can find it anywhere
        if isempty(which(fname)), error('Could not find %s\n',fname); 
        else
            fname = which(fname); 
            fprintf('Using asset %s\n',fname);
        end
    end
end

asset = load(fname);

%% Adjust the input slot in the recipe for the local user.

% The file was written out by a specific user.  But another user on another
% system is loading it. So we need to adjust the location of the input to
% match this user.

% Find the name of the directory containing the original pbrt file in the file.
[thePath,n,e] = fileparts(asset.thisR.get('input file'));

% Cross-platform issue: 
% Window paths will have \, Linux/Mac /.  We need to be able to get the 
% but we don't know what has been encoded in there.
if contains(thePath, '/'),     temp = split(thePath,'/');
else,                          temp = split(thePath,'\');
end
theDir = temp{end};

% This is the path for the current user.
% Hmm. This seems pretty limiting ...
inFile = fullfile(piDirGet('scenes'),theDir,[n,e]);

% Make sure it exists or try characters
% PS I still don't really understand all this re-mapping
%    and wish we could just get rid of it somehow
if ~isfile(inFile)
    inFile = fullfile(piDirGet('character-recipes'),theDir,[n,e]);
    if ~isfile(inFile)
        error('Cannot find the PBRT input file %s\n',thisR.inputFile); 
    end
end

% Set it
asset.thisR.set('input file',inFile);

%% Adjust the input slot in the recipe for the local user

[thePath,n,e] = fileparts(asset.thisR.get('output file'));

% Find the last element of the path
temp = split(thePath,filesep);
theDir = temp{end};

% The file name for this user should be
outFile=fullfile(piRootPath,'local',theDir,[n,e]);

asset.thisR.set('output file',outFile);

end
