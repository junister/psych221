function [ieObject, result] = piRender(thisR,varargin)
% Read a PBRT scene file, run the docker cmd locally, return the ieObject.
%
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
   pbrtFile = fullfile(piRootPath,'data','V3','teapot','teapot-area-light.pbrt');
   scene = piRender(pbrtFile);
   sceneWindow(scene); sceneSet(scene,'gamma',0.5);
%}
%{
   % Render radiance and depth separately
   pbrtFile = fullfile(piRootPath,'data','V3','teapot','teapot-area-light.pbrt');
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
  thisR = piRecipeDefault; piWrite(thisR);
  [coords, result] = piRender(thisR, 'render type','coordinates');
  ieNewGraphWin; imagesc(coords(:,:,1));
  ieNewGraphWin; imagesc(coords(:,:,2));
  ieNewGraphWin; imagesc(coords(:,:,3));
%}

%%  Name of the pbrt scene file and whether we use a pinhole or lens model

p = inputParser;
p.KeepUnmatched = true;

% p.addRequired('pbrtFile',@(x)(exist(x,'file')));
p.addRequired('recipe',@(x)(isequal(class(x),'recipe') || ischar(x)));

varargin = ieParamFormat(varargin);
p.addParameter('meanluminance',100,@isnumeric);
p.addParameter('meanilluminancepermm2',[],@isnumeric);
p.addParameter('scalepupilarea',true,@islogical);
p.addParameter('reuse',false,@islogical);
p.addParameter('reflectancerender', false, @islogical);
p.addParameter('dockerimagename','camerasimulation/pbrt-v4-cpu',@ischar);
p.addParameter('wave', 400:10:700, @isnumeric); % This is the past to piDat2ISET, which is where we do the construction.
p.addParameter('verbose', 2, @isnumeric);

p.parse(thisR,varargin{:});
dockerImageName  = p.Results.dockerimagename;
scalePupilArea = p.Results.scalepupilarea;
meanLuminance    = p.Results.meanluminance;
wave             = p.Results.wave;
verbosity        = p.Results.verbose;

%% We have a radiance recipe and we have written the pbrt radiance file

% Set up the output folder.  This folder will be mounted by the Docker
% image
outputFolder = fileparts(thisR.outputFile);
if(~exist(outputFolder,'dir'))
    error('We need an absolute path for the working folder.');
end
pbrtFile = thisR.outputFile;

%% Call the Docker for rendering

%% Build the docker command
dockerCommand   = 'docker run -ti --rm';

[~,currName,~] = fileparts(pbrtFile);

% Make sure renderings folder exists
if(~exist(fullfile(outputFolder,'renderings'),'dir'))
    mkdir(fullfile(outputFolder,'renderings'));
end

outFile = fullfile(outputFolder,'renderings',[currName,'.exr']);

% Experiment with calling a native version of pbrt on Windows
% As of March, 2021 doesn't seem to make a difference on my test
% machines, but it does work as long as you use the spectral version
% of pbrt. So I've set the default to false.
native_pbrt =   false;
if ispc  % Windows
    currFile = pbrtFile; % in v3 we could process several files, not sure about v4
    if native_pbrt
        % For now spectral pbrt changes data on write by 0a->0d0a
        % so for this case we do a dos2unix conversion later
        % Filepath to pbrt.exe goes here
        pbrtBinary = 'pbrt.exe';
        outF = fullfile(outputFolder, strcat('renderings/',currName,'.exr')); % for v4 assume exr
        % Hack, for testing.
        renderCommand = sprintf('%s --outfile %s %s', pbrtBinary, outF, currFile);
        command = renderCommand;
    else
        
        % Hack to reverse \ to / for _depth files, for compatibility
        % with Linux-based Docker pbrt container
        pFile = fopen(currFile,'rt');
        tFileName = tempname;
        tFile = fopen(tFileName,'wt');
        while true
            thisline = fgets(pFile);
            if ~ischar(thisline); break; end  %end of file
            if contains(thisline, "C:\")
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
        
        dockerCommand = sprintf('%s -v %s:%s', dockerCommand, linuxOut, shortOut);
        
        cmd = sprintf('%s %s %s', dockerCommand, dockerImageName, renderCommand);
    end
else  % Linux & Mac
    renderCommand = sprintf('pbrt --outfile %s %s', outFile, pbrtFile);
    if ~isempty(outputFolder)
        if ~exist(outputFolder,'dir'), error('Need full path to %s\n',outputFolder); end
        dockerCommand = sprintf('%s --workdir="%s"', dockerCommand, outputFolder);
    end
    
    dockerCommand = sprintf('%s --volume="%s":"%s"', dockerCommand, outputFolder, outputFolder);
    % Check whether GPU is available
    [GPUCheck, GPUModel] = system('nvidia-smi --query-gpu=name --format=csv,noheader');
    try
        ourGPU = gpuDevice();
        if ourGPU.ComputeCapability < 5.3 % minimum for PBRT on GPU
            GPUCheck = -1;
        end
    catch
        % GPU acceleration with Parallel Computing Toolbox is not supported on macOS.
    end

    if ~GPUCheck

        % GPU is available
        cudalib = ['-v /usr/lib/x86_64-linux-gnu/libnvoptix.so.1:/usr/lib/x86_64-linux-gnu/libnvoptix.so.1 ',...
            '-v /usr/lib/x86_64-linux-gnu/libnvoptix.so.470.57.02:/usr/lib/x86_64-linux-gnu/libnvoptix.so.470.57.02 ',...
            '-v /usr/lib/x86_64-linux-gnu/libnvidia-rtcore.so.470.57.02:/usr/lib/x86_64-linux-gnu/libnvidia-rtcore.so.470.57.02'];
        renderCommand = sprintf('pbrt --gpu --outfile %s %s', outFile, pbrtFile);
        % update docker command to use gpu
        dockerCommand  = strrep(dockerCommand,'-ti --rm','--gpus 1 -it --rm');
        switch ieParamFormat(strtrim(GPUModel))
            case 'teslat4'
                dockerImageName = 'camerasimulation/pbrt-v4-gpu-t4';
            case {'geforcertx3070', 'geforcertx3090'}
                dockerImageName = 'camerasimulation/pbrt-v4-gpu';
            otherwise
                warning('No compatible docker image for GPU model: %s, might not be able to run docker.', GPUModel);
                dockerImageName = 'camerasimulation/pbrt-v4-gpu';
        end
        
        cmd = sprintf('%s %s %s %s', dockerCommand, cudalib, dockerImageName, renderCommand);   
    else
        renderCommand = sprintf('pbrt --outfile %s %s', outFile, pbrtFile);
        cmd = sprintf('%s %s %s', dockerCommand, dockerImageName, renderCommand);
    end
end


%% Determine if prefer to use existing files, and if they exist.
tic;
if native_pbrt
    if verbosity > 2
        [status, result] = system(command,'-echo');
        [status, result] = system(command); % don't display pbrt output
    end
    if ~status
        unix2dos(outFile, true);
    end
else
    [status, result] = piRunCommand(cmd, 'verbose', verbosity);
end
elapsedTime = toc;
% disp(result)
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

%% Convert the returned data to an ieObject
if isempty(thisR.metadata)
    ieObject = piEXR2ISET(outFile, 'recipe',thisR,'label',{'radiance'});
else
    ieObject = piEXR2ISET(outFile, 'recipe',thisR,'label',thisR.metadata.rendertype);
end
%% We used to name here, but apparently not needed any more

% Why are we updating the wave?  Is that ever needed?
if isstruct(ieObject)
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





