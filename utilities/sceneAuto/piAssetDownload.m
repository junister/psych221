function assetRecipe = piAssetDownload(session,sessionname,nassets,varargin)
% Download assets from a flywheel session
%
%  fname = piAssetDownload(session,sessionname,nassets,varargin)
%
% Description
%
% Inputs
% Optional key/value parameters
% Outputs
%

% Examples: 
%{
fname = piAssetDownload(session,sessionname,ncars);
%}

%% Parse the inputs

p = inputParser;
p.addRequired('session',@(x)(isa(x,'flywheel.model.Session')));
p.addRequired('sessionname',@ischar);
p.addRequired('nassets',@isnumeric);
p.addParameter('acquisition','',@ischar);
p.addParameter('scitran',[],@(x)(isa(x,'scitran')));

p.parse(session, sessionname, nassets, varargin{:});
acqname = p.Results.acquisition;
st = p.Results.scitran;

if isempty(st)
    st = scitran('stanfordlabs');
end
% varargin = ieParamFormat(varargin);
% 
% vFunc = @(x)(strncmp(class(x),'flywheel.model',14) || ...
%             (iscell(x) && strncmp(class(x{1}),'flywheel.model',14)));
% p.addRequired('session',vFunc);
% 
% p.addParameter('sessionname','car')
% p.addParameter('ncars',1)
% p.addParameter('ntrucks',0);
% p.addParameter('npeople',0);
% p.addParameter('nbuses',0);
% p.addParameter('ncyclist',0); 
% sessionName = p.Results.sessionname;
% ncars = p.Results.ncars;
%%
containerID = idGet(session,'data type','session');
fileType = 'CG Resource';
[resourceFiles, resource_acqID] = st.dataFileList('session', containerID, fileType);
fileType_json ='source code'; % json
[recipeFiles, recipe_acqID] = st.dataFileList('session', containerID, fileType_json);
%%
if isempty(acqname)
%%
% Create Assets obj struct
% Download random cars from flywheel

% Find how many cars are in the database?
% stPrint(hierarchy.acquisitions{whichSession},'label','') % will be disable

% These files are within an acquisition (dataFile)


nDatabaseAssets = length(resourceFiles);

assetList = randi(nDatabaseAssets,nassets,1);
% count objectInstance
downloadList = piObjectInstanceCount(assetList);
nDownloads = length(downloadList);
assetRecipe = cell(nDownloads,1);
% if nassets <= nDatabaseAssets
%     assetList = randperm(nDatabaseAssets,nassets);
%     nDownloads = nassets;
%     nRequired = 0;
% else 
%     nDownloads = nDatabaseAssets;
%     nRequired = nassets-nDatabaseAssets;
%     assetList = randperm(nDatabaseAssets,nDatabaseAssets);
%     assetList_required = randperm(nDatabaseAssets,nRequired);
% end

for ii = 1:nDownloads
    [~,n,~] = fileparts(resourceFiles{downloadList(ii).index}{1}.name);
    [~,n,~] = fileparts(n); % extract file name
    % Download the scene to a destination zip file
    localFolder = fullfile(piRootPath,'local',n);    
    destName_recipe = fullfile(localFolder,sprintf('%s.json',n));
    % we might not need to download zip files every time, use
    % resourceCombine.m 08/14 --zhenyi
    destName_resource = fullfile(localFolder,sprintf('%s.zip',n));
    if ~exist(localFolder,'dir'), mkdir(localFolder)
    st.fileDownload(recipeFiles{downloadList(ii).index}{1}.name,...
        'container type', 'acquisition' , ...
        'container id',  recipe_acqID{downloadList(ii).index} ,...
        'destination',destName_recipe);
    
    st.fileDownload(resourceFiles{downloadList(ii).index}{1}.name,...
        'container type', 'acquisition' , ...
        'container id',  resource_acqID{downloadList(ii).index} ,...
        'unzip', true, ...
        'destination',destName_resource);
    end
    assetRecipe{ii}.name   = destName_recipe;
    assetRecipe{ii}.count  = downloadList(ii).count;
%     if ~exist(assetRecipe{ii}.name,'file'), error('File not found');end 
end

% for jj = 1:nRequired
%     [~,n,~] = fileparts(resourceFiles{assetList_required(jj)}{1}.name);
%     assetRecipe{nDownloads+jj} = fullfile(localFolder, sprintf('%s.json',n));
%     if ~exist(assetRecipe{ii},'file'), error('File not found');end 
% end

fprintf('%d Files downloaded.\n',nDownloads);
else
    % download acquisition by given name;
    for jj = 1:length(recipeFiles)
        if contains(recipeFiles{jj}{1}.name,acqname)
            [~,n,~] = fileparts(resourceFiles{jj}{1}.name);
    [~,n,~] = fileparts(n); % extract file name
    % Download the scene to a destination zip file
    localFolder = fullfile(piRootPath,'local',n);    
    destName_recipe = fullfile(localFolder,sprintf('%s.json',n));
    % we might not need to download zip files every time, use
    % resourceCombine.m 08/14 --zhenyi
    destName_resource = fullfile(localFolder,sprintf('%s.zip',n));
    if ~exist(localFolder,'dir'), mkdir(localFolder)
    st.fileDownload(recipeFiles{jj}{1}.name,...
        'container type', 'acquisition' , ...
        'container id',  recipe_acqID{jj} ,...
        'destination',destName_recipe);
    
    st.fileDownload(resourceFiles{jj}{1}.name,...
        'container type', 'acquisition' , ...
        'container id',  resource_acqID{jj} ,...
        'unzip', true, ...
        'destination',destName_resource);
    end
    assetRecipe.name   = destName_recipe;
    assetRecipe.count  = 1;
        end
    end
end







