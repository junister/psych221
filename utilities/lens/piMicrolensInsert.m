function [combinedLensName, uLens, iLens]  = piMicrolensInsert(microLens,imagingLens,varargin)
% Combine a microlens with an imaging lens into a lens file
%
% Syntax
%   [combinedLensName, uLens, iLens]  = piMicrolensInsert(microLens,imagingLens,varargin)
%
% Brief description:
%   Create a json file that combines the imaging and microlens array.
%   Used for PBRT omni camera rendering.
%   
% Inputs:
%   uLens - Microlens file name or a lensC of the lens
%   iLens - Imaging lens file name or a lensC of the lens
%
% Optional key/value pairs
%   output name   - File name of the output combined lens
%   uLensHeight   - Shouldn't this be part of the microlens file?
%   nMicrolens    - 2-vector for row/col?
%
% Default parameters - not always useful.  Should create a routine to
% generate default parameters
%   n microlens        - x,y number (col, row)
%   microlens diameter - microns?
%   filmwidth   -   4 microns for each of the 3 superpixels behind the
%                   microlens; 84 superpixels, 84 * 12 (um) ~ 1 mm
%   filmheight  -  
%   filmtomicrolens - Only works for 0.
%
% Output
%   combinedLens - Full path to the output file
%   cmd  - Full docker command that was built
%
% See also
%   piMicrolensWrite

%{
%convert options:
%    --inputscale <n>    Input units per mm (which are used in the output). Default: 1.0
%    --implicitdefaults  Omit fields from the json file if they match the defaults.
%
% insertmicrolens options:
%    --xdim <n>             How many microlenses span the X direction.
%        Default - tile the film based on uLens height and film width
%    --ydim <n>             How many microlenses span the Y direction.
%        Default - tile the film based on uLens height and film height
%
%    --filmwidth <n>        Width of target film  (mm). Default: 20.0
%    --filmheight <n>       Height of target film (mm). Default: 20.0
%    --filmtolens <n>       Distance (mm) from film to back of main lens system . Default: 50.0
%    --filmtomicrolens <n>  Distance (mm) from film to back of microlens. Default: 0.0 and only
%
%}


%{
 chdir(fullfile(piRootPath,'local','microlens'));
 microLens   = lensC('filename','microlens.json');
 imagingLens = lensC('filename','dgauss.22deg.3.0mm.json');
 combinedLens = piMicrolensInsert(microLens,imagingLens,'film to microlens',0);

 thisLens = jsonread(combinedLens);
%}
%{

%}

%% Programming TODO
%
%   The filmheight and filmwidth seem to have an error when less than 1.
%   Checking with Mike Mara.
%
%
% To set the distance between the microlens and the film, you must adjust a
% parameter in the OMNI camera.  Talk to TL about that!

%% Parse inputs

varargin = ieParamFormat(varargin);

p = inputParser;

% Input can be the filename of the lens or the lens object
vFile = @(x)(isa(x,'lensC') || (ischar(x) && exist(x,'file')));
p.addRequired('imagingLens',vFile);
p.addRequired('microLens',vFile);

p.addParameter('microlensdiameter',0.028,@isscalar);   % Default is 2.8 microns
p.addParameter('outputname','',@ischar);
p.addParameter('nmicrolens',[],@isvector);    % x,y (col, row)

p.addParameter('xdim',[],@isscalar);
p.addParameter('ydim',[],@isscalar);
p.addParameter('filmheight',1,@isscalar);
p.addParameter('filmwidth',1,@isscalar);
p.addParameter('filmtomicrolens',0,@isscalar);   % Only works for 0 at this time.

p.parse(imagingLens,microLens,varargin{:});

nMicrolens = p.Results.nmicrolens;

% If a lensC was input, the lensC might have been modified from the
% original fullFileName. So we write out a local copy of the json file.
if isa(imagingLens,'lensC')
    thisName = [imagingLens.name,'.json']; 
    imagingLens.fileWrite(thisName);
    imagingLens = fullfile(pwd,thisName);
end

if isa(microLens,'lensC')
    mlObj = microLens;
    thisName = [microLens.name,'.json'];
    microLens.fileWrite(thisName);
    microLens = fullfile(pwd,thisName);
end

if isempty(p.Results.outputname)
    [~,imagingName,~]   = fileparts(imagingLens);
    [~,microLensName,e] = fileparts(microLens); 
    combinedLensName = fullfile(pwd,sprintf('%s+%s',imagingName,[microLensName,e]));
else
    combinedLensName = p.Results.outputname;
end

%% Set up dimension and film parameters

filmheight = ceil(p.Results.filmheight);
filmwidth  = ceil(p.Results.filmwidth);

% If the user did not specify  xdim and ydim, set up the number of
% microlenses so that the film is tiled based on the lens height.
if isempty(nMicrolens)
    xdim =  floor((filmheight/mlObj.get('lens height')));
    ydim =  floor((filmwidth/mlObj.get('lens height')));
else
    xdim = nMicrolens(1); ydim = nMicrolens(2);
end

%% Print out parameter summary
fprintf('\n------\nMicrolens insertion summary\n');
fprintf('Microlens dimensions %d %d \n',xdim,ydim);
fprintf('Film height and width %0.2f %0.2f mm\n',filmheight,filmwidth);
fprintf('------\n');

%% Remember where you started 
% 
% % Basic docker command
% if ispc
%     dockerCommand   = 'docker run -i --rm';
% else
%     dockerCommand   = 'docker run -ti --rm';
% end
% 
% % Where you want the output file
% % dockerCommand = sprintf('%s --workdir="%s"', dockerCommand, pathToLinux(outputFolder));
% dockerCommand = sprintf('%s --volume="%s":"%s"', dockerCommand, outputFolder, pathToLinux(outputFolder));
% 
% % What you want to run
% dockerImageName = dockerWrapper.localImage;

%% Copy the imaging and microlens to the output folder

outputFolder  = pwd;

iLensFullPath = which(imagingLens);
[~,n,e] = fileparts(iLensFullPath);
iLensCopy = fullfile(outputFolder,[n e]);
if ~exist(iLensCopy,'file')
    copyfile(iLensFullPath,iLensCopy)
else
    disp('Imaging lens copy exists.  Not over-writing');
end

mLensFullPath = which(microLens);
[~,n,e] = fileparts(mLensFullPath);
mLensCopy = fullfile(outputFolder,[n e]);
if ~exist(mLensCopy,'file')
    copyfile(mLensFullPath,mLensCopy)
else
    disp('Microlens copy exists.  Not over-writing');
end


%% Set up the lens tool command to run

% Replace this call.
% [combinedLens, cmd] = piDockerLenstool('insertmicrolens', ...
%     'xdim', xdim, 'ydim', ydim, ...
%     'filmheight', filmheight, 'filmwidth', filmwidth, ...
%     'imaginglens', imagingLens, 'microLens', microLens, ...
%     'filmtomicrolens',filmtomicrolens,...
%     'combinedlens', combinedLens, 'outputfolder', outputFolder);

iLens = lensC('file name',imagingLens);
combinedLens.description = iLens.description;
combinedLens.microlens = [];
combinedLens.name = [imagingLens,' + ',microLens];
combinedLens.surfaces = lens2pbrt(iLens);
combinedLens.type = iLens.type;

uLens = lensC('file name',microLens);
combinedLens.microlens.dimensions = [xdim,ydim]';
combinedLens.microlens.offsets = zeros(xdim*ydim,2);
combinedLens.microlens.surfaces = lens2pbrt(uLens);

jsonwrite(combinedLensName,combinedLens);

end

function surfaces = lens2pbrt(uLens)
% Take a lensC and returns it as an array of structs needed to write
% into the PBRT file for rendering.

if ~numel(unique(uLens.surfaceArray(1).n)) == 1
    warning('Index of refraction is not constant.')
end

surfaceArray = uLens.surfaceArray;
for ii=1:numel(surfaceArray)
    thisSurf = surfaceArray(ii);
    surfaces(ii).conic_constant = thisSurf.conicConstant;  %#ok<*AGROW> % Or {}.  To check

    % We should check that the IOR is the same for all the wavelengths
    % for this surface.  If it is not, warn.
    surfaces(ii).ior = thisSurf.n(1);
    surfaces(ii).radius = thisSurf.sRadius;
    surfaces(ii).semi_aperture = thisSurf.apertureD/2;

    % Distance between the surfaces
    offsetLists = uLens.get('offsets');
    % PBRT files need the distance between the surfaces.
    surfaces(ii).thickness = offsetLists(ii);
end

end
