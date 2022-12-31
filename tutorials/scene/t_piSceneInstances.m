%% t_piSceneInstances
%
% Show how to add multiple instances of an asset to a scene.  Instances are
% a way to store the mesh data of an object once, but to reuse the mesh as
% we render the asset with different transforms for position, size, and
% rotation.
% 
% This is used heavily in the ISETAuto work and also for text rendering
% (e.g., piTextInsert).
%  
% See also
%  piObjectInstanceCreate, piObjectInstanceRemove
%
 
%%
ieInit;
if ~piDockerExists, piDockerConfig; end

%% Render the basic scene

thisR = piRecipeDefault('scene name','simple scene');
piWRS(thisR);

%% Create a second instance of the yellow guy

% Converts the whole recipe.  Is this necessary or 
piObjectInstance(thisR);
% thisR.show;

% Maybe this should be thisR.get('asset',idx,'top branch')
yellowID = piAssetSearch(thisR,'object name','figure_6m');
p2Root = thisR.get('asset',yellowID,'pathtoroot');
idx = p2Root(end);

% This position is relative to the position of the original object
for ii=1:3
    thisR = piObjectInstanceCreate(thisR, idx, 'position',ii*[-0.3 0 0.0]);
end

%% Blue man copies

blueID = piAssetSearch(thisR,'object name','figure_3m');
p2Root = thisR.get('asset',blueID,'pathtoroot');
idx = p2Root(end);

% This position is relative to the position of the original object
steps = [-0.3 0.3];
for ii=1:numel(steps)
    thisR = piObjectInstanceCreate(thisR, idx, 'position',[steps(ii) 0 0.0]);
end

%% The necessity of unique names has to do with speed and ISETAuto

% See comments at the end of piObjectInstanceCreate
thisR.assets = thisR.assets.uniqueNames;
piWRS(thisR,'render flag','hdr');

%% Try it with the Chess Set
thisR = piRecipeDefault('scene name','Chess Set');
piObjectInstance(thisR);
piWRS(thisR,'render flag','hdr');

%% Copy the pieces

% To see the different pieces, try
%   [idMap, oList] = piLabel(thisR);
%   ieNewGraphWin; image(idMap);
%
% Click on the pieces to see the index
% Then use oList(idx) to see the mesh name
% 72 is the ruler.  The king is 7.  The queen is 141.

pieceID = piAssetSearch(thisR,'object name','ChessSet_mesh_00007');
p2Root = thisR.get('asset',pieceID,'pathtoroot');
idx = p2Root(end);

% This position is relative to the position of the original object
% The Chess set dimensions are small.  
steps = [-0.2 0.2]*1e-1;
for ii=1:numel(steps)
    thisR = piObjectInstanceCreate(thisR, idx, 'position',[steps(ii) 0 0.0]);
end

topID = piAssetSearch(thisR,'object name','ChessSet_mesh_00065');
p2Root = thisR.get('asset',topID,'pathtoroot');
idx = p2Root(end);

% This position is relative to the position of the original object
% The Chess set dimensions are small.  
steps = [-0.2 0.2]*1e-1;
for ii=1:numel(steps)
    thisR = piObjectInstanceCreate(thisR, idx, 'position',[steps(ii) 0 0.0]);
end

%% The necessity of unique names has to do with speed and ISETAuto

thisR.assets = thisR.assets.uniqueNames;

%%
piWRS(thisR,'render flag','hdr');


%% END
