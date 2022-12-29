function piObjectInstance(thisR)
% Prepare a recipe by creating instances for each of its objects 
%
% Synopsis
%   piObjectInstance(thisR)
%
% Brief
%   This function prepares a recipe with assets so that its objects can be
%   copied by creating an instance
%
% Inputs
%   thisR - A recipe
%
% Outputs
%   N/A
%
% See also
%  piObjectInstanceCreate, t_piSceneInstances

% Objects all have a mesh that can be shared
objID = thisR.get('objects');

%  Create an instance for each of the objects
for ii = 1:numel(objID)

    % The last index is the node just prior to root.  This is the node we
    % pass in to create the instance.  I am considering whether we should
    % return an array of these.  But they can be found just these two lines
    % of code.
    p2Root = thisR.get('asset',objID(ii),'pathtoroot');    
    thisNode = thisR.get('node',p2Root(end));

    thisNode.isObjectInstance = 1;

    thisR.set('assets',p2Root(end), thisNode);

    % I am not sure why we need a unique name here, and at the end. Do we?
    % TESTING the deletion
    % thisR.assets.uniqueNames;

    if isempty(thisNode.referenceObject)
        thisR = piObjectInstanceCreate(thisR, thisNode.name,'position',[0 0 0],'rotation',piRotationMatrix());
    end
    
end

thisR.assets = thisR.assets.uniqueNames;

end
