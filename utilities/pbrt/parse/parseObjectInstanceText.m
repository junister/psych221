function [trees, newWorld] = parseObjectInstanceText(thisR, txt)
% Parse the geometry objects accounting for object instances
%
% Synopsis
%   [trees, newWorld] = parseObjectInstanceText(thisR, txt)
%
% Brief description
%   The txt is the world text from a PBRT file.  It is parsed into
%   objects creating the asset tree.  The assets include objects and
%   lights.
% 
%   This function relies on parseGeometryText, which works on
%   AttributeBegin/End sequences and certain other simple file
%   formats.  The code here also handles the special cases of
%   ObjectBegin/End instances, but that may be deprecated.
%
% Inputs
%   thisR - ISET3d recipe
%   txt -  Cell array of text strings, usually from the WorldBegin ...
%
% Outputs
%   trees    -  Assets in a tree format
%   newWorld - Modified world text, after removing unnecessary lines.
%
% See also
%   parseGeometryText

%% Create the tree root and initialize the tree
rootAsset = piAssetCreate('type', 'branch');
rootAsset.name = 'root_B';
trees = tree(rootAsset);

%% Identify the lines with objects

% We should probably eliminate this because we are not consistent with V3
% any more anyway. Perhaps we need it if we are still writing out with
% piWrite the ObjectInstance (BW,ZLY) 

objBeginLocs = find(contains(txt,'ObjectBegin'));
objEndLocs   = find(contains(txt,'ObjectEnd'));

% For each line with an ObjectBegin, we do some pre-processing.  What?
% This seems like special case because many scenes never enter this
% ObjectBegin processing.  We need some more comments here (BW).
if ~isempty(objBeginLocs)
    disp('ObjectBegin processing.');
    for objIndex = 1:numel(objBeginLocs)

        % Find its name.  Sometimes this is empty.  Hmm.
        name = erase(txt{objBeginLocs(objIndex)}(13:end),'"');

        % Parse the text to create a node of the tree
        [subnodes, ~] = parseGeometryText(thisR,...
            txt(objBeginLocs(objIndex)+1:objEndLocs(objIndex)-1), '');

        % If we have a node of the tree, further process
        if ~isempty(subnodes)
            % If there are subnodes, then this is a branch
            subtree = subnodes.subtree(2);
            branchNode = subtree.Node{1};
            branchNode.isObjectInstance = 1;
            branchNode.name = sprintf('%s_B',name);
            subtree = subtree.set(1, branchNode);
            trees = trees.graft(1, subtree);
        end

        % We need to remove the empty lines here.
        txt(objBeginLocs(objIndex):objEndLocs(objIndex)) = cell(objEndLocs(objIndex)-objBeginLocs(objIndex)+1,1);
    end
    
    % Remove any empty cells
    txt = txt(~cellfun('isempty',txt));
end


%% The asset tree is built here.  This is the main work.
newWorld = txt;
[subnodes, parsedUntil] = parseGeometryText(thisR, newWorld,'');

%% We assign the returned subnodes to the tree
if trees.Parent == 0
    % Usually, we are here.
    trees = subnodes;   
else
    % We might be here if we entered the ObjectBegin loop.
    if ~isempty(subnodes)
        subtree = subnodes.subtree(2);
        trees = trees.graft(1, subtree);
    end
end

if ~isempty(trees)
    % In some parsing we do not yet have a tree.  But almost always,
    % we have a tree.  Trying to find the cases where parsing fails.
    trees = trees.uniqueNames;
else
    warning('Empty tree.');
end

% We should have parsed all of the lines in newWorld.  So if
% parsedUntil exceeds the number of lines in newWorld, we just set it
% to be equal to those lines.
parsedUntil(parsedUntil>numel(newWorld)) = numel(newWorld);

% Remove all the parsed lines from world because, well, we have
% already parsed them and they are not needed.
newWorld(2:parsedUntil)=[];

end
