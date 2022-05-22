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
%   We store certain simple asset recipes as mat-files for easy loading and
%   insertion into scenes.  The assets are created in the script
%   s_assetsCreate
%
%   The piRecipeMerge function works to combine
%   these with general scenes.
%
%   The asset recipes are stored along with the critical node used for
%   merging. The mat-file slot for the input is just the name of the
%
% See also
%   s_assetsCreate, piRootPath/data/assets
%

%%
if ~exist('fname','var') || isempty(fname)
    error('The asset name must be specified');
end

%% We need a mat-file, preferably from the data/assets directory

% Check the extension
[p,n,e] = fileparts(fname);
if isempty(e), e = '.mat'; end
fname = fullfile(p,[n,e]);

% If the user did not specify a path, look in the data/assets directory
if isempty(p)
    % See if it exists in the data/assets directory.
    if exist(fullfile(piRootPath,'data','assets',[n e]),'file')
        fname = fullfile(piRootPath,'data','assets',[n e]);
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

% The problem is that the file is written out for a specific user.  But
% another user on another system is loading it.  Still, the file should be
% in the ISET3D directory tree.
[thePath,n,e] = fileparts(asset.thisR.get('input file'));

% Find the name of the directory containing the file.
% Cross-platform issue: Win paths will have \, Linux/Mac /
% but we don't know what has been encoded in there.
if contains(thePath, '/')
    temp = split(thePath,'/');
else
    temp = split(thePath,'\');
end
theDir = temp{end};

% Insist that this is a V4 pbrt file.
inFile = fullfile(piRootPath,'data','V4',theDir,[n,e]);

% Make sure it exists
if ~isfile(inFile), error('Cannot find the PBRT input file %s\n',thisR.inputFile); end

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
