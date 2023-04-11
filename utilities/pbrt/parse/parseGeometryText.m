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

% persistent ABLoop;

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

    % The ObjectInstances are currently created in parseObjectInstanceText.
    % When we have an ObjectInstance line here, it is a text string that
    % refers to an object instance.  We set this strength as the
    % referenceObject below. 
    % BW moved this test into the if/else...  cases below rather than here.
    %{
    if piContains(currentLine, 'ObjectInstance') && ~strcmp(currentLine(1),'#')
        InstanceName = erase(currentLine(length('ObjectInstance ')+1:end),'"');
    end
    %}

    % ABLoop = false;
    if strcmp(currentLine,'AttributeBegin')
        % Entering an AttributeBegin/End block
        % ABLoop = true;
        % fprintf('loop = %d - %s\n',ABLoop,currentLine);

        % Parse the next lines for materials, shapes, lights. If
        % we run into another AttributeBegin, we recursively come back
        % here.  Typically, we return here with the subnodes from the
        % AttributeBegin/End block.
        [subnodes, retLine] = parseGeometryText(thisR, txt(cnt+1:end), name);
        
        % We now have the collection of subnodes from this
        % AttributeBegin/End block.  Also we know the returned line number
        % (retLine) where we will continue.
        
        % Group the subnodes from this Begin/End block with the others that
        % have collected into the variable subtrees.
        subtrees = cat(1, subtrees, subnodes);

        % Update where we start from
        cnt =  cnt + retLine;

    elseif contains(currentLine,{'#ObjectName','#object name','#CollectionName','#Instance','#MeshName'}) && ...
            strcmp(currentLine(1),'#')

        % Name
        [name, sz] = piParseObjectName(currentLine);

    elseif contains(currentLine, 'ObjectInstance') && ~strcmp(currentLine(1),'#')
        % The object instance will be assigned to the branch node after
        % AttributeEnd.
        InstanceName = erase(currentLine(length('ObjectInstance ')+1:end),'"');    

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
        % ABLoop = false;  
        % Exiting a Begin/End block
        % fprintf('loop = %d - %s\n',ABLoop,currentLine);

        % We have come to the AttributeEnd. We accumulate the
        % parameters we read into a node.  The type of node will
        % depend on the parameters we found since the AttributeBegin
        % line.

        % At this point we know what kind of node we have, so we create a
        % node of the right type.
        %
        % Another if/else sequence.
        %
        %   * If certain properties are defined, we process this node
        %   further.
        %   * The properties depend on the node type (light or asset)

        %  We have a light or a object if this conditions is met
        if exist('areaLight','var') || exist('lght','var') ...
                || exist('rot','var') || exist('translation','var') || ...
                exist('shape','var') || ...
                exist('mediumInterface','var') || exist('mat','var')

            % In this case, we detected a light of some type.
            if exist('areaLight','var') 
                % Adds the area light asset to the collection of subtrees
                % that we are building.
                if ~exist('shape','var'), shape = []; end
                if ~exist('name','var'), name = '';   end
                resLight = parseGeometryAreaLight(thisR,areaLight,name,shape);
                subtrees = cat(1, subtrees, tree(resLight));

            elseif exist('lght','var')
                
                if ~exist('name','var'), name = '';   end
                resLight = parseGeometryLight(thisR,lght,name);
                subtrees = cat(1, subtrees, tree(resLight));

                % ------- A shape.  Create an object node
            elseif exist('shape','var') % || exist('medium','var') || exist('mat','var')
                % We have a shape.  We just exited from an
                % AttributeEnd

                % Shouldn't we be looping over numel(shape)?
                if iscell(shape), shape = shape{1}; end
                if ~exist('name','var')
                    % The name might have been passed in
                    name = piShapeNameCreate(shape,true,thisR.get('input basename'));
                end

                % We create object (assets) here.
                if exist('mat','var'), oMAT = mat;   else, oMAT = []; end
                if exist('medium','var'), oMEDIUM = medium; else, oMEDIUM = []; end
                resObject = parseGeometryObject(shape,name,oMAT,oMEDIUM);

                % Makes a tree of this object and adds that into the
                % collection of subtrees we are building.
                subtrees = cat(1, subtrees, tree(resObject));
            end

            % Create a parent branch node with the transform information for
            % the object, light, or arealight.
            %
            % Sometimes are here with some transform information
            % (following an AttributeEnd), and we put in a branch
            % node.  

            % When there is no name, I make up this special case. This
            % happens at the end of ChessSet.  There is an
            % AttributeBegin/End with only a transform, but no mesh
            % name.
            if ~exist('name','var'), bNAME = 'AttributeEnd'; 
            else, bNAME = name;
            end

            if exist('sz','var'),  oSZ = sz; else, oSZ = []; end
            if exist('rot','var'), oROT = rot; else, oROT = []; end
            if exist('translation','var'),oTRANS = translation; else, oTRANS = []; end
            if exist('scale','var'),oSCALE = scale; else, oSCALE = []; end

            resCurrent = parseGeometryBranch(bNAME,oSZ,oROT,oTRANS,oSCALE);

            % If we have defined an Instance (ObjectBegin/End) then we
            % assign it to a branch node here.
            if exist('InstanceName','var')
                resCurrent.referenceObject = InstanceName; 
            end

            % Adding this resCurrent branch above the light and object
            % nodes in this subtree.  The subtrees are below this branch
            % with its transformation.
            trees = tree(resCurrent);
            for ii = 1:numel(subtrees)
                trees = trees.graft(1, subtrees(ii));
            end

        elseif exist('name','var')  && ~isempty(name)
            % We have a name, but not shape, lght or arealight.
            %
            % Zheng remembers that we used this for the Cinema4D case when
            % we hung a camera under a marker position.  It is possible
            % that we should stop doing that.  We should try to get rid of
            % this condition.
            %
            resCurrent = piAssetCreate('type', 'branch');

            if length(name) < 2 || ~isequal(name(end-1:end),'_B')            
                resCurrent.name = sprintf('%s_B', name); 
            else  % Already ends with '_B'
                resCurrent.name = name;
            end
            trees = tree(resCurrent);
            for ii = 1:numel(subtrees)
                trees = trees.graft(1, subtrees(ii));
            end
        else
            % No objects or name.  This is probably an empty block
            %   AttributeBegin
            %   AttributeEnd
            % Maybe we just return subtrees as the trees.
            trees = subtrees;

        end  % AttributeEnd

        % Return, indicating how far we have gotten in the txt
        parsedUntil = cnt;

        % We always have the trees at this point.
        % if ~exist('trees','var'), warning('trees not defined'); end

        return;
    else
        % Starting to manage the case of kitchen.pbrt where there are no
        % AttributeBegin/End blocks.  This section of code is not properly
        % tested and should be clarified.
        warning('Untested section.  We should not be here.')
        % Also, if there is no AttributeBegin but there is a shape, we
        % get here.  Perhaps there has been a transform, as well.
        if exist('shape','var') && exist('mat','var')
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
                if length(name) < 2  || isequal(name(end-1:end),'_O'), resObject.name = name;
                else, resObject.name = sprintf('%s_O', name);
                end
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

    % We were at the AttributeEnd.  We move one more step forward.
    cnt = cnt+1;

end
parsedUntil = cnt;  % Return and start at this line.

%% We build the tree that is returned from any of the defined subtrees

% Debugging.
fprintf('Identified %d assets; parsed up to line %d\n',numel(subtrees),cnt);

% We create the root node here, placing it as the root of all of the
% subtree branches.
if ~isempty(subtrees)
    rootAsset = piAssetCreate('type', 'branch');
    rootAsset.name = 'root_B';
    trees = tree(rootAsset);

    % Graft each of the subtrees to the root node
    for ii = 1:numel(subtrees)
        trees = trees.graft(1, subtrees(ii));
    end
else
    % Hmm. There were no subtrees.  So no root.  Send the whole thing back
    % as empty.
    warning('Empty tree.')
    trees=[];
end

% if ~exist('trees','var'), warning('trees not defined'); end

end

%% Helper functions
% parseGeometryBranch
% parseGeometryObject

%% Make a branch node
function resCurrent = parseGeometryBranch(name,sz,rot,translation,scale)
% Create a branch node with the transform information.

% This should be the parent of the light or object,
resCurrent = piAssetCreate('type', 'branch');

% It is a branch.  Adjust the name
if length(name) < 3  
    % Could be a single character name, such as 'A'
    resCurrent.name = sprintf('%s_B', name);
elseif ~isequal(name(end-1:end),'_B')
    % At least 3, but not the right ending.
    switch name(end-1:end)
        case {'_L','_O'}
            % Replace with _B
            name(end-1:end) = '_B';
            resCurrent.name = name;
        otherwise
            % Append _B
            resCurrent.name = sprintf('%s_B', name);
    end
else
    % >= 3 and ends in _B.  Good to go.
    resCurrent.name = name;
end

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
if length(name) < 3 || ~isequal(name(end-1:end),'_O')
    resObject.name = sprintf('%s_O', name);
else
    resObject.name = name;
end


% Hopefully we have a material or medium for this object. If not, then PBRT
% uses coateddiffuse as a default, I think.
if ~isempty(mat),    resObject.material = mat;  end
if ~isempty(medium), resObject.medium = medium; end

end

%% Make an area light struct forthe tree
function resLight = parseGeometryAreaLight(thisR,areaLight,name,shape)

isNode = true;
baseName = thisR.get('input basename');

resLight = piAssetCreate('type', 'light');

resLight.lght = piLightGetFromText({areaLight}, 'print', false);
if ~isempty(shape)
    resLight.lght{1}.shape = shape;
else, warning("Area light with no shape.");
end

% Manage the name with an _L at the end.
if isempty(name)
    name = piLightNameCreate(resLight.lght,isNode,baseName);
end

% We have two names.  One for the node and one for the
% object itself, I guess. (BW).
resLight.name = name;
resLight.lght{1}.name = resLight.name;
end

%% Make a light struct for the tree
function resLight = parseGeometryLight(thisR,lght,name)

isNode = true;
baseName = thisR.get('input basename');

resLight = piAssetCreate('type', 'light');

if exist('lght','var')
    % Wrap the light text into attribute section
    lghtWrap = [{'AttributeBegin'}, lght(:)', {'AttributeEnd'}];
    resLight.lght = piLightGetFromText(lghtWrap, 'print', false);
end

if isempty(name)
    name = piLightNameCreate(resLight.lght,isNode,baseName);
end

% We have two names.  One for the node and one for the
% object itself, I guess. (BW).
resLight.name = name;
resLight.lght{1}.name = resLight.name;

end
