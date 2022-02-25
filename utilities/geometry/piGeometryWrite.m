function  piGeometryWrite(thisR,varargin)
% Write out a geometry file that matches the format and labeling objects
%
% Synopsis
%   piGeometryWrite(thisR,varargin)
%
% Input:
%       thisR: a render recipe
%       obj:   Returned by piGeometryRead, contains information about objects.
%
% Optional key/value pairs
%
% Output:
%       None for now.
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

% varargin =ieParamFormat(varargin);

p.addRequired('thisR',@(x)isequal(class(x),'recipe'));
% default is flase, will turn on for night scene
% p.addParameter('lightsFlag',false,@islogical);
% p.addParameter('thistrafficflow',[]);

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

    % Write the tree structure in the main geometry file
    lvl = 0;
    recursiveWriteAttributes(fid_obj, obj, rootID, lvl, thisR.outputFile);
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
    
    % Define object node
    elseif isequal(thisNode.type, 'object')
        % strip the ID number to get a more general node name
        while numel(thisNode.name) >= 8 &&...
                isequal(thisNode.name(5:6), 'ID')
            thisNode.name = thisNode.name(8:end);
        end

        % tell pbrt we are starting an object definition
        fprintf(fid, 'ObjectBegin "%s"\n', thisNode.name);

        % Write out mediumInterface
        if ~isempty(thisNode.mediumInterface)
            fprintf(fid, strcat("MediumInterface ", '"', thisNode.mediumInterface, '" ','""', '\n'));
        end

        % Write out materials used in the object
        if ~isempty(thisNode.material)
            %{
            % From dev branch
            if strcmp(thisNode.material,'none')
                fprintf(fid, strcat("Material ", '"none"', '\n'));
            else
                fprintf(fid, strcat("NamedMaterial ", '"',...
                            thisNode.material.namedmaterial, '"', '\n'));
            %}
            try
                fprintf(fid, strcat("NamedMaterial ", '"',...
                    thisNode.material.namedmaterial, '"', '\n'));
            catch
                materialTxt = piMaterialText(thisNode.material);
                fprintf(fid, strcat(materialTxt, '\n'));
            end
        end
        %{
            % I don't know what's this used for, but commenting here.
            if ~isempty(thisNode.output)
                % There is an output slot
                [~,output] = fileparts(thisNode.output);
                fprintf(fid, 'Include "scene/PBRT/pbrt-geometry/%s.pbrt" \n', output);
        %}

        % Object geometry is in the shape slot
        % We write it out here
        if ~isempty(thisNode.shape)

            shapeText = piShape2Text(thisNode.shape);

            if isfield(thisNode.shape,'filename') && ~isempty(thisNode.shape.filename)
                % If the shape has ply info, do this
                % Convert shape struct to text
                [~, ~, e] = fileparts(thisNode.shape.filename);
                if ~exist(fullfile(rootPath, strrep(thisNode.shape.filename,'.ply','.pbrt')),'file')
                    if ~exist(fullfile(rootPath, strrep(thisNode.shape.filename,'.pbrt','.ply')),'file')
                        error('%s not exist',thisNode.shape.filename);
                    else
                        thisNode.shape.filename = strrep(thisNode.shape.filename,'.pbrt','.ply');
                        thisNode.shape.meshshape = 'plymesh';
                        shapeText = piShape2Text(thisNode.shape);
                    end
                else
                    if isequal(e, '.ply')
                        thisNode.shape.filename = strrep(thisNode.shape.filename,'.ply','.pbrt');
                        thisNode.shape.meshshape = 'trianglemesh';
                        shapeText = piShape2Text(thisNode.shape);
                    end
                end
                if isequal(e, '.ply')
                    fprintf(fid, '%s \n',shapeText);
                else
                    % In this case it is a .pbrt file, we will write it
                    % out.
                    fprintf(fid, 'Include "%s" \n', thisNode.shape.filename);
                end
            else
                % If it does not have plt file, do this
                % There is a shape slot we also open the
                % geometry file.
                name = thisNode.name;
                geometryFile = fopen(fullfile(rootPath,'geometry',sprintf('%s.pbrt',name)),'w');
                fprintf(geometryFile,'%s',shapeText);
                fclose(geometryFile);
                % Note, assume Linux-style path names for renderer
                fprintf(fid, 'Include "geometry/%s.pbrt" \n', name);
            end
        end

        fprintf(fid, 'ObjectEnd\n\n');

    % NOTE: We now process lights separately?    
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

function recursiveWriteAttributes(fid, obj, thisNode, lvl, outFilePath)
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


for ii = 1:numel(children)
    thisNode = obj.get(children(ii));
    fprintf(fid, strcat(spacing, 'AttributeBegin\n'));

    if isequal(thisNode.type, 'branch')
        % get the name after stripping ID for this Node
        while numel(thisNode.name) >= 8 &&...
                isequal(thisNode.name(5:6), 'ID')
            thisNode.name = thisNode.name(8:end);
        end
        % Write the object's dimensions
        fprintf(fid, strcat(spacing, indentSpacing,...
            sprintf('#ObjectName %s:Dimension:[%.4f %.4f %.4f)',thisNode.name,...
            thisNode.size.l,...
            thisNode.size.w,...
            thisNode.size.h), '\n'));
        
        % If a motion exists in the current object, prepare to write it out by
        % having an additional line below.
        if ~isempty(thisNode.motion)
            fprintf(fid, strcat(spacing, indentSpacing,...
                'ActiveTransform StartTime \n'));
        end

        % Transformation section
        if ~isempty(thisNode.rotation)
            % Zheng: I think it is always this case, but maybe it is rarely
            % the case below. Have no clue.
            % If this way, we would write the translation, rotation and
            % scale line by line based on the order of thisNode.transorder
            piGeometryTransformWrite(fid, thisNode, spacing, indentSpacing);
        else
            thisNode.concattransform(13:15) = thisNode.translation(:);
            fprintf(fid, strcat(spacing, indentSpacing,...
                sprintf('ConcatTransform [%.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f]', thisNode.concattransform(:)), '\n'));
            % Scale
            fprintf(fid, strcat(spacing, indentSpacing,...
                sprintf('Scale %.10f %.10f %.10f', thisNode.scale), '\n'));
        end

        %{
        % This is the old transformation section
        % Rotation
        if ~isempty(thisNode.rotation)
            fprintf(fid, strcat(spacing, indentSpacing,...
                sprintf('Translate %.5f %.5f %.5f', thisNode.translation(1),...
                thisNode.translation(2),...
                thisNode.translation(3)), '\n'));
            fprintf(fid, strcat(spacing, indentSpacing,...
                sprintf('Rotate %.5f %.5f %.5f %.5f', thisNode.rotation(:, 1)), '\n'));
            fprintf(fid, strcat(spacing, indentSpacing,...
                sprintf('Rotate %.5f %.5f %.5f %.5f', thisNode.rotation(:, 2)), '\n'));
            fprintf(fid, strcat(spacing, indentSpacing,...
                sprintf('Rotate %.5f %.5f %.5f %.5f', thisNode.rotation(:, 3)), '\n'));
        else
            thisNode.concattransform(13:15) = thisNode.translation(:);
            fprintf(fid, strcat(spacing, indentSpacing,...
                sprintf('ConcatTransform [%.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f]', thisNode.concattransform(:)), '\n'));
        end
        % Scale
        fprintf(fid, strcat(spacing, indentSpacing,...
            sprintf('Scale %.10f %.10f %.10f', thisNode.scale), '\n'));
        %}

        % Write out motion
        %
        if ~isempty(thisNode.motion)
            fprintf(fid, strcat(spacing, indentSpacing,...
                'ActiveTransform EndTime \n'));
            for jj = 1:size(thisNode.motion, 1)

                % First write out the same translation and rotation
                piGeometryTransformWrite(fid, thisNode, spacing, indentSpacing);

                % Now write the end position
                if isfield(thisNode.motion(jj), 'translation')
                    pos = thisNode.motion(jj).translation;
                    fprintf(fid, strcat(spacing, indentSpacing,...
                        sprintf('Translate %f %f %f', pos(1),...
                        pos(2),...
                        pos(3)), '\n'));
                    
                end

                if isfield(thisNode.motion(jj), 'rotation')
                    rot = thisNode.motion(jj).rotation;
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

        recursiveWriteAttributes(fid, obj, children(ii), lvl + 1, outFilePath);

    elseif isequal(thisNode.type, 'object') || isequal(thisNode.type, 'instance')
        while numel(thisNode.name) >= 8 &&...
                isequal(thisNode.name(5:6), 'ID')
            % remove instance suffix
            endIndex = strfind(thisNode.name, '_I_');
            if ~isempty(endIndex)
                endIndex =endIndex-1;
            else
                endIndex = numel(thisNode.name);
            end
            thisNode.name = thisNode.name(8:endIndex);
        end
        fprintf(fid, strcat(spacing, indentSpacing, ...
            sprintf('ObjectInstance "%s"', thisNode.name), '\n'));

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


% Geometry file writing helper
function piGeometryTransformWrite(fid, thisNode, spacing, indentSpacing)
    pointerT = 1; pointerR = 1; pointerS = 1;
    for tt = 1:numel(thisNode.transorder)
        switch thisNode.transorder(tt)
            case 'T'
                fprintf(fid, strcat(spacing, indentSpacing,...
                    sprintf('Translate %.5f %.5f %.5f', thisNode.translation{pointerT}(1),...
                    thisNode.translation{pointerT}(2),...
                    thisNode.translation{pointerT}(3)), '\n'));
                pointerT = pointerT + 1;
            case 'R'
                fprintf(fid, strcat(spacing, indentSpacing,...
                    sprintf('Rotate %.5f %.5f %.5f %.5f', thisNode.rotation{pointerR}(:, 1)), '\n'));
                fprintf(fid, strcat(spacing, indentSpacing,...
                    sprintf('Rotate %.5f %.5f %.5f %.5f', thisNode.rotation{pointerR}(:, 2)), '\n'));
                fprintf(fid, strcat(spacing, indentSpacing,...
                    sprintf('Rotate %.5f %.5f %.5f %.5f', thisNode.rotation{pointerR}(:, 3)), '\n'));
                pointerR = pointerR + 1;
            case 'S'
                fprintf(fid, strcat(spacing, indentSpacing,...
                    sprintf('Scale %.10f %.10f %.10f', thisNode.scale{pointerS}), '\n'));
                pointerS = pointerS + 1;
        end
    end
end
