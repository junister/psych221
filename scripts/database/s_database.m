%%
ieInit; clear ISETdb
% set up connection to the database, it's 49153 if we are in Stanford
% Network. 
% Question: 
%   1. How to figure out the port number if we are not.
%   2. What if the data is not on acorn?
% 
setpref('db','port',49153);
ourDB = idb.ISETdb();

if ~isopen(ourDB.connection),error('No connection to database.');end
%% Database description
% assets: Contains reusable components like models, textures, or animations
%         that can be used across various scenes or projects.
%
% scenes: Contains individual scene files which may include all
%         the necessary data (like assets, lighting, and camera information) 
%         to render a complete environment or image. 

% bsdfs: Stands for Bidirectional Scattering Distribution Functions; likely
%        contains data or scripts related to the way light interacts with 
%        surfaces within a scene. 
% 
% lens: Could contain data related to camera lens
%       configurations or simulations, affecting how scenes are viewed or
%       rendered. 
% 
% lights: Likely holds information or configurations for various
%         lighting setups, which are essential in 3D rendering for realism 
%         and atmosphere. 
% 
% skymaps: Usually refers to
%          panoramic textures representing the sky, often used in rendering 
%          to create backgrounds or to simulate environmental lighting.
%% Render local scene with remote PBRT
% Make sure you have configured your computer according to this:
%       https://github.com/ISET/iset3d/wiki/Remote-Rendering-with-PBRT-v4
% See /iset3d/tutorials/remote/s_remoteSet.m for remote server
% configuration

% getpref('docker')
% Things to check:
%     remoteUser;
%     renderContext;

sceneFolder = '/Users/zhenyi/git_repo/dev/iset3d/data/V4/low-poly-taxi';

pbrtFile = fullfile(sceneFolder, 'low-poly-taxi.pbrt');

% we might want to decide, wheather we would like to add this scene to our
% database.
% Create a new collection for test
colName = 'PBRTResources';

ourDB.collectionCreate(colName);

% list the data in a collection
% thisCollection = ourDB.docList(colName);

% Add the scene to the database
% if we need to add a local scene to the database, a directory is
% needed.

dstDir = 'zhenyiliu@orange:/acorn/data/iset/PBRTResources';
% or some local directory 
% dstDir = 'your/local/path/to/scenes'

% this local scene will be copied to the remote directory and add to the
% given collection.

[thisID, contentStruct] = ourDB.contentCreate('collection Name',colName, ...
    'type','scene', ...
    'name','low-poly-taxi',...
    'category','iset3d',...
    'mainfile','low-poly-taxi.pbrt',...
    'source','blender',...
    'tags','test',...
    'size',piDirSizeGet(sceneFolder)/1024^2,... % MB
    'format','pbrt'); 


string = queryConstruct(contentStruct);
doc = find(obj.connection, p.Results.collectionname, Query = queryString);

ourDB.upload(sceneFolder, dstDir) % source and destinated directory



% Delete the scene in the database



%% Render remote scene with remote PBRT




%% Render local scene with local PBRT