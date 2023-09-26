%% Store small asset recipes as mat-files in the data/assets directory
%
% We save certain small assets and specific test chart recipes in
% data/assets. 
%
% The goal is to simplify inserting these objeccts into arbitrary scenes
% easily. We save more complex scenes in the data/scenes directories.
%
% This script is used to produce the assets, which have
%   * a recipe  (thisAsset.thisR)
%   * a node where the recipe is merged into the root of the larger scene
%      (thisAsset.mergeNode)
%
% In the asset recipe is
%  the 'from' is [0,0,0]
%  the 'to'   is [0 0 1];
%
% An asset has one object (asset) and no light.  To check the appearance of
% the asset, you can run this code:
%
% To visualize an asset
%{
  thisA = piAssetLoad('Bunny');
  thisR = thisA.thisR;
  lgt = piLightCreate('point','type','point'); 
  thisR.set('object distance',1);
  thisR.set('light',lgt,'add');
  piWRS(thisR,'render flag','rgb');
%}
%
% To merge an asset into an existing scene, use code like this
% Fix the code below for the ordering of translate and scale. 
%{
   mccR = piRecipeCreate('macbeth checker');
   thisA = piAssetLoad('Bunny');
   mccR = piRecipeMerge(mccR,thisA.thisR);
   bunny = piAssetSearch(mccR,'object name','Bunny');
   mccR.set('asset',bunny,'world position',[0 0 -2]);
   mccR.set('asset',bunny,'scale',4);
   piWRS(mccR,'render flag','rgb');
%}
% 
% See also
%   s_scenesRecipe
%

%% Init

ieInit;
if ~piDockerExists, piDockerConfig; end

assetDir = piDirGet('assets');

%% The Stanford bunny

sceneName = 'bunny';
thisR = piRecipeDefault('scene name', sceneName);

% Camera at origin.  Look at 0,0,1.
thisR.set('from',[0 0 0]);
thisR.set('to',  [0 0 1]);

% There is just one object.
bunnyID = piAssetSearch(thisR,'object name','Bunny');
% oNames  = thisR.get('object names no id');

% The default Bunny has two geometry branch nodes with the same name.  We
% delete one of them.
% parentid = thisR.get('asset parent id',oNames{1});
parentid = thisR.get('asset parent id',bunnyID);

% This changes the bunnyID
thisR.set('asset',parentid,'delete');

% So find it again
bunnyID = piAssetSearch(thisR,'object name','Bunny');

% Position and size
thisR.set('asset', bunnyID, 'world position', [0 0 1]);
thisR.set('asset', bunnyID,'scale',5);

oFile = thisR.save(fullfile(assetDir,[sceneName,'.mat']));
mergeNode = 'Bunny_B';
save(oFile,'mergeNode','-append');

thisR.show('objects');

%{
lgt = piLightCreate('point','type','point');
thisR.set('light',lgt,'add');
piWRS(thisR);
%}
%% A head - maybe we should scale this to a smaller size

thisR = piRecipeDefault('scene name','head');
thisR.set('lights','all','delete');

n = thisR.get('asset names');
thisR.set('asset',n{3},'name','head_O');
thisR.set('asset',n{2},'name','head_B');

% Head has a world position of 001
headID = piAssetSearch(thisR,'object name','head');
% thisR.set('asset',headID,'world position',[0 0 0]);
% thisR.set('asset',headID,'rotate',[0 180 0]);
thisR.set('asset',headID,'world position',[0 0 1]);

thisR.set('from',[0 0 5]);
thisR.set('to',[0 0 1]);

%{
lgt = piLightCreate('point','type','point');
thisR.set('light',lgt,'add');
piWRS(thisR);
%}
oFile = thisR.save(fullfile(assetDir,'head.mat'));

mergeNode = 'head_B';
save(oFile,'mergeNode','-append');
thisR.show('materials');

%%  Coordinate axes at 000

sceneName = 'coordinate';
thisR = piRecipeDefault('scene name', sceneName);
oNames = thisR.get('object names no id');

% Put a merge node (branch type) above all the objects
geometryNode = piAssetCreate('type','branch');
geometryNode.name = 'mergeNode_B';
thisR.set('asset','root_B','add',geometryNode);

% Merge the branches above the object. Then attach each object to the
% merge node.
% 
%{
% No longer runs (BW).  Commenting out
for oo=1:numel(oNames)
    thisR.set('asset',oNames{oo},'merge branches');
    % I do not think this line should be here.  This is managed inside
    % of the merge branches set, above. (BW).  Even so, I left it for
    % now.
    thisR.set('asset',strrep(oNames{oo},'_O','_B'),'parent',geometryNode.name);
end
%}

% Move the axes by adjusting the mergeNode_B.
thisR.set('asset','mergeNode_B','translate',[0 0 1]);

% piWRS(thisR);
mergeNode = geometryNode.name;
thisR.show('textures');   % The filename should be textures/mumble.png
oFile = thisR.save(fullfile(assetDir,[sceneName,'.mat']));
save(oFile,'mergeNode','-append');
thisR.show('materials');

%% We need a light to see it.
%
% Camera at 000 to 001 sphere at 001
%
sceneName = 'sphere';
thisR = piRecipeCreate(sceneName);
thisR.set('lights','all','delete');
mergeNode = 'Sphere_B';

%{
lgt = piLightCreate('point','type','point');
thisR.set('light',lgt,'add');
piWRS(thisR);
%}

oFile = thisR.save(fullfile(assetDir,[sceneName,'.mat']));
save(oFile,'mergeNode','-append');

%% Test charts

% The merge node is used for
%
%   piRecipeMerge(thisR,chartR,'node name',mergeNode);
%

%{
thisR.show('textures'); 
names = thisR.get('texture','names');
thisR.set('texture',names{1},'filename','textures/monochromeFace.png');
thisR.show('textures');   % The filename should be textures/mumble.png
%}

% EIA Chart
[thisR, mergeNode] = piChartCreate('EIA');

%{
lgt = piLightCreate('point','type','point');
thisR.set('light',lgt,'add');
piWRS(thisR);
%}
oFile = thisR.save(fullfile(assetDir,'EIA.mat'));
save(oFile,'mergeNode','-append');
thisR.show('textures');
%{
 lgt = piLightCreate('point light 1');
 thisR.set('light',lgt,'add');
 piWRS(thisR);
%}

% Ringsrays
[thisR, mergeNode]= piChartCreate('ringsrays');
oFile = thisR.save(fullfile(assetDir,'ringsrays.mat'));
save(oFile,'mergeNode','-append');

% Slanted bar
[thisR, mergeNode] = piChartCreate('slanted bar');
oFile = thisR.save(fullfile(assetDir,'slantedbar.mat'));
save(oFile,'mergeNode','-append');

% Grid lines
[thisR, mergeNode] = piChartCreate('grid lines');
oFile = thisR.save(fullfile(assetDir,'gridlines.mat'));
save(oFile,'mergeNode','-append');

% face
[thisR, mergeNode] = piChartCreate('face');
oFile = thisR.save(fullfile(assetDir,'face.mat'));
save(oFile,'mergeNode','-append');

% Macbeth
[thisR, mergeNode] = piChartCreate('macbeth');
oFile = thisR.save(fullfile(assetDir,'macbeth.mat'));
save(oFile,'mergeNode','-append');

% point array
[thisR, mergeNode] = piChartCreate('pointarray_512_64');
oFile = thisR.save(fullfile(assetDir,'pointarray512.mat'));
save(oFile,'mergeNode','-append');

%% END
