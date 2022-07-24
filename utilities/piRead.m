function thisR = piRead(fname,varargin)
% Read an parse a PBRT scene file, returning a rendering recipe
%
% Syntax
%    thisR = piRead(fname, varargin)
%
% Description
%  piREAD parses a pbrt scene file and returns the full set of rendering
%  information in the slots of the "x@J8HDaCMm3LxM3Lrecipe" object. The recipe object
%  contains all the information used by PBRT to render the scene.
%
%  We extract blocks with these names from the text prior to WorldBegin
%
%    Camera, Sampler, Film, PixelFilter, SurfaceIntegrator (V2, or
%    Integrator in V3), Renderer, LookAt, Transform, ConcatTransform,
%    Scale
%
%  After creating this recipe object in Matlab, we can modify it
%  programmatically.  We use piWrite with the modified recipe to
%  create an updated version of the PBRT files for rendering. These
%  updated PBRT files are rendered using piRender, which executes the
%  PBRT docker image and return an ISETCam scene or oi format).
%
%  Because we have write, render and show, we also have a single
%  function (piWRS) that performs all three of these functions in a
%  single call.
%
% Required inputs
%   fname - full path to a pbrt scene file.  The geometry, materials
%           and other needed files should be in relative path to the
%           main scene file.
%
% Optional key/value pairs
%
%   'read materials' - When PBRT scene file is exported by cinema4d,
%        the exporterflag is set and we read the materials file.  If
%        you do not want to read that file, set this to false.
%
%   exporter - The exporter determines ... (MORE HERE).  
%              One of 'PARSE','Copy'.  Default is PARSE.
%
% Output
%   recipe - A @recipe object with the parameters needed to write a
%            new pbrt scene file for rendering.  Normally, we write
%            out the new files in (piRootPath)/local/scenename
%
% Assumptions:  
% 
%  piRead assumes that
%
%     * There is a block of text before WorldBegin and no more text after
%     * Comments (indicated by '#' in the first character) and blank lines
%        are ignored.
%     * When a block is encountered, the text lines that follow beginning
%       with a '"' are included in the block.
%
%  piRead will not work with PBRT files that do not meet these criteria.
%
%  Text starting at WorldBegin to the end of the file (not just WorldEnd)
%  is stored in recipe.world.
%
% Authors: TL, ZLy, BW, Zhenyi
%
% See also
%   piWRS, piWrite, piRender, piBlockExtract

% Examples:
%{
 thisR = piRecipeDefault('scene name','MacBethChecker');
 thisR.set('skymap','room.exr');
 % thisR = piRecipeDefault('scene name','SimpleScene');
 % thisR = piRecipeDefault('scene name','teapot');

 piWrite(thisR);
 scene =  piRender(thisR);
 sceneWindow(scene);
%}

%% Parse the inputs

varargin =ieParamFormat(varargin);
p = inputParser;

p.addRequired('fname', @(x)(exist(fname,'file')));
validExporters = {'Copy','PARSE'};
p.addParameter('exporter', 'PARSE', @(x)(ismember(x,validExporters))); 

% We use meters in PBRT, assimp uses centimeter as base unit
% Blender scene has a scale factor equals to 100.
% Not sure whether other type of FBX file has this problem.
% p.addParameter('convertunit',false,@islogical);

p.parse(fname,varargin{:});

thisR = recipe;
thisR.version = 4;
[~, inputname, input_ext] = fileparts(fname);

%% If input is a FBX file, we convert it into PBRT file
if strcmpi(input_ext, '.fbx')
    disp('Converting FBX file into PBRT file...')
    pbrtFile = piFBX2PBRT(fname);

    disp('Formating PBRT file...')
    infile = piPBRTReformat(pbrtFile);
else
    infile = fname;
end

thisR.inputFile = infile;

% Copy?  Or some other method?
exporter = p.Results.exporter;
thisR.exporter = exporter;

%% Set the default output directory
outFilepath      = fullfile(piRootPath,'local',inputname);
outputFile       = fullfile(outFilepath,[inputname,'.pbrt']);
thisR.set('outputFile',outputFile);


%% Split text lines into pre-WorldBegin and WorldBegin sections
[txtLines, ~] = piReadText(thisR.inputFile);
txtLines = strrep(txtLines, '[ "', '"');
txtLines = strrep(txtLines, '" ]', '"');
[options, ~] = piReadWorldText(thisR, txtLines);

%% Read options information
% think about using piParameterGet;
% Extract camera block
thisR.camera = piParseOptions(options, 'Camera');

% Extract sampler block
thisR.sampler = piParseOptions(options,'Sampler');

% Extract film block
thisR.film    = piParseOptions(options,'Film');

% always use 'gbuffer' for multispectral rendering
thisR.film.subtype = 'gbuffer';

% Patch up the filmStruct to match the recipe requirements
if(isfield(thisR.film,'filename'))
    % Remove the filename since it inteferes with the outfile name.
    thisR.film = rmfield(thisR.film,'filename');
end

% Some PBRT files do not specify the film diagonal size.  We set it to
% 1mm here.
try
    thisR.get('film diagonal');
catch
    disp('Setting film diagonal size to 1 mm');
    thisR.set('film diagonal',1);
end

% Extract transform time block
thisR.transformTimes = piParseOptions(options, 'TransformTimes');

% Extract surface pixel filter block
thisR.filter = piParseOptions(options,'PixelFilter');

% Extract (surface) integrator block
thisR.integrator = piParseOptions(options,'Integrator');

% % Extract accelerator
% thisR.accelerator = piParseOptions(options,'Accelerator');

% Set thisR.lookAt and determine if we need to flip the image
flipping = piReadLookAt(thisR,options);

% Sometimes the axis flip is "hidden" in the concatTransform matrix. In
% this case, the flip flag will be true. When the flip flag is true, we
% always output Scale -1 1 1.
if(flipping)
    thisR.scale = [-1 1 1];
end

% Read Scale, if it exists
% Because PBRT is a LHS and many object models are exported with a RHS,
% sometimes we stick in a Scale -1 1 1 to flip the x-axis. If this scaling
% is already in the PBRT file, we want to keep it around.
% fprintf('Reading scale\n');
[~, scaleBlock] = piParseOptions(options,'Scale');
if(isempty(scaleBlock))
    thisR.scale = [];
else
    values = textscan(scaleBlock, '%s %f %f %f');
    thisR.scale = [values{2} values{3} values{4}];
end

%%  Read world information for the Include files
world = thisR.world;
if any(piContains(world, 'Include'))
    % If we have an Include file in the world section, the txt lines in the
    % file is merged into thisR.world.

    % Find all the lines in world that have an 'Include'
    inputDir = thisR.get('inputdir');
    IncludeIdxList = find(piContains(world, 'Include'));

    % For each of those lines ....
    for IncludeIdx = 1:numel(IncludeIdxList)
        % Find the include file
        IncStrSplit = strsplit(world{IncludeIdxList(IncludeIdx)},' ');
        IncFileName = erase(IncStrSplit{2},'"');
        IncFileNamePath = fullfile(inputDir, IncFileName);

        % Read the text from the include file
        [IncLines, ~] = piReadText(IncFileNamePath);

        % Erase the include line.
        thisR.world{IncludeIdxList(IncludeIdx)} = [];

        % Add the text to the world section
        thisR.world = {thisR.world, IncLines};
        thisR.world = cat(1, thisR.world{:});
    end
end

thisR.world = piFormatConvert(thisR.world);

if strcmpi(exporter, 'Copy')
    % what does this mean since we then parse it?
    %disp('Scene will not be parsed. Maybe we can parse in the future');
        % Read material and texture
    [materialLists, textureList, newWorld, matNameList, texNameList] = parseMaterialTexture(thisR);
    thisR.world = newWorld;
    fprintf('Read %d materials and %d textures.\n', materialLists.Count, textureList.Count);

    thisR.materials.list = materialLists;
    thisR.materials.order = matNameList;
    % Call material lib
    thisR.materials.lib = piMateriallib;

    thisR.textures.list = textureList;
    thisR.textures.order = texNameList;

    % Convert texture file format to PNG
    thisR = piTextureFileFormat(thisR);

    thisR.world = newWorld;
else
    % Read material and texture
    [materialLists, textureList, newWorld, matNameList, texNameList] = parseMaterialTexture(thisR);
    thisR.world = newWorld;
    fprintf('Read %d materials and %d textures..\n', materialLists.Count, textureList.Count);

    [trees, newWorld] = parseObjectInstanceText(thisR, thisR.world);
    thisR.world = newWorld;
    thisR.materials.list = materialLists;
    thisR.materials.order = matNameList;
    % Call material lib
    thisR.materials.lib = piMateriallib;

    thisR.textures.list = textureList;
    thisR.textures.order = texNameList;

    % Convert texture file format to PNG
    thisR = piTextureFileFormat(thisR);

    if exist('trees','var') && ~isempty(trees)
        thisR.assets = trees.uniqueNames;
    else
        % needs to add function to read structure like this:
        % transform [...] / Translate/ rotate/ scale/
        % material ... / NamedMaterial
        % shape ...
        disp('*** No AttributeBegin/End pair found. Set recipe.assets to empty');
    end

    %%  Additional information for instanced objects

    % PBRT does not allow instance lights, however in the cases that
    % we would like to instance an object with some lights on it, we will
    % need to save that additional information to it, and then repeatedly
    % write the attributes when the objectInstance is used in attribute
    % pairs. --Zhenyi
    %
    % OK, but this code breaks on the teapot because there are no
    % assets.  So need to check that there are assets. -- BW
    if ~isempty(thisR.assets)
        for ii  = 1:numel(thisR.assets.Node)
            thisNode = thisR.assets.Node{ii};
            if isfield(thisNode, 'isObjectInstance') && isfield(thisNode, 'referenceObject')
                if isempty(thisNode.referenceObject) || thisNode.isObjectInstance == 1
                    continue
                end

                [ParentId, ParentNode] = piAssetFind(thisR, 'name', [thisNode.referenceObject,'_B']);

                if isempty(ParentNode), continue;end

                ParentNode = ParentNode{1};
                ParentNode.extraNode = thisR.get('asset', ii, 'subtree','true');
                ParentNode.camera = thisR.lookAt;
                thisR.assets = thisR.assets.set(ParentId, ParentNode);
            end
        end
    end

end

verbosity = 0;
if verbosity > 0
    disp('***Scene parsed.');
end



end

%% Helper functions

%% Generic text reading, omitting comments and including comments
function [txtLines, header] = piReadText(fname)
% Open, read, close excluding comment lines
fileID = fopen(fname);
% tmp = textscan(fileID,'%s','Delimiter','\n','CommentStyle',{'#'});
tmp = textscan(fileID,'%s','Delimiter','\n');

txtLines = tmp{1};
fclose(fileID);

% Include comments so we can read only the first line, really
fileID = fopen(fname);
tmp = textscan(fileID,'%s','Delimiter','\n');
header = tmp{1};
fclose(fileID);
end

%% Find the text in WorldBegin/End section
function [options, world] = piReadWorldText(thisR,txtLines)
%
% Finds all the text lines from WorldBegin
% It puts the world section into the thisR.world.
% Then it removes the world section from the txtLines
%
% Question: Why doesn't this go to WorldEnd?  We are hoping that nothing is
% important after WorldEnd.  In our experience, we see some files that
% never even have a WorldEnd, just a World Begin.

% The general parser (toply) writes out the PBRT file in a block format with
% indentations.  Zheng's Matlab parser (started with Cinema4D), expects the
% blocks to be in a single line.
%
% This function converts the blocks to a single line.  This function is
% used a few places in piRead().
txtLines = piFormatConvert(txtLines);

worldBeginIndex = 0;
for ii = 1:length(txtLines)
    currLine = txtLines{ii};
    if(piContains(currLine,'WorldBegin'))
        worldBeginIndex = ii;
        break;
    end
end

% fprintf('Through the loop\n');
if(worldBeginIndex == 0)
    warning('Cannot find WorldBegin.');
    worldBeginIndex = ii;
end

% Store the text from WorldBegin to the end here
world = txtLines(worldBeginIndex:end);
thisR.world = world;

% Store the text lines from before WorldBegin here
options = txtLines(1:(worldBeginIndex-1));

end

%% Build the lookAt information
function [flipping,thisR] = piReadLookAt(thisR,txtLines)
% Reads multiple blocks to create the lookAt field and flip variable
%
% The lookAt is built up by reading from, to, up field and transform and
% concatTransform.
%
% Interpreting these variables from the text can be more complicated w.r.t.
% formatting.

% A flag for flipping from a RHS to a LHS.
flipping = 0;

% Get the block
% [~, lookAtBlock] = piBlockExtract(txtLines,'blockName','LookAt');
[~, lookAtBlock] = piParseOptions(txtLines,'LookAt');
if(isempty(lookAtBlock))
    % If it is empty, use the default
    thisR.lookAt = struct('from',[0 0 0],'to',[0 1 0],'up',[0 0 1]);
else
    % We have values
    %     values = textscan(lookAtBlock{1}, '%s %f %f %f %f %f %f %f %f %f');
    values = textscan(lookAtBlock, '%s %f %f %f %f %f %f %f %f %f');
    from = [values{2} values{3} values{4}];
    to = [values{5} values{6} values{7}];
    up = [values{8} values{9} values{10}];
end

% If there's a transform, we transform the LookAt. % to change
[~, transformBlock] = piBlockExtract(txtLines,'blockName','Transform');
if(~isempty(transformBlock))
    values = textscan(transformBlock{1}, '%s [%f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f]');
    values = cell2mat(values(2:end));
    transform = reshape(values,[4 4]);
    [from,to,up,flipping] = piTransform2LookAt(transform);
end

% If there's a concat transform, we use it to update the current camera
% position. % to change
[~, concatTBlock] = piBlockExtract(txtLines,'blockName','ConcatTransform');
if(~isempty(concatTBlock))
    values = textscan(concatTBlock{1}, '%s [%f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f]');
    values = cell2mat(values(2:end));
    concatTransform = reshape(values,[4 4]);

    % Apply transform and update lookAt
    lookAtTransform = piLookat2Transform(from,to,up);
    [from,to,up,flipping] = piTransform2LookAt(lookAtTransform*concatTransform);
end

% Warn the user if nothing was found
if(isempty(transformBlock) && isempty(lookAtBlock))
    warning('Cannot find "LookAt" or "Transform" in PBRT file. Returning default.');
end

thisR.lookAt = struct('from',from,'to',to,'up',up);
thisR.set('film render type',{'radiance'});

end

%% Parse several critical recipe options
function [s, blockLine] = piParseOptions(txtLines, blockName)
% Parse the options for a specific block
%

% How many lines of text?
nline = numel(txtLines);
s = [];ii=1;

while ii<=nline
    blockLine = txtLines{ii};
    % There is enough stuff to make it worth checking
    if length(blockLine) >= 5 % length('Shape')
        % If the blockLine matches the BlockName, do something
        if strncmp(blockLine, blockName, length(blockName))
            s=[];

            % If it is Transform, do this and then return
            if (strcmp(blockName,'Transform') || ...
                    strcmp(blockName,'LookAt')|| ...
                    strcmp(blockName,'ConcatTransform')|| ...
                    strcmp(blockName,'Scale'))
                return;
            end

            % It was not Transform.  So figure it out.
            thisLine = strrep(blockLine,'[','');  % Get rid of [
            thisLine = strrep(thisLine,']','');   % Get rid of ]
            thisLine = textscan(thisLine,'%q');   % Find individual words into a cell array

            % thisLine is a cell of 1.
            % It contains a cell array with the individual words.
            thisLine = thisLine{1};
            nStrings = length(thisLine);
            blockType = thisLine{1};
            blockSubtype = thisLine{2};
            s = struct('type',blockType,'subtype',blockSubtype);
            dd = 3;

            % Build a struct that will be used for representing this type
            % of Option (Camera, Sampler, Integrator, Film, ...)
            % This builds the struct and assigns the values of the
            % parameters
            while dd <= nStrings
                if piContains(thisLine{dd},' ')
                    C = strsplit(thisLine{dd},' ');
                    valueType = C{1};
                    valueName = C{2};
                end

                % Some parameters have multiple values, most just one.
                % inserted this switch to handle the cropwindow case.
                % Maybe others will come up (e.g., spectrum?) (BW)
                switch valueName
                    case 'cropwindow'
                        value = zeros(1,4);
                        for jj=1:4
                            value(jj) = str2double(thisLine{dd+jj});
                        end
                        dd = dd+5;
                    otherwise
                        value = thisLine{dd+1};
                        dd = dd+2;
                end

                % Convert value depending on type
                if(isempty(valueType))
                    continue;
                elseif(strcmp(valueType,'string')) || strcmp(valueType,'spectrum')
                    % Do nothing.
                elseif strcmp(valueType,'bool')
                    if isequal(value, 'true')
                        value = true;
                    elseif isequal(value, 'false')
                        value = false;
                    end
                elseif(strcmp(valueType,'float') || strcmp(valueType,'integer'))
                    % In cropwindow case, above, value is already converted.
                    if ischar(value)
                        value = str2double(value);
                    end
                else
                    error('Did not recognize value type, %s, when parsing PBRT file!',valueType);
                end

                % Assign the type and value to the recipe
                tempStruct = struct('type',valueType,'value',value);
                s.(valueName) = tempStruct;
            end
            break;
        end
    end
    ii = ii+1;
end

if isequal(blockName,'Integrator') && isempty(s)
    % We did not find an integrator.  So we return a default.
    s.type = 'Integrator';
    s.subtype = 'path';
    s.maxdepth.type = 'integer';
    s.maxdepth.value= 5;
    fprintf('Setting integrator to "path" with 5 bounces.\n')
end

end

%% END
