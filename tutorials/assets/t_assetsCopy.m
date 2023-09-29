%% t_assetCopy
%
%  Make copies of an object in a recipe at different positions.
%
% See also
%   t_piSceneInstances

%%

% Maybe we should have an instance flag?
thisR = piRecipeCreate('sphere');

%% Turn this into an instance recipe
piObjectInstance(thisR);

% Find the object
%
% Maybe this should be thisR.get('asset',idx,'top branch')
sphereID = piAssetSearch(thisR,'object name','Sphere');
p2Root = thisR.get('asset',sphereID,'pathtoroot');
idx = p2Root(end);

% Create copies at a position is relative to the position of the original
% object 
for ii=1:3
    thisR = piObjectInstanceCreate(thisR, idx, 'position',ii*[-0.3 0 0.0]);
end

% We need to adjust the names of the nodes after inserting.  Not sure why
% this can't happen in piObjectInstanceCreate.  I think speed was the
% issue.  We do not want to call this function every time we add an
% instance.  Once at the end is enough.
thisR.assets = thisR.assets.uniqueNames;

%%  Show it

piWRS(thisR);
