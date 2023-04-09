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

%% Identify the objects

% This code section might be able to be placed in parseGeometryText.

% The ObjectBegin/End sections define an object that will be reused as an
% ObjectInstance elsewhere, probably with different position, scale, or
% even materials.  Here are the lines with objects.
objBeginLocs = find(contains(txt,'ObjectBegin'));
objEndLocs   = find(contains(txt,'ObjectEnd'));

% For each objectBegin/End section we process to create a reusable asset.
% The 'trees' variable stores the objects we create.  The code between
% ObjectBegin/End is parsed in the usual way via parseGeometryText.
if ~isempty(objBeginLocs)
    disp('Start Object processing.');
    for objIndex = 1:numel(objBeginLocs)
        fprintf('Object %d: ',objIndex);

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

        % We remove the object lines here, creating an empty cell
        txt(objBeginLocs(objIndex):objEndLocs(objIndex)) = cell(objEndLocs(objIndex)-objBeginLocs(objIndex)+1,1);
    end
    
    % Remove all the empty cells created by removing the objects.
    txt = txt(~cellfun('isempty',txt));
end
disp('Finished Object processing.');

%% Build the asset tree apart from the Object instances

% The txt has no ObjectBegin/End cases, those have been processed and
% removed.  It does have AttributeBegin/End sequences.  We parse them and
% create the subnodes here.
newWorld = txt;
[subnodes, parsedUntil] = parseGeometryText(thisR, newWorld,'');

%% We assign the returned subnodes to the tree
if trees.Parent == 0
    % These are the subnodes return by parseGeometryText. There is no tree
    % from the ObjectBegin/End.  So we use the subnodes
    trees = subnodes;   
else
    % A tree was built in the ObjectBegin loop.  We graft the returned
    % subnodes onto that tree.
    if ~isempty(subnodes)
        subtree = subnodes.subtree(2);
        trees = trees.graft(1, subtree);
    end
end

% The if/elses seems unnecessary to me.
if ~isempty(trees)
    % In some parsing we do not yet have a tree.  But almost always,
    % we have a tree.  Trying to find the cases where parsing fails.
    trees = trees.uniqueNames;
else
    % This seems impossible to me.  So a warning.
    warning('Empty tree.  Hard to see how that could happen.');
end

% We first parsed all of the lines in txt between ObjectBegin/End. We then
% parsed the lines in newWorld.  If parsedUntil exceeds the number of lines
% in newWorld, we set it to be equal to that number. But really, we expect
% it to be numel(newWorld)
if parsedUntil ~= numel(newWorld), warning('Incomplete parsing'); end
parsedUntil = min(parsedUntil,numel(newWorld));
% Old code that I didn't understand.  Seemed wrong, but it ran.
% parsedUntil(parsedUntil>numel(newWorld)) = numel(newWorld);

% Remove the parsed lines from newWorld. I am unclear about the 'Include'
% lines.  I think we always need those.  Perhaps piWrite handles the
% matter?
newWorld(2:parsedUntil)=[];

end
