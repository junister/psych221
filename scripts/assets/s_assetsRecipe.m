%% Store small recipes as mat-files in the data/assets directory
%
% We insert these assets as test objects in other scenes
%
% We save these small assets and test chart recipes data/assets.
%
% We save some recipes for bigger scenes in their input directories.
%
% See also
%   s_scenesRecipe
%

%% Init

ieInit;
if ~piDockerExists, piDockerConfig; end

assetDir = piDirGet('assets');

%% A few more scenes as assets
sceneName = 'bunny';
thisR = piRecipeDefault('scene name', sceneName);

thisR.set('from',[0 0 0]);
thisR.set('to',[0 0 1]);

oNames = thisR.get('object names no id');

% The bunny has two geometry branch nodes with the same name.  we have to
% delete one of them.
id = thisR.get('asset parent id',oNames{1});
thisR.set('asset',3,'delete');
% thisR.show;

thisR.set('asset', oNames{1}, 'world position', [0 0 1]);
oFile = thisR.save(fullfile(assetDir,[sceneName,'.mat']));
mergeNode = 'Bunny_B';
save(oFile,'mergeNode','-append');

%% A head - maybe we should scale this to a smaller size

thisR = piRecipeDefault('scene name','head');
thisR.set('lights','all','delete');
% Head has a world position of 000
n = thisR.get('asset names');
thisR.set('asset',n{2},'name','head_B');

oFile = thisR.save(fullfile(assetDir,'head.mat'));
mergeNode = 'head_B';
save(oFile,'mergeNode','-append');

%%  Coordinate axes at 000

sceneName = 'coordinate';
thisR = piRecipeDefault('scene name', sceneName);
oNames = thisR.get('object names no id');

% Put a merge node (branch type) above all the objects
geometryNode = piAssetCreate('type','branch');
geometryNode.name = 'mergeNode_B';
thisR.set('asset','root_B','add',geometryNode);

% Merge the multiple branches above each object
% Then attach each object to the merge node.
for oo=1:numel(oNames)
    thisR.set('asset',oNames{oo},'merge branches');
    thisR.set('asset',strrep(oNames{oo},'_O','_B'),'parent',geometryNode.name);
end

% Move the axes by adjusting the mergeNode_B.
thisR.set('asset','mergeNode_B','translate',[0 0 1]);

% piWRS(thisR);
mergeNode = geometryNode.name;
oFile = thisR.save(fullfile(assetDir,[sceneName,'.mat']));
save(oFile,'mergeNode','-append');

%% We need a light to see it.
%
% Camera at 000 to 001 sphere at 001
%
sceneName = 'sphere';
thisR = piRecipeDefault('scene name', sceneName);
thisR.set('asset','Camera_B','delete');
thisR.set('asset',2,'delete');
piAssetSet(thisR, 'Sphere_B','translate',[0 0 1]);
thisR.set('from',[0 0 0]);
thisR.set('to',[0 0 1]);
mergeNode = 'Sphere_B';
oFile = thisR.save(fullfile(assetDir,[sceneName,'.mat']));
save(oFile,'mergeNode','-append');

%% Test charts

% The merge node is used for
%
%   piRecipeMerge(thisR,chartR,'node name',mergeNode);
%

[thisR, mergeNode] = piChartCreate('EIA');
% thisR.set('lights','all','delete');
oFile = thisR.save(fullfile(assetDir,'EIA.mat'));
save(oFile,'mergeNode','-append');
%{
 lgt = piLightCreate('point light 1');
 thisR.set('light','add',lgt);
 piWRS(thisR);
%}
[thisR, mergeNode]= piChartCreate('ringsrays');
%{
  thisR.set('materials','delete','Mat');
  thisR.get('print materials');
 piWRS(thisR);

%}
oFile = thisR.save(fullfile(assetDir,'ringsrays.mat'));
save(oFile,'mergeNode','-append');

[thisR, mergeNode] = piChartCreate('slanted bar');
oFile = thisR.save(fullfile(assetDir,'slantedbar.mat'));
save(oFile,'mergeNode','-append');

[thisR, mergeNode] = piChartCreate('grid lines');
oFile = thisR.save(fullfile(assetDir,'gridlines.mat'));
save(oFile,'mergeNode','-append');

[thisR, mergeNode] = piChartCreate('face');
oFile = thisR.save(fullfile(assetDir,'face.mat'));
save(oFile,'mergeNode','-append');

[thisR, mergeNode] = piChartCreate('macbeth');
oFile = thisR.save(fullfile(assetDir,'macbeth.mat'));
save(oFile,'mergeNode','-append');

[thisR, mergeNode] = piChartCreate('pointarray_512_64');
oFile = thisR.save(fullfile(assetDir,'pointarray512.mat'));
save(oFile,'mergeNode','-append');


%% END
