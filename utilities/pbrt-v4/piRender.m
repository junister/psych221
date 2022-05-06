function [ieObject, result, thisD] = piRender(thisR,varargin)
% Read a PBRT scene file, run the docker command, return the ieObject.
%
% Synopsis
%   [ieObject, result, thisD] = piRender(thisR,varargin)
%
% Syntax:
%  [oi or scene or metadata] = piRender(thisR,varargin)
%
% Input
%  thisR - A recipe, whose outputFile specifies the file, OR a string that
%          is a full path to a scene pbrt file.
%
% OPTIONAL key/val pairs
%
%  rendertype - Any combination of these strings
%        {'radiance', 'radiancebasis', 'depth', 'material', 'instance', 'illuminance'}
%
%  oi/scene params - You can use parameters from oiSet or sceneSet that
%            will be applied to the rendered ieObject prior to return.
%
%  mean luminance -  If a scene, this mean luminance. If set to a negative
%            value values returned by the renderer are used.
%            (default 100 cd/m2)
%
%  mean illuminance per mm2 - default is 5 lux
%
%  scalePupilArea
%             - if true, scale the mean illuminance by the pupil
%               diameter in piDat2ISET (default is true)
%
%  reuse      - Boolean. Indicate whether to use an existing file if one of
%               the correct size exists (default is false)
%
%  ourdocker  - Specify the docker wrapper to use.  Default is build
%               from scratch with defaults in the Matlab getprefs('docker')
%
%  reflectancerender -  NYI
%
%  verbose    - Level of desired output:
%               0 Silent
%               1 Minimal
%               2 Legacy -- for compatibility
%               3 Verbose -- includes pbrt output, at least on Windows
%
% wave      -
%
% Returns
%   ieObject - an ISET scene, oi, or a metadata image
%   result   - PBRT output from the terminal. The result is very
%              useful for debugging because it contains Warnings and Errors.
%              The text also contains parameters about the
%              optics, including the distance from the back of
%              the lens to film and the in-focus distance given the 
%              lens-film distance.
%   thisD    - the dockerWrapper used for the rendering.
%
% See also
%   s_piReadRender*.m, piRenderResult, dockerWrapper
%
% TODO: 
%   The parameters are not yet all correctly handled, including
% meanluminance and scalepupilarea.  These are important for ISETBio.
%

% Examples
%{
% These are examples of how to set the dockerWrapper parameters
%
% ourDocker = dockerWrapper('gpuRendering', true, ...
%     'renderContext', 'remote-render','remoteImage', ...
%     'digitalprodev/pbrt-v4-gpu-ampere-bg', 'remoteRoot','/home/david81/', ...
%     'remoteMachine', 'beluga.psych.upenn.edu', ...
%     'remoteUser', 'david81', 'localRoot', '/mnt/c', 'whichGPU', 1);
%
% to run it using the CPU container
%
% ourDocker = dockerWrapper('gpuRendering', false);
%}
%{
   % Renders both radiance and depth by default.
   pbrtFile = fullfile(piRootPath,'data','V4','teapot','teapot-area-light-v4.pbrt');
   scene = piRender(pbrtFile);
   sceneWindow(scene); sceneSet(scene,'gamma',0.5);
%}
%{
   % Render radiance and depth separately
   % Currently this means running the render twice, which isn't very
   % efficient
   pbrtFile = fullfile(piRootPath,'data','V4','teapot','teapot-area-light-v4.pbrt');
   scene = piRender(pbrtFile,'render type','radiance');
   ieAddObject(scene); sceneWindow; sceneSet(scene,'gamma',0.5);

   dmap = piRender(pbrtFile,'render type','depth');
   scene = sceneSet(scene,'depth map',dmap);
   sceneWindow(scene); sceneSet(scene,'gamma',0.5);
%}
%{
  % Separately calculate the illuminant and the radiance-
  % We are not sure this works or is right!
  thisR = piRecipeDefault; 
  piWrite(thisR);
  [scene, result]      = piRender(thisR,'render type','radiance');
  [illPhotons, result] = piRender(thisR,'render type','illuminance');
  scene = sceneSet(scene,'illuminant photons',illPhotons);
  sceneWindow(scene);
%}
%{
  % Calculate the (x,y,z) coordinates of every surface point in the
  % scene.  If there is no surface a zero is returned.  This should
  % probably either a Inf or a NaN when there is no surface.  We might
  % replace those with a black color or something.
  thisR = piRecipeDefault('scene name', 'ChessSet'); piWrite(thisR);
  [coords, result] = piRender(thisR, 'render type','coordinates');
  ieNewGraphWin; imagesc(coords(:,:,1));
  ieNewGraphWin; imagesc(coords(:,:,2));
  ieNewGraphWin; imagesc(coords(:,:,3));
%}
%{
% get materials
  thisR = piRecipeDefault('scene name', 'ChessSet'); piWrite(thisR);
  [aScene, metadata] = piRender(thisR, 'render type','material');
%}
%{
% Render locally with your CPU machine
  thisR = piRecipeDefault('scene name', 'ChessSet'); piWrite(thisR);
  scene = piRender(thisR,'local',true,'our docker','digitalprodev/pbrt-v4-cpu');
  
  dockerWrapper.setParams('local',true);
  dockerWrapper.setParams('local image','digitalprodev/pbrt-v4-cpu');
  scene = piRender(thisR);
%}

%%  Name of the pbrt scene file and whether we use a pinhole or lens model

p = inputParser;
p.KeepUnmatched = true;

% p.addRequired('pbrtFile',@(x)(exist(x,'file')));
p.addRequired('recipe',@(x)(isequal(class(x),'recipe') || ischar(x)));

varargin = ieParamFormat(varargin);
p.addParameter('meanluminance',0,@isnumeric);
p.addParameter('meanilluminancepermm2',[],@isnumeric);
p.addParameter('scalepupilarea',true,@islogical);
p.addParameter('reuse',false,@islogical);
% p.addParameter('reflectancerender', false, @islogical);
p.addParameter('ourdocker','',@(x)(isa(x,'dockerWrapper')) || isempty(x));    % to specify a docker image

% This passed to piDat2ISET, which is where we do the construction.
p.addParameter('wave', 400:10:700, @isnumeric); 

p.addParameter('verbose', getpref('docker','verbosity',1), @isnumeric);
p.addParameter('rendertype', []); % if none we use what is in the recipe

% If you would to render on your local machine, set this to true.  And
% make sure that 'ourdocker' is set to the container you want to run.
p.addParameter('localrender',false,@islogical);

p.parse(thisR,varargin{:});
ourDocker        = p.Results.ourdocker;
scalePupilArea   = p.Results.scalepupilarea;  % Fix this
meanLuminance    = p.Results.meanluminance;   % And this
wave             = p.Results.wave;
renderType       = p.Results.rendertype;

%% Set up the dockerWrapper
persistent renderDocker;

% If the user has sent in a dockerWrapper (ourDocker) we use it
if ~isempty(ourDocker),   renderDocker = ourDocker;
else,                     renderDocker = dockerWrapper;
end

if renderDocker.localRender
    % It is local so use this local rendering
    renderDocker.relativeScenePath = fileparts(thisR.get('output dir'));
    renderDocker.remoteMachine = '';

    % If the local docker is a GPU type, OK.  Otherwise, set gpuRendering
    % false.
    str = renderDocker.localImage;
    if contains(str,'gpu'), renderDocker.gpuRendering = true;
    else, renderDocker.gpuRendering = false;
    end

end

%% We have a radiance recipe and we have written the pbrt radiance file

% Set up the output folder.  This folder will be mounted by the Docker
% image if run locally.  When run remotely, we are using rsynch and
% different mount points.
outputFolder = fileparts(thisR.outputFile);
if(~exist(outputFolder,'dir'))
    error('We need an absolute path for the working folder.');
end
pbrtFile = thisR.outputFile;

%% Call the Docker for rendering

% This should all go through the dockerWrapper class
% That requires dealing with:
%  -- container has a base dir of local, not the scene folder
%  -- any support for making sure various directories exist have to deal
%  with that
%  -- When pbrt is launched it needs to know how to navigate to the
%  approprite scene
%

%% Build the docker command
dockerCommand   = 'docker run -ti --rm';

[~,currName,~] = fileparts(pbrtFile);

% Make sure renderings folder exists and is fresh
if(isfolder(fullfile(outputFolder,'renderings')))
    delete(fullfile(outputFolder, 'renderings', '*'));
else
    mkdir(fullfile(outputFolder,'renderings'));
end

outFile = fullfile(outputFolder,'renderings',[currName,'.exr']);

if ispc  % Windows
    currFile = pbrtFile; % in v3 we could process several files, not sure about v4

    % Hack to reverse \ to / for _depth files, for compatibility
    % with Linux-based Docker pbrt container
    pFile = fopen(currFile,'rt');
    tFileName = tempname;
    tFile = fopen(tFileName,'wt');
    while true
        thisline = fgets(pFile);
        if ~ischar(thisline); break; end  %end of file
        if contains(thisline, "C:\") || contains(thisline, "B:\")
            thisline = strrep(thisline, piRootPath, '');
            thisline = strrep(thisline, '\local', '');
            thisline = strrep(thisline, '\', '/');
        end
        fprintf(tFile,  '%s', thisline);
    end
    fclose(pFile);
    fclose(tFile);
    copyfile(tFileName, currFile);
    delete(tFileName);

    % With V4 the output is EXR not Dat
    outF = strcat('renderings/',currName,'.exr');
    renderCommand = sprintf('pbrt --outfile %s %s', outF, strcat(currName, '.pbrt'));
        
    if ~isempty(outputFolder)
        if ~exist(outputFolder,'dir'), error('Need full path to %s\n',outputFolder); end
    end

else  % Linux & Mac

    % With V4 the output is EXR not Dat
    outF = strcat('renderings/',currName,'.exr');
    renderCommand = sprintf('pbrt --outfile %s %s', outF, strcat(currName, '.pbrt'));

    if ~isempty(outputFolder)
        if ~exist(outputFolder,'dir'), error('Need full path to %s\n',outputFolder); end
    end
end

% renderDocker is a dockerWrapper and its parameters.  The parameters
% control on which machine and with what parameters the docker
% container is invoked.  I am not sure why it is a persistent
% variable (BW).
preRender = tic;
[status, result] = renderDocker.render(renderCommand, outputFolder);

% Append the renderCommand and output file
sprintf('%s\nOutput file:  %s\n',result,outF);

elapsedTime = toc(preRender);
if getpref('docker','verbosity',0) > 0
    fprintf("Complete render took: %6.2d seconds.", elapsedTime);
end

% The user wants the dockerWrapper.
if nargout > 2, thisD = renderDocker; end

%% Check the returned rendering image.

if status
    warning('Docker did not run correctly');
    % The status may contain a useful error message that we should
    % look up.  The ones we understand should offer help here.
    fprintf('Status:\n'); disp(status);
    fprintf('Result:\n'); disp(result);
end

fprintf('*** Rendering time for %s:  %.1f sec ***\n\n',currName,elapsedTime);

% not sure what we should return with 'all' but this is a start
% as I'm not sure coordinates is working
if isequal(renderType,'all')
    renderType = {'radiance','depth'};
end

%% Convert the returned data to an ieObject
if ~isempty(renderType)
    ieObject = piEXR2ISET(outFile, 'recipe',thisR,'label',renderType);
elseif isempty(thisR.metadata)
    ieObject = piEXR2ISET(outFile, 'recipe',thisR,'label',{'radiance','depth'});
else
    ieObject = piEXR2ISET(outFile, 'recipe',thisR,'label',thisR.metadata.rendertype);
end

% Why are we updating the wave?  Is that ever needed?
if isstruct(ieObject)
    % It might be helpful to preserve the recipe used
    ieObject.recipeUsed = thisR;
    
    switch ieObject.type
        case 'scene'
            % names = strsplit(fileparts(thisR.inputFile),'/');
            % ieObject = sceneSet(ieObject,'name',names{end});
            curWave = sceneGet(ieObject,'wave');
            if ~isequal(curWave(:),wave(:))
                ieObject = sceneSet(ieObject, 'wave', wave);
            end

        case 'opticalimage'
            % names = strsplit(fileparts(thisR.inputFile),'/');
            % ieObject = oiSet(ieObject,'name',names{end});
            curWave = oiGet(ieObject,'wave');
            if ~isequal(curWave(:),wave(:))
                ieObject = oiSet(ieObject,'wave',wave);
            end

        otherwise
            error('Unknown struct type %s\n',ieObject.type);
    end
end


