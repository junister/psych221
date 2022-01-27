function [ieObject, result] = piRender(thisR,varargin)
% Read a PBRT scene file, run the docker command, return the ieObject.
%
% updated version using dockerWrapper for render -- D. Cardinal

% Syntax:
%  [oi or scene or metadata] = piRender(thisR,varargin)
%
% REQUIRED input
%  thisR - A recipe, whose outputFile specifies the file, OR a string that
%          is a full path to a scene pbrt file.
%
% OPTIONAL input parameter/val
%  oi/scene   - You can use parameters from oiSet or sceneSet that
%               will be applied to the rendered ieObject prior to return.
%
%  mean luminance -  If a scene, this mean luminance. If set to a negative
%                    value values returned by the renderer are used.
%                    (default 100 cd/m2)
%  mean illuminance per mm2 - default is 5 lux
%  scalePupilArea
%             - if true, scale the mean illuminance by the pupil
%               diameter in piDat2ISET (default is true)
%  reuse      - Boolean. Indicate whether to use an existing file if one of
%               the correct size exists (default is false)
%
%  verbose    - Level of desired output:
%               0 Silent
%               1 Minimal
%               2 Legacy -- for compatibility
%               3 Verbose -- includes pbrt output, at least on Windows
%
% RETURN
%   ieObject - an ISET scene, oi, or a metadata image
%   result   - PBRT output from the terminal.  This can be vital for
%              debugging! The result contains useful parameters about
%              the optics, too, including the distance from the back
%              of the lens to film and the in-focus distance given the
%              lens-film distance.
%
% Zhenyi, 2021
%
% See also
%   s_piReadRender*.m, piRenderResult

% Examples
%{
   % Renders both radiance and depth
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
  % Separately calculate the illuminant and the radiance
  thisR = piRecipeDefault; piWrite(thisR);
  [scene, result]      = piRender(thisR);
  [illPhotons, result] = piRender(thisR);
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
p.addParameter('reflectancerender', false, @islogical);
p.addParameter('ourdocker',''); % to specify a specific docker container
p.addParameter('wave', 400:10:700, @isnumeric); % This is the past to piDat2ISET, which is where we do the construction.
p.addParameter('verbose', getpref('docker','verbosity',1), @isnumeric);
p.addParameter('rendertype', []); % if none we use what is in the recipe

p.parse(thisR,varargin{:});
ourDocker = p.Results.ourdocker;
scalePupilArea = p.Results.scalepupilarea;
meanLuminance    = p.Results.meanluminance;
wave             = p.Results.wave;
verbosity        = p.Results.verbose;
renderType       = p.Results.rendertype;

%% try to support docker servers
persistent renderDocker;

% try and set the default to a server if we aren't passed one:
if isempty(ourDocker)
    renderPrefs = getpref('docker','renderString', {'gpuRendering', false});
    ourDocker = dockerWrapper(renderPrefs{:});
end

% Extensive Example:
% renderString = {'gpuRendering', true, 'remoteMachine', <machine name>,'renderContext', <docker context>,'remoteImage', 'digitalprodev/pbrt-v4-gpu-ampere-mux', 'remoteRoot',<homedir>, 'remoteUser', uName, 'localRoot', <for WSL>, 'whichGPU', <#>};
% setpref('docker', 'renderString', renderString);

% or you can create one directly:
% ourDocker = dockerWrapper('gpuRendering', true, 'renderContext', 'remote-render','remoteImage', ...
%    'digitalprodev/pbrt-v4-gpu-ampere-bg', 'remoteRoot','/home/david81/', ...
%     'remoteMachine', 'beluga.psych.upenn.edu', ...
%     'remoteUser', 'david81', 'localRoot', '/mnt/c', 'whichGPU', 1);

% to run it using a typical local container
%ourDocker = dockerWrapper('gpuRendering', false);

if ~isempty(ourDocker)
    renderDocker = ourDocker; % use the one we are passed
elseif isempty(renderDocker)
    renderDocker = dockerWrapper(); % accept defaults
end

%% We have a radiance recipe and we have written the pbrt radiance file

% Set up the output folder.  This folder will be mounted by the Docker
% image if run locally.  When run remotely, we are using rsynch and different mount points.
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

    % With V4 we need EXR not Dat
    outF = strcat('renderings/',currName,'.exr');
    renderCommand = sprintf('pbrt --outfile %s %s', outF, strcat(currName, '.pbrt'));
    folderBreak = split(outputFolder, filesep());
    shortOut = strcat('/', char(folderBreak(end)));
    
    if ~isempty(outputFolder)
        if ~exist(outputFolder,'dir'), error('Need full path to %s\n',outputFolder); end
        dockerCommand = sprintf('%s -w %s', dockerCommand, shortOut);
    end

    %fix for non - C drives
    %linuxOut = strcat('/c', strrep(erase(outputFolder, 'C:'), '\', '/'));
    linuxOut = char(join(folderBreak,"/"));

    % legacy
    %dockerCommand = sprintf('%s -v %s:%s', dockerCommand, linuxOut, shortOut);
    %cmd = sprintf('%s %s %s', dockerCommand, dockerImageName, renderCommand);
else  % Linux & Mac

    % With V4 we need EXR not Dat
    outF = strcat('renderings/',currName,'.exr');
    renderCommand = sprintf('pbrt --outfile %s %s', outF, strcat(currName, '.pbrt'));
    folderBreak = split(outputFolder, filesep());
    shortOut = strcat('/', char(folderBreak(end)));

    if ~isempty(outputFolder)
        if ~exist(outputFolder,'dir'), error('Need full path to %s\n',outputFolder); end
        % Legacy
        %dockerCommand = sprintf('%s --workdir="%s"', dockerCommand, outputFolder);
    end
end

preRender = tic;

[status, result] = renderDocker.render(renderCommand, outputFolder);
elapsedTime = toc(preRender);
fprintf("Complete render took: %6.2d seconds.", elapsedTime);


%% Check the return

if status
    warning('Docker did not run correctly');
    % The status may contain a useful error message that we should
    % look up.  The ones we understand should offer help here.
    fprintf('Status:\n'); disp(status)
    fprintf('Result:\n'); disp(result)
    pause;
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





