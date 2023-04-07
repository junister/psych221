function [trees, parsedUntil] = parseGeometryText(thisR, txt, name)
% function [trees, parsedUntil] = parseGeometryText(thisR, txt, name)
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
%   name        - Use this object name
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

persistent ABLoop;

% This routine processes the text and returns a cell array of trees that
% will be part of the whole asset tree. In many cases the returned tree
% will be the whole asset tree for the recipe.
subtrees = {};

% We sometimes have multiple objects inside one Begin/End group that have
% the same name.  We add an index in this routine to distinguish them.  See
% below.
% Removed when we changed to making the object names unique in piRead.
% objectIndex = 0;

% Multiple material and shapes can be used for one object.
nMaterial   = 0;
nShape      = 0;

% Strip WorldBegin
if isequal(txt{1},'WorldBegin'),  txt = txt(2:end); end

% This code is initially designed to work only with the
% AttributeBegin/End format.  Perhaps we should look for
% AttributeBegin, and if there are none in the txt, we should parse
% with the other style (BW).
% Counts which line we are on.  At the end we return how many lines we
% have counted (parsedUntil)
% if isempty(txt{1}), warning('Empty text line.'); end
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

    ABLoop = false;
    if strcmp(currentLine,'AttributeBegin')
        % Entering an AttributeBegin/End block
        ABLoop = true;
        % fprintf('loop = %d - %s\n',ABLoop,currentLine);

        % Parse the next few lines for materials, shapes, lights. If
        % we run into another AttributeBegin, we recursively come back
        % here.  Typically, we return here with the subnodes from the
        % AttributeBegin/End block.
        [subnodes, retLine] = parseGeometryText(thisR, txt(cnt+1:end), name);
        
        % We now have the collection of nodes from the
        % AttributeBegin/End block, and the returned line number
        % (retLine) to continue.        
        
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
        %{
        if ~ABLoop
            fprintf('Named material out of loop: %s\n',mat{nMaterial}.namedmaterial);
        end
        %}
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
        % Shape - We have a shape.  Why don't we create the object
        % now?  And we add any existing material to it?
        nShape = nShape+1;
        shape{nShape} = piParseShape(currentLine);
        %{
        if ~ABLoop
            % We are not in an AttributeBegin Loop.  In that case,
            % every time we find a shape, we add it and the current
            % material to the subnodes.  We will need to update
            % nShape, also.
            fprintf('%d: %s\n',cnt,currentLine);
            fprintf('nShape = %d\n',nShape);
            fprintf('%s\n',mat{end}.namedmaterial);
            pause;
        end
        %}
    elseif strcmp(currentLine,'AttributeEnd')
        ABLoop = false;  % Exiting a Begin/End block
        % fprintf('loop = %d - %s\n',ABLoop,currentLine);

        % We have come to the AttributeEnd. We accumulate the
        % information we have read into a node.  The type of node will
        % depend on what we read since the AttributeBegin line.

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
                % We detected a light of some type.

                isNode = true;
                baseName = thisR.get('input basename');
                % function resLight = parseGeometryLight();
                % end

                resLight = piAssetCreate('type', 'light');
                if exist('lght','var')
                    % Wrap the light text into attribute section
                    lghtWrap = [{'AttributeBegin'}, lght(:)', {'AttributeEnd'}];
                    resLight.lght = piLightGetFromText(lghtWrap, 'print', false);
                end
                if exist('areaLight','var')
                    resLight.lght = piLightGetFromText({areaLight}, 'print', false);
                    if exist('shape', 'var')
                        resLight.lght{1}.shape = shape;
                    else, warning("Area light with no shape.");
                    end
                end

                % Manage the name with an _L at the end.
                if ~exist('name','var') || isempty(name)
                    name = piLightNameCreate(resLight.lght,isNode,baseName);
                elseif length(name) < 2 || ~isequal(name(end-1:end),'_L')
                    name = sprintf('%s_L', name);
                end

                % We have two names.  One for the node and one for the
                % object itself, I guess. (BW).
                resLight.name = name;
                resLight.lght{1}.name = resLight.name;

                % Add the light asset to the collection of subtrees.
                subtrees = cat(1, subtrees, tree(resLight));

                % ------- A shape.  Create an object node
            elseif exist('shape','var') % || exist('medium','var') || exist('mat','var')
                % We have a shape.  We just exited from an
                % AttributeEnd

                if iscell(shape), shape = shape{1}; end
                if ~exist('name','var')
                    % The name might have been passed in
                    name = piShapeNameCreate(shape,true,thisR.get('input basename'));
                elseif length(name) < 2 || ~isequal(name(end-1:end),'_O')
                    name = sprintf('%s_O',name);
                end

                % We create object (assets) here.
                if exist('mat','var'), oMAT = mat;   else, oMAT = []; end
                if exist('medium','var'), oMEDIUM = medium; else, oMEDIUM = []; end
                resObject = parseGeometryObject(shape,name,oMAT,oMEDIUM);

                % Add this object into the subtrees.
                subtrees = cat(1, subtrees, tree(resObject));

            end

            % Create a branch node with the transform information.
            % This should be the parent of the light or object.
            % Sometimes we end up here following an AttributeEnd and
            % we put in a branch node.  I am not sure why.  To keep
            % things moving, I make up an AttributeEnd name for such a
            % node.  Otherwise, we have a name.
            if exist('name','var') && ~isempty(name)
                oNAME = name; else, oNAME = 'AttributeEnd'; 
            end
            if exist('sz','var'),  oSZ = sz; else, oSZ = []; end
            if exist('rot','var'), oROT = rot; else, oROT = []; end
            if exist('translation','var'),oTRANS = translation; else, oTRANS = []; end
            if exist('scale','var'),oSCALE = scale; else, oSCALE = []; end

            resCurrent = parseGeometryBranch(oNAME,oSZ,oROT,oTRANS,oSCALE);

            if exist('InstanceName','var'), resCurrent.referenceObject = InstanceName; end

            trees = tree(resCurrent);
            for ii = 1:numel(subtrees)
                trees = trees.graft(1, subtrees(ii));
            end

        elseif exist('name','var')
            % We got this far, but all we have is a name. This happens
            % when we have an AttributeEnd on the currentLine.  Let's
            % fix it.
            % warning('Empty branch added on line %d: %s',cnt,currentLine);
            % trees = subtrees;
            % {
            resCurrent = piAssetCreate('type', 'branch');
            if exist('name','var'), resCurrent.name = sprintf('%s_B', name); end
            trees = tree(resCurrent);
            for ii = 1:numel(subtrees)
                trees = trees.graft(1, subtrees(ii));
            end
            %}
        else
            % No objects or name.  This is probably an empty block
            %   AttributeBegin
            %   AttributeEnd
            % Maybe we just return subtrees as the trees.
            trees = subtrees;

        end  % AttributeEnd

        % Return, indicating how far we have gotten in the txt
        parsedUntil = cnt;

        if ~exist('trees','var'), warning('trees not defined'); end

        return;
    else
        % WorldBegin gets here.
        % Also, if there is no AttributeBegin but there is a shape, we
        % get here.  Perhaps there has been a transform, as well.
        if strcmp(currentLine,'WorldBegin')
            % Do nothing
            disp('WorldBegin')
        elseif exist('shape','var') && exist('mat','var')
            if iscell(shape), shape = shape{1}; end

            % We create object (assets) here.  If the shape is
            % empty for an asset, we will have a problem later.
            % So check how that can happen.
            %
            % I don't understand why we are creating materials or
            % mediumInterface here.  I need to ask Zhenyi, Henryk,
            % and Zheng. Such materials do get created in
            % contemporary-bathroom, but not, say, in kitchen.
            resObject = piAssetCreate('type', 'object');
            resObject.shape = shape;

            % Set the object name
            if exist('name','var')
                resObject.name = sprintf('%s_O', name);
            else
                resObject.name = piReadObjectName(shape);
            end

            % Hopefully we have a material or medium for this object.
            if exist('mat','var')  && ~isempty(mat)
                resObject.material = mat;
            end

            if exist('medium','var'), resObject.medium = medium; end

            % Add this object into the subtrees.
            subtrees = cat(1, subtrees, tree(resObject));
        end

    end % AttributeBegin

    cnt = cnt+1;

end
parsedUntil = cnt;  % Returned.

%% We build the tree that is returned from any of the defined subtrees

% Debugging.
fprintf('Identified %d assets; parsed up to line %d\n',numel(subtrees),cnt);

% Each subtree is an asset.
if ~isempty(subtrees)
    % ZLY:
    % Modified the root node to a identity transformation branch node.
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

if ~exist('trees','var'), warning('trees not defined'); end

end

%% Helper functions
% parseGeometryBranch
% parseGeometryObject

%% Make a branch node
function resCurrent = parseGeometryBranch(name,sz,rot,translation,scale)
% Create a branch node with the transform information.

% This should be the parent of the light or object,
resCurrent = piAssetCreate('type', 'branch');

% If present populate fields.
if ~isempty('name'), resCurrent.name = sprintf('%s_B', name); end

if ~isempty(sz), resCurrent.size = sz; end
if ~isempty(rot), resCurrent.rotation = {rot}; end
if ~isempty(translation), resCurrent.translation = {translation}; end
if ~isempty(scale), resCurrent.scale = {scale}; end

end

%% Make an object node
function resObject = parseGeometryObject(shape,name,mat,medium)
% Create an object node with the shape and material information

resObject = piAssetCreate('type', 'object');
resObject.shape = shape;
resObject.name = name;

% Hopefully we have a material or medium for this object.
if ~isempty(mat),    resObject.material = mat;  end
if ~isempty(medium), resObject.medium = medium; end

end

