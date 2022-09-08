function  piGeometryWrite(thisR,varargin)
% Write out a geometry file that matches the format and labeling objects
%
% Synopsis
%   piGeometryWrite(thisR,varargin)
%
% Input:
%   thisR: a render recipe
%   obj:   Returned by piGeometryRead, contains information about objects.
%
% Optional key/value pairs
%
% Output:
%   None
%
% Description
%   We need a better description of objects and groups here.  Definitions
%   of 'assets'.
%
% Zhenyi, 2018
%
% See also
%   piGeometryRead
%
%%
p = inputParser;

% Not needed now.
% varargin = ieParamFormat(varargin);

p.addRequired('thisR',@(x)isequal(class(x),'recipe'));
p.parse(thisR,varargin{:});

%% Create the default file name

% Get the fullname of the geometry file to write
[Filepath,scene_fname] = fileparts(thisR.outputFile);
fname = fullfile(Filepath,sprintf('%s_geometry.pbrt',scene_fname));[~,n,e]=fileparts(fname);

% Get the assets from the recipe
obj = thisR.assets;

%% Write the geometry file...

fname_obj = fullfile(Filepath,sprintf('%s%s',n,e));

% Open the file and write out the assets
fid_obj = fopen(fname_obj,'w');
fprintf(fid_obj,'# Exported by piGeometryWrite on %i/%i/%i %i:%i:%f \n  \n',clock);

% Traverse the asset tree beginning at the root
rootID = 1;

% Write object and light definitions in the main geometry
% and any needed child geometry files
if ~isempty(obj)
    recursiveWriteNode(fid_obj, obj, rootID, Filepath, thisR.outputFile);

    % Write tree structure in main geometry file
    lvl = 0;
    writeGeometryFlag = 0;
    recursiveWriteAttributes(fid_obj, obj, rootID, lvl, thisR.outputFile, writeGeometryFlag);
else
    % if no assets were found
    for ii = numel(thisR.world)
        fprintf(fid_obj, thisR.world{ii});
    end
end
fclose(fid_obj);

% Not sure we want this most of the time, can un-comment as needed
%fprintf('%s is written out \n', fname_obj);

end

function recursiveWriteNode(fid, obj, nodeID, rootPath, outFilePath)
% Define each object in geometry.pbrt file. This section writes out
% (1) Material for every object
% (2) path to each child geometry file
%     which store the shape and other geometry info.
%
% The process is:
%   (1) Get the children of the current node
%   (2) For each child, check if it is an 'object' or 'light' node.
%       If it is, write it out.
%   (3) If the child is a 'branch' node, put it in a list which will be
%       recursively checked in the next level of our traverse.

%% Get children of our current Node (thisNode)
children = obj.getchildren(nodeID);

%% Loop through all children of our current node (thisNode)
% If 'object' node, write out. If 'branch' node, put in the list

% Create a list for next level recursion
nodeList = [];

for ii = 1:numel(children)

    % set our current node to each of the child nodes
    thisNode = obj.get(children(ii));

    % If a branch, put id in the nodeList
    if isequal(thisNode.type, 'branch')
        % do not write object instance repeatedly
        nodeList = [nodeList children(ii)];
        if isfield(thisNode,'isObjectInstance')
            if thisNode.isObjectInstance ==1
                indentSpacing = "    ";
                fprintf(fid, 'ObjectBegin "%s"\n', thisNode.name(8:end-2));
                if ~isempty(thisNode.motion)
                    fprintf(fid, strcat(spacing, indentSpacing,...
                        'ActiveTransform StartTime \n'));
                end

                arealight = 0; % light can't be used as instance.
                piGeometryTransformWrite(fid, thisNode, "", indentSpacing, 0);

                % Write out motion
                if ~isempty(thisNode.motion)
                    for jj = 1:size(thisNode.translation, 2)
                        fprintf(fid, strcat(spacing, indentSpacing,...
                            'ActiveTransform EndTime \n'));

                        % First write out the same translation and rotation
                        piGeometryTransformWrite(fid, thisNode, spacing, indentSpacing, arealight);

                        if isfield(thisNode.motion, 'translation')
                            if isempty(thisNode.motion.translation(jj, :))
                                fprintf(fid, strcat(spacing, indentSpacing,...
                                    'Translate 0 0 0\n'));
                            else
                                pos = thisNode.motion.translation(jj,:);
                                fprintf(fid, strcat(spacing, indentSpacing,...
                                    sprintf('Translate %f %f %f', pos(1),...
                                    pos(2),...
                                    pos(3)), '\n'));
                            end
                        end

                        if isfield(thisNode.motion, 'rotation') &&...
                                ~isempty(thisNode.motion.rotation)
                            rot = thisNode.motion.rotation;
                            % Write out rotation
                            fprintf(fid, strcat(spacing, indentSpacing,...
                                sprintf('Rotate %f %f %f %f',rot(:,jj*3-2)), '\n')); % Z
                            fprintf(fid, strcat(spacing, indentSpacing,...
                                sprintf('Rotate %f %f %f %f',rot(:,jj*3-1)),'\n')); % Y
                            fprintf(fid, strcat(spacing, indentSpacing,...
                                sprintf('Rotate %f %f %f %f',rot(:,jj*3)), '\n'));   % X
                        end
                    end
                end
                lvl = 1;
                writeGeometryFlag = 1;
                recursiveWriteAttributes(fid, obj, children(ii), lvl, outFilePath, writeGeometryFlag);
                fprintf(fid, 'ObjectEnd\n\n');
                % nodeID == 1 is rootID.
                if nodeID ~=1, return; end
            end
        end

        % Define object node
    elseif isequal(thisNode.type, 'object')
        % Deal with object node properties in recursiveWriteAttributes;
        %{
                while numel(thisNode.name) >= 8 &&...
                        isequal(thisNode.name(5:6), 'ID')
                    thisNode.name = thisNode.name(8:end);
                end

                fprintf(fid, 'ObjectBegin "%s"\n', thisNode.name);
                % write out objects
                ObjectWrite(fid, thisNode, rootPath, "", "");
                fprintf(fid,'\n');
                fprintf(fid, 'ObjectEnd\n\n');
        %}
    elseif isequal(thisNode.type, 'light') || isequal(thisNode.type, 'marker') || isequal(thisNode.type, 'instance')
        % That's okay but do nothing.
    else
        % Something must be wrong if we get here.
        warning('Unknown node type: %s', thisNode.type)
    end
end

% Now what we've build up a list of branch nodes that we need to
% process, pick one and recurse through it
for ii = 1:numel(nodeList)
    recursiveWriteNode(fid, obj, nodeList(ii), rootPath, outFilePath);
end

end

function recursiveWriteAttributes(fid, obj, thisNode, lvl, outFilePath, writeGeometryFlag)
% Write attribute sections. The logic is:
%   1) Get the children of the current node
%   2) For each child, write out information accordingly
%
%% Get children of this node
children = obj.getchildren(thisNode);
%% Loop through children at this level

% Generate spacing to make the tree structure more beautiful
spacing = "";
for ii = 1:lvl
    spacing = strcat(spacing, "    ");
end

% indent spacing
indentSpacing = "    ";

% indicate wheather the child node is an arealight, arealight use 'Transfom'
% other objects use 'ConcatTransform', not sure why yet. --Zhenyi
arealight = 0;

for ii = 1:numel(children)
    thisNode = obj.get(children(ii));

    if isfield(thisNode, 'isObjectInstance')
        if thisNode.isObjectInstance ==1 && ~writeGeometryFlag
            % This node is an object instance node, skip;
            continue;
        end
    end

    thisNodeChildId = obj.getchildren(children(ii));
    if ~isempty(thisNodeChildId)
        thisNodeChild = obj.get(thisNodeChildId);
        if strcmp(thisNodeChild.type, 'light') &&...
                strcmp(thisNodeChild.lght{1}.type,'area')
            arealight = 1; % this transform is for an arealight
        end
    end
    referenceObjectExist = [];
    if isfield(thisNode,'referenceObject') && ~isempty(thisNode.referenceObject)
        referenceObjectExist = piAssetFind(obj,'name',strcat(thisNode.referenceObject,'_B'));
    end

    fprintf(fid, strcat(spacing, 'AttributeBegin\n'));
    if isequal(thisNode.type, 'branch')
        % get the name after stripping ID for this Node
        while numel(thisNode.name) >= 8 &&...
                isequal(thisNode.name(5:6), 'ID')
            thisNode.name = thisNode.name(8:end);
        end
        % Write the object's dimensions
        fprintf(fid, strcat(spacing, indentSpacing,...
            sprintf('#MeshName: "%s" #Dimension:[%.4f %.4f %.4f]',thisNode.name,...
            thisNode.size.l,...
            thisNode.size.w,...
            thisNode.size.h), '\n'));

        % If a motion exists in the current object, prepare to write it out by
        % having an additional line below.  For now, this is not
        % functional.
        if ~isempty(thisNode.motion)
            fprintf(fid, strcat(spacing, indentSpacing,...
                'ActiveTransform StartTime \n'));
            % thisR.hasActiveTransform = true;
        end

        % Transformation section
        if ~isempty(thisNode.rotation)
            % Zheng: I think it is always this case, but maybe it is rarely
            % the case below. Have no clue.
            % If this way, we would write the translation, rotation and
            % scale line by line based on the order of thisNode.transorder
            piGeometryTransformWrite(fid, thisNode, spacing, indentSpacing, arealight);
            arealight = 0;
        else
            thisNode.concattransform(13:15) = thisNode.translation(:);
            fprintf(fid, strcat(spacing, indentSpacing,...
                sprintf('ConcatTransform [%.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f]', thisNode.concattransform(:)), '\n'));
            % Scale
            fprintf(fid, strcat(spacing, indentSpacing,...
                sprintf('Scale %.10f %.10f %.10f', thisNode.scale), '\n'));
        end

        % Motion section
        if ~isempty(thisNode.motion)
            fprintf(fid, strcat(spacing, indentSpacing,...
                'ActiveTransform EndTime \n'));
            for jj = 1:size(thisNode.translation, 2)


                % First write out the same translation and rotation
                piGeometryTransformWrite(fid, thisNode, spacing, indentSpacing, arealight);

                if isfield(thisNode.motion, 'translation')
                    if isempty(thisNode.motion.translation(jj, :))
                        fprintf(fid, strcat(spacing, indentSpacing,...
                            'Translate 0 0 0\n'));
                    else
                        pos = thisNode.motion.translation(jj,:);
                        fprintf(fid, strcat(spacing, indentSpacing,...
                            sprintf('Translate %f %f %f', pos(1),...
                            pos(2),...
                            pos(3)), '\n'));
                    end
                end

                if isfield(thisNode.motion, 'rotation') &&...
                        ~isempty(thisNode.motion.rotation)
                    rot = thisNode.motion.rotation;
                    % Write out rotation
                    fprintf(fid, strcat(spacing, indentSpacing,...
                        sprintf('Rotate %f %f %f %f',rot(:,3-2)), '\n')); % Z
                    fprintf(fid, strcat(spacing, indentSpacing,...
                        sprintf('Rotate %f %f %f %f',rot(:,3-1)),'\n')); % Y
                    fprintf(fid, strcat(spacing, indentSpacing,...
                        sprintf('Rotate %f %f %f %f',rot(:,3)), '\n'));   % X
                end
            end
        end

        % Reference object section (also if an instance (object copy))
        if ~isempty(referenceObjectExist) && isfield(thisNode,'referenceObject')
            fprintf(fid, strcat(spacing, indentSpacing, ...
                sprintf('ObjectInstance "%s"', thisNode.referenceObject), '\n'));
        end

        recursiveWriteAttributes(fid, obj, children(ii), lvl + 1, ...
            outFilePath, writeGeometryFlag);

    elseif isequal(thisNode.type, 'object') || isequal(thisNode.type, 'instance')
        while numel(thisNode.name) >= 8 &&...
                isequal(thisNode.name(5:6), 'ID')
            
            % remove instance suffix
            endIndex = strfind(thisNode.name, '_I_');
            if ~isempty(endIndex),    endIndex =endIndex-1;
            else,                     endIndex = numel(thisNode.name);
            end
            thisNode.name = thisNode.name(8:endIndex);
        end

        % if this is an arealight or object without a reference object
        if writeGeometryFlag || isempty(referenceObjectExist)
            [rootPath,~] = fileparts(outFilePath);
            ObjectWrite(fid, thisNode, rootPath, spacing, indentSpacing);
            fprintf(fid,'\n');
        else
            % use reference object
            fprintf(fid, strcat(spacing, indentSpacing, ...
                sprintf('ObjectInstance "%s"', thisNode.name), '\n'));
        end

    elseif isequal(thisNode.type, 'light')
        % Create a tmp recipe
        tmpR = recipe;
        tmpR.outputFile = outFilePath;
        tmpR.lights = thisNode.lght;
        lightText = piLightWrite(tmpR, 'writefile', false);

        for jj = 1:numel(lightText)
            for kk = 1:numel(lightText{jj}.line)
                fprintf(fid,sprintf('%s%s%s\n',spacing, indentSpacing,...
                    sprintf('%s',lightText{jj}.line{kk})));
            end
        end
    else
        % Hopefully we never get here.
        warning('Unknown node type %s\n',thisNode.type);
    end


    fprintf(fid, strcat(spacing, 'AttributeEnd\n'));
end

end

%% Geometry file writing helper
function piGeometryTransformWrite(fid, thisNode, spacing, indentSpacing, arealight)
% Zhenyi: export Transform matrix instead of translation/rotation/scale

pointerT = 1; pointerR = 1; pointerS = 1;
translation = zeros(3,1);
rotation = piRotationMatrix;
scale = ones(1,3);
for tt = 1:numel(thisNode.transorder)
    switch thisNode.transorder(tt)
        case 'T'
            translation = translation + thisNode.translation{pointerT}(:);
            pointerT = pointerT + 1;
        case 'R'
            rotation = rotation + thisNode.rotation{pointerR};
            pointerR = pointerR + 1;
        case 'S'
            scale = scale .* thisNode.scale{pointerS};
            pointerS = pointerS + 1;
    end
end
tMatrix = piTransformCompose(translation, rotation, scale);
tMatrix = reshape(tMatrix,[1,16]);

if arealight
    transformType = 'Transform';
else
    transformType = 'ConcatTransform';
end
fprintf(fid, strcat(spacing, indentSpacing,...
    sprintf('%s [%.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f]',...
    transformType, tMatrix(:)), '\n'));

end


function ObjectWrite(fid, thisNode, rootPath, spacing, indentSpacing)

if ~isempty(thisNode.mediumInterface)
    fprintf(fid, strcat(spacing, indentSpacing, "MediumInterface ", '"', thisNode.mediumInterface, '" ','""', '\n'));
end

% Write out material
for nMat = 1:numel(thisNode.material) % object can contain multiple material and shapes
    if iscell(thisNode.material)
        material = thisNode.material{nMat};
    else
        material = thisNode.material;
    end
    try
        fprintf(fid, strcat(spacing, indentSpacing, "NamedMaterial ", '"',...
            material.namedmaterial, '"', '\n'));
    catch
        % we should never go here
        materialTxt = piMaterialText(material, thisR);
        fprintf(fid, strcat(materialTxt, '\n'));
    end

    % end

    % Deal with possibility of a cell array for the shape
    if ~iscell(thisNode.shape) 
        thisShape = thisNode.shape;
    elseif iscell(thisNode.shape) && numel(thisNode.shape) 
        thisShape = thisNode.shape{1};
    else
        thisShape = thisNode.shape{nMat};
    end

    % If there is a shape, act here.
    if ~isempty(thisShape)

        shapeText = piShape2Text(thisShape);

        if ~isempty(thisShape.filename)
            % If the shape has ply info, do this
            % Convert shape struct to text
            [~, ~, e] = fileparts(thisShape.filename);
            if ~exist(fullfile(rootPath, strrep(thisShape.filename,'.ply','.pbrt')),'file')
                if ~exist(fullfile(rootPath, strrep(thisShape.filename,'.pbrt','.ply')),'file')
                    error('%s not exist',thisShape.filename);
                else
                    thisShape.filename = strrep(thisShape.filename,'.pbrt','.ply');
                    thisShape.meshshape = 'plymesh';
                    shapeText = piShape2Text(thisShape);
                end
            else
                if isequal(e, '.ply')
                    thisShape.filename = strrep(thisShape.filename,'.ply','.pbrt');
                    thisShape.meshshape = 'trianglemesh';
                    shapeText = piShape2Text(thisShape);
                end
            end
            if isequal(e, '.ply')
                fprintf(fid, strcat(spacing, indentSpacing, sprintf('%s\n',shapeText)));
            else
                % In this case it is a .pbrt file, we will write it
                % out.
                fprintf(fid, strcat(spacing, indentSpacing, sprintf('Include "%s"', thisNode.shape.filename)),'\n');
            end
        else
            % If it does not have ply file, do this
            % There is a shape slot we also open the geometry file.
            name = thisNode.name;
            geometryFile = fopen(fullfile(rootPath,'geometry',sprintf('%s.pbrt',name)),'w');
            fprintf(geometryFile,'%s',shapeText);
            fclose(geometryFile);
            fprintf(fid, strcat(spacing, indentSpacing, sprintf('Include "geometry/%s.pbrt"', name)),'\n');
        end
        fprintf(fid,'\n');
    end
end
end
