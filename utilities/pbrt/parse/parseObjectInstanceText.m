function [trees, newWorld] = parseObjectInstanceText(thisR, txt)

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
        branchNode.isInstance = 1;
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
trees = trees.uniqueNames;
parsedUntil(parsedUntil>numel(newWorld))=numel(newWorld);
%remove parsed line from world
newWorld(2:parsedUntil)=[];

end