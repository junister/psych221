%% t_piSceneInstances
%
% Show how to add additional instances of an asset to a scene. 
%
%  piObjectInstanceCreate
%
% Also illustrate
%
%  piObjectInstanceRemove
%
% See also
%
 
%%
ieInit;
if ~piDockerExists, piDockerConfig; end

%% Render the basic scene

thisR = piRecipeDefault('scene name','simple scene');
piObjectInstance(thisR);

% thisR.show;
%{
%% We need to convert all of the objects to instances

% These all have a mesh
objID = thisR.get('objects');

%  Create an instance for each of the objects
for ii = 1:numel(objID)

    % The last index is the node just prior to root
    p2Root = thisR.get('asset',objID(ii),'pathtoroot');
    
    thisNode = thisR.get('node',p2Root(end));
    thisNode.isObjectInstance = 1;

    thisR.set('assets',p2Root(end), thisNode); 
    thisR.assets.uniqueNames;

    if isempty(thisNode.referenceObject)
        thisR = piObjectInstanceCreate(thisR, thisNode.name,'position',[0 0 0],'rotation',piRotationMatrix());
    end
    
end

%%
thisR.assets = thisR.assets.uniqueNames;
%}

%%
piWRS(thisR,'render flag','hdr');

%% Create a second instance if the yellow guy

% oNames = thisR.get('object names');

% Maybe this should be thisR.get('asset',idx,'top branch')
yellowID = piAssetSearch(thisR,'object name','figure_6m');
p2Root = thisR.get('asset',yellowID,'pathtoroot');
idx = p2Root(end);

% This position is relative to the position of the original object
for ii=1:3
    thisR = piObjectInstanceCreate(thisR, idx, 'position',ii*[-0.3 0 0.0]);
    % thisR.assets = thisR.assets.uniqueNames;
end

%% Blue man copies

blueID = piAssetSearch(thisR,'object name','figure_3m');
p2Root = thisR.get('asset',blueID,'pathtoroot');
idx = p2Root(end);

% This position is relative to the position of the original object
steps = [-0.3 0.3];
for ii=1:numel(steps)
    thisR = piObjectInstanceCreate(thisR, idx, 'position',[steps(ii) 0 0.0]);
    % thisR.assets = thisR.assets.uniqueNames;
end

% thisR.show;
%%
piWRS(thisR,'render flag','hdr');

