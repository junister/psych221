function [trees, parsedUntil] = parseGeometryText(thisR, txt, name)
% Parse the text from a Geometry file, returning an asset subtree
%
% Synopsis
%   [trees, parsedUntil] = parseGeometryText(thisR, txt, name)
%
% Brief:
%   We parse the geometry text file to build up the asset tree in the
%   recipe.  We succeed for some, but not all, PBRT files.  We continue to
%   add special cases.  Called by parseObjectInstanceText
%
% Inputs:
%   thisR       - a scene recipe
%   txt         - text of the PBRT geometry information that we parse
%   name        - current object name
%
% Outputs:
%   trees       - A tree class that describes the assets and their geometry
%   parsedUntil - line number where the parsing ends
%
% Description:
%   The lines of text in 'txt' are a cell array that has been formatted so
%   that each main object or material or light is on a single line.  We
%   parse the lines to create a tree structure of assets, which includes
%   objects and lights. We also learn about named materials. The naming of
%   these assets has been a constant struggle, and I attempt to clarify
%   here.
%
%   This parseGeometryText method creates the asset tree. It reads the
%   geometry text in the PBRT scene file (and the includes) line by
%   line. It tries to find the materials and shapes to create the
%   assets.  It also tries to find the transforms for the branch node
%   above the object node. 
% 
%   There are two types of parsing that this routine handles. 

%   AttributeBegin/End 
%    Each such block and creates an asset.  Because these can be
%    nested (i.e., we have AttributeBegin/End within such a block), this 
%    routine is recursive (calls itself).
%
%   NamedMaterial-Shapes
%    Some scenes do not have a Begin/End, just a series of
%    NamedMaterial followed by shapes.
%
%   This routine fails on some 'wild' type PBRT scenes. In those
%   casses we try setting thisR.exporter = 'Copy'. 
%
%   A limitation si that we do not have an overview of the whole
%   'world' text at the beginning. Maybe we should do a quick first
%   pass?  To see whether everything is between an AttributeBegin/End
%   grouping, or to determine the Material-Shapes sequences?
%
% More details
%
%   For the AttributeBegin/End case
%
%       a) 'AttributeBegin': this is the beginning of a block. We will
%       keep looking for node/object/light information until we reach
%       the 'AttributeEnd'.  Remember, though, this is recursive.  So
%       we might have multiple Begin/End pairs within a Begin/End
%       pair.
%
%       b) Node/object/light information: The text within a
%       AttributeBegin/End section may contain multiple types of
%       information.  For example, about the object rotation, position,
%       scaling, shape, material properties, light spectrum information. We
%       do our best to parse this information, and then the parameters are
%       stored in the appropriate location within the asset tree in the
%       recipe.
%
%       c) 'AttributeEnd': When we reach this line, we close up this node
%       and add it to the array of what we call 'subnodes'. We know whether
%       it is a branch node by whether it  has children.  'Object' and
%       'Light' nodes are the leaves of the tree and have no children.
%       Instance nodes are copies of Objects and thus also are leaves.
%
%  If we do not have AttributeBegin/End blocks, for example in the
%  kitchen.pbrt scene, we may have lines like
%
%     NamedMaterial
%     Shape
%     Shape
%     NamedMaterial
%     Shape
%     NamedMaterial
%
%  In that case we create a new object for each shape line, and we
%  assign it the material listed above the shape.
%
% See also
%   parseObjectInstanceText

% res = [];
% groupobjs = [];
% children = [];

% This routine processes the text and returns a cell array of trees that
% will be part of the whole asset tree. In many cases the returned tree
% will be the whole asset tree for the recipe.
subtrees = {};

% We sometimes have multiple objects inside one Begin/End group that have
% the same name.  We add an index in this routine to distinguish them.  See
% below.
objectIndex = 0;

% Multiple material and shapes can be used for one object.
nMaterial   = 0;
nShape      = 0;

% This code seems designed to work only with the AttributeBegin/End
% format.  Perhaps we should look for AttributeBegin, and if there are
% none in the txt, we should parse with the other style (BW).

% Counts which line we are on.  At the end we return how many lines we
% have counted (parsedUntil)
cnt = 1;
while cnt <= length(txt)

    % For debugging, I removed the semicolon
    currentLine = txt{cnt};

    % Remove trailing spaces from the current line.
    % This is now done in piReadText
    %
    % idx = find(currentLine ~=' ',1,'last');
    % currentLine = currentLine(1:idx);

    % ObjectInstances are treated specially. If the line specifies an
    % ObjectInstance and is not a comment, we delete any quotation marks
    % after the string 'ObjectInstance '
    % Why (BW?)
    if piContains(currentLine, 'ObjectInstance') && ~strcmp(currentLine(1),'#')
        InstanceName = erase(currentLine(length('ObjectInstance '):end),'"');
    end

    if strcmp(currentLine,'AttributeBegin')
        % We reached a line with AttributeBegin. If the next line is
        % also an AttributeBegin (nested) we will be back here after
        % the following call.  If it is not, we will parse the
        % contents of the next line using other parts of this routine
        % to generate a subnode.
        [subnodes, retLine] = parseGeometryText(thisR, txt(cnt+1:end), name);

        % We now have a subnode and a returned line, where we should
        % continue our analysis at line number (retLine) next time
        % around.

        % We are mostly dealing with the names of the subnodes in
        % here.
        %
        % For piLabel (the pixel level labeling algorithm) to work, we
        % need to have subnodes.Node to be >=2. But in that case, the
        % labels can get pretty ugly, with recursive objectIndex
        % values. It would be much better if the labels were based on
        % the == 2 condition, not this >= 2 case. (BW: I think I wrote
        % this.  I am confused by it).
        if numel(subnodes.Node) >= 2 && strcmp(subnodes.Node{end}.type, 'object')
            % The last node is an object.  When we only process for == 2,
            % the pixel-wise labeling method, piLabel, fails. So we
            % don't come in here for == 2.
            lastNode = subnodes.Node{end};
            if strcmp(lastNode.type,'object')
                % The last node is an object and we are careful about
                % its name.
                %
                % In some cases (e.g., the Macbeth color checker) there is
                % one ObjectName in the comment, but multiple components to
                % the object (the patches). We need to distinguish the
                % components. We use the objectIndex to distinguish them.
                %
                % But when we allow processing with >2 nodes, we
                % repeatedly add an objectIndex to the node name.
                % That's ugly, but runs.
                objectIndex = objectIndex+1;
                lastNode.name = sprintf('%03d_%s',objectIndex, lastNode.name);
                subnodes = subnodes.set(numel(subnodes.Node),lastNode);

                % This is the base name, with the _O part removed.  It has
                % the object index in it.
                baseName = lastNode.name(1:end-2);

                % The other subnodes above the object are checked.  If
                % they are unlabeled we give them the same name but
                % _B, rather than _O.
                for ii=(numel(subnodes.Node)-1):-1:1
                    thisNode = subnodes.Node{ii};
                    if isequal(thisNode.name,'_B')
                        % An empty name.  So let's change it and put it
                        % in place.
                        thisNode.name = sprintf('%s_B',baseName);
                        subnodes = subnodes.set(ii,thisNode);
                    end
                end
            end
        end

        % This is the main point of this section.  Add the subnodes to
        % the subtrees.
        subtrees = cat(1, subtrees, subnodes);
        cnt =  cnt + retLine;

    elseif contains(currentLine,{'#ObjectName','#object name','#CollectionName','#Instance','#MeshName'}) && ...
            strcmp(currentLine(1),'#')

        % Name
        [name, sz] = piParseObjectName(currentLine);

    elseif strncmp(currentLine,'Transform ',10) ||...
            piContains(currentLine,'ConcatTransform')

        % Translation
        [translation, rot, scale] = parseTransform(currentLine);

    elseif piContains(currentLine,'MediumInterface') && ~strcmp(currentLine(1),'#')
        % MediumInterface could be water or other scattering media.
        medium = currentLine;

    elseif piContains(currentLine,'NamedMaterial') && ~strcmp(currentLine(1),'#')
        nMaterial = nMaterial+1;
        mat{nMaterial} = piParseGeometryMaterial(currentLine); %#ok<AGROW>

    elseif strncmp(currentLine,'Material',8) && ~strcmp(currentLine(1),'#')

        % Material
        mat = parseBlockMaterial(currentLine);

    elseif piContains(currentLine,'AreaLightSource') && ~strcmp(currentLine(1),'#')
        % lght is not created here. The light is created below.
        areaLight = currentLine;

    elseif piContains(currentLine,'LightSource') || ...
            piContains(currentLine, 'Rotate') ||...
            piContains(currentLine, 'Scale') && ~strcmp(currentLine(1),'#')

        % Usually light source contains only one line. Exception is there
        % are rotations or scalings
        if ~exist('lght','var')
            lght{1} = currentLine;
        else
            lght{end+1} = currentLine; %#ok<AGROW>
        end

    elseif piContains(currentLine,'Shape') && ~strcmp(currentLine(1),'#')

        % Shape
        nShape = nShape+1;
        shape{nShape} = piParseShape(currentLine);

    elseif strcmp(currentLine,'AttributeEnd')
        % What do we do if we have a namedmaterial (light) and a shape
        % (trianglemesh)? What kind of a node is that?  cornell_box.pbrt
        %

        % Let's make this a separate function.  This is what we do after we
        % get to the AttributeEnd line in the block.

        % At this point we know what kind of node we have, so we create a
        % node of the right type.
        %
        % Another if/else sequence.
        %
        %   * If certain properties are defined, we process this node
        %   further.
        %   * The properties depend on the node type (light or asset)

        %  Do we have something at all worth doing?
        if exist('areaLight','var') || exist('lght','var') ...
                || exist('rot','var') || exist('translation','var') || ...
                exist('shape','var') || ...
                exist('mediumInterface','var') || exist('mat','var')

            % We have something.  It is either a 'light' or an 'object',
            % material or medium.  Create the subtree with the added light
            % or object.
            if exist('areaLight','var') || exist('lght','var')
                % It is a light

                resLight = piAssetCreate('type', 'light');
                if exist('lght','var')
                    % Wrap the light text into attribute section
                    lghtWrap = [{'AttributeBegin'}, lght(:)', {'AttributeEnd'}];
                    resLight.lght = piLightGetFromText(lghtWrap, 'print', false);
                end
                if exist('areaLight','var')
                    resLight.lght = piLightGetFromText({areaLight}, 'print', false);
                    if exist('shape', 'var')
                        % What happens to an area light without a
                        % shape?
                        resLight.lght{1}.shape = shape;
                    end
                end

                if exist('name', 'var')
                    if isempty(name), name = sprintf('light-%d',randi(1000,1)); end
                    resLight.name = sprintf('%s_L', name);
                    resLight.lght{1}.name = resLight.name;
                else
                    warning('No name for light on line %d',cnt);
                end

                % Add the light asset to the collection of subtrees.
                subtrees = cat(1, subtrees, tree(resLight));

                % ------- Fill in object node properties
            elseif exist('shape','var') || exist('medium','var') || exist('mat','var')
                % It is an object, medium, or material

                % This AttributeBegin/End has a material or medium, but no
                % shape.  We don't want to change the tree.  The material
                % or medium should have been handled by the parse
                % materials.
                if ~exist('shape','var')
                    % This is not the right way to return.  Need to
                    % figure it out.
                    warning('Material or medium with no shape.');
                    trees = [];
                    parsedUntil = cnt;
                    return;
                elseif iscell(shape) %#ok<NODEF>
                    shape = shape{1};
                end

                % We create object (assets) here.  If the shape is
                % empty for an asset, we will have a problem later.
                % So check how that can happen.
                %
                % I don't understand why we are creating materials or
                % mediumInterface here.  I need to ask Zhenyi, Henryk,
                % and Zheng. Such materials do get created in
                % contemporary-bathroom, but not, say, in kitchen.
                resObject = piAssetCreate('type', 'object');

                % Set the object name
                if exist('name','var')
                    resObject.name = sprintf('%s_O', name);
                else
                    % Name not found. In that case we assign an object
                    % name with priority:
                    %
                    %   (1) Check if ply file name exists
                    %   (2) Check if named material exists
                    %   (3) (Worst case) Only material type exists
                    %
                    if ~isempty(shape.filename)
                        [~, n, ~] = fileparts(shape.filename);

                        % If there was a '_mat0' added to the ply file name
                        % remove it.
                        if contains(n,'_mat0'), n = erase(n,'_mat0'); end

                        % Add the _O because it is an object.
                        resObject.name = sprintf('%s_O', n);
                    elseif ~isempty(mat)
                        warning('Assigning the object a material name with no shape.filename or name.')
                        resObject.name = sprintf('%s_O',mat.namedmaterial);
                    else
                        warning('No name for this (shape or mat or medium).');
                    end
                end
                %{
                    elseif ~isempty(mat)
                        % This is a problem for remote rendering.
                        %
                        % We need a way to assign a named material to
                        % this object.  We want the name to be unique.
                        % For now, we just pick a random number.  Some
                        % chance of a duplicate, but not much.
                        mat = mat{1}; % tmp fix
                        resObject.name = sprintf('%s-%d_O',mat.namedmaterial,randi(1e6,1));
                        warning('Random material name %s',resObject.name);

                    elseif exist('medium','var')
                        % If we get here, figure out how to set the
                        % name.
                        warning('medium, but no name set.');
                        resObject.medium = medium;
                    end
                %}

                % Always set these, even if there is no name.
                % Why wouldn't there be a name?
                % Also, can we have a material or a medium, but not both?
                % {
                resObject.shape = shape;

                if exist('mat','var')  && ~isempty(mat)
                    resObject.material = mat;
                end

                if exist('medium','var'), resObject.medium = medium; end

                % Add this object into the subtrees.
                subtrees = cat(1, subtrees, tree(resObject));

            end

            % Create a branch node that will sit on top of the light or
            % object, containing the transformation information
            resCurrent = piAssetCreate('type', 'branch');

            % If present populate fields.
            if exist('name','var'), resCurrent.name = sprintf('%s_B', name); end

            if exist('InstanceName','var')
                resCurrent.referenceObject = InstanceName;
            end

            if exist('rot','var') || exist('translation','var') || exist('scale', 'var')
                if exist('sz','var'), resCurrent.size = sz; end
                if exist('rot','var'), resCurrent.rotation = {rot}; end
                if exist('translation','var'), resCurrent.translation = {translation}; end
                if exist('scale','var'), resCurrent.scale = {scale}; end
            end

            trees = tree(resCurrent);
            for ii = 1:numel(subtrees)
                % TODO: solve the empty node name problem here
                trees = trees.graft(1, subtrees(ii));
            end

        elseif exist('name','var')
            % We got this far, but all we have is a name. There are no
            % light or object properties.
            %
            % So we create a branch, with no parameters, and add it to the
            % main tree.
            %
            % Should we add this?
            % warning('Empty branch added on line %d',cnt);
            resCurrent = piAssetCreate('type', 'branch');
            if exist('name','var'), resCurrent.name = sprintf('%s_B', name); end
            trees = tree(resCurrent);
            for ii = 1:numel(subtrees)
                trees = trees.graft(1, subtrees(ii));
            end
        end

        % Return, indicating how far we have gotten in the txt
        parsedUntil = cnt;
        return;
    else
        % WorldBegin gets here.  Other stuff?
        % warning('Current line skipped: %s', currentLine);
        %
    end % AttributeBegin

    cnt = cnt+1;

end
parsedUntil = cnt;  % Returned.

%% We build the main tree that is returned from any defined subtrees

% Debugging.
fprintf('Identified %d assets; parsed up to line %d\n',numel(subtrees),cnt);

% Each subtree is an asset.
if ~isempty(subtrees)
    % ZLY: modified the root node to a identity transformation branch node.
    % Need more test
    rootAsset = piAssetCreate('type', 'branch');
    rootAsset.name = 'root_B';
    trees = tree(rootAsset);

    % Graft each of the subtrees to the root node
    for ii = 1:numel(subtrees)
        trees = trees.graft(1, subtrees(ii));
    end
else
    trees=[];
end

end
