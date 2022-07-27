function [trees, newWorld] = parseObjectInstanceText(thisR, txt)
% Parse the geometry objects accounting for object instances
%
% Synopsis
%   [trees, newWorld] = parseObjectInstanceText(thisR, txt)
%
% Brief description
%   The txt is usually the world text from the PBRT file.  It is
%   parsed into objects and materials.  This function relies on
%   parseGeometryText, but handles the special cases of object
%   instaces
%
% Inputs
%   thisR - ISET3d recipe
%   txt -  Cell array of text strings, usually from the WorldBegin ...
%
% Outputs
%   trees -  Assets in a tree format
%   newWorld - Modified world text to use, after removing unnecessary
%              lines.
%
% See also
%   parseGeometryText

%%
rootAsset = piAssetCreate('type', 'branch');
rootAsset.name = 'root_B';
trees = tree(rootAsset);
objBeginLocs = find(contains(txt,'ObjectBegin'));
objEndLocs   = find(contains(txt, 'ObjectEnd'));

for objIndex = 1:numel(objBeginLocs)
    name = erase(txt{objBeginLocs(objIndex)}(13:end),'"');
    
    [subnodes, ~] = parseGeometryText(thisR,...
        txt(objBeginLocs(objIndex)+1:objEndLocs(objIndex)-1), '');
    
    if ~isempty(subnodes)
        subtree = subnodes.subtree(2);
        branchNode = subtree.Node{1};
        branchNode.isObjectInstance = 1;
        branchNode.name = sprintf('%s_B',name);
        subtree = subtree.set(1, branchNode);
        trees = trees.graft(1, subtree);
    end
    txt(objBeginLocs(objIndex):objEndLocs(objIndex)) = cell(objEndLocs(objIndex)-objBeginLocs(objIndex)+1,1);
end

newWorld = txt(~cellfun('isempty',txt));
[subnodes, parsedUntil] = parseGeometryText(thisR, newWorld,'');
if trees.Parent == 0
    trees = subnodes;   
else
    if ~isempty(subnodes)
        subtree = subnodes.subtree(2);
        trees = trees.graft(1, subtree);
    end
end

if ~isempty(trees)
    % In some parsing we do not yet have a tree allocated.  If there
    % is just NamedMaterial in the Begin/End
    trees = trees.uniqueNames;
end
parsedUntil(parsedUntil>numel(newWorld))=numel(newWorld);
%remove parsed line from world
newWorld(2:parsedUntil)=[];

end