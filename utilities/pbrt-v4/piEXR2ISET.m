function ieObject = piEXR2ISET(inputFile, varargin)
% Read an exr-file rendered by PBRT, and return an ieObject or a
% metadataMap
%       ieObject = piExr2ISET(inputFile, varagin)
% 
% Brief description:
%   We take a exr-file from pbrt as input and return an ISET object.
%
% Inputs
%   inputFile - Multi-spectral exr-file rendered by pbrt.
% 
% Optional key/value pairs
%   label            -  Specify the type of data: radiance, mesh, depth.
%                       Default is radiance
%   recipe           -  The recipe used to create the file
%   mean luminance   -  Set the mean illuminance, if -1 do not scale values
%                       returned by the renderer.
%   mean luminance per mm2 - Set the mean illuminance per square pupil mm
%   scalePupilArea -  if true, we scale the mean illuminance by the pupil
%                       diameter.
%
% Output
%   ieObject: if label is radiance: optical image;
%             else, a metadatMap
%
%
% Zhenyi, 2021
%
% ## python test
% python installation: https://docs.conda.io/en/latest/miniconda.html
% Install python 3.8 for matlab 2020 and above
% check version in matlab command window:
%          pe = pyenv; 
% Install python library for reading exr files, run this in terminal: 
%          sudo apt install libopenexr-dev # (ubuntu)
%          brew install openexr # (mac)
%          pip install git+https://github.com/jamesbowman/openexrpython.git
%          pip install pyexr
%%
%{
 opticalImage = piEXR2ISET('radiance.exr','label','radiance','recipe',thisR);
%}

%%
varargin =ieParamFormat(varargin);

p = inputParser;
p.addRequired('inputFile',@(x)(exist(x,'file')));
p.addParameter('label','radiance',@(x)(ischar(x)||iscell(x)));

p.addParameter('recipe',[],@(x)(isequal(class(x),'recipe')));
p.addParameter('wave', [], @isnumeric);

% For the OI case
p.addParameter('meanilluminancepermm2',5,@isnumeric);
p.addParameter('scalepupilarea',true,@islogical);

% For the pinhole case
p.addParameter('meanluminance',100,@isnumeric);

% determine how chatty we should be
p.addParameter('verbose', 2, @isnumeric);

p.parse(inputFile,varargin{:});
label       = p.Results.label;
thisR       = p.Results.recipe;
verbosity   = p.Results.verbose;

meanIlluminancepermm2 = p.Results.meanilluminancepermm2;
scalePupilArea        = p.Results.scalepupilarea;
meanLuminance         = p.Results.meanluminance;
wave                  = p.Results.wave;
%%
if numel(label)==1, label={label};end

for ii = 1:numel(label)
    
    switch label{ii}
        case 'radiance'
            %             energy = piReadEXR(inputFile, 'data type','radiance');
            energy = single(py.pyexr.read(inputFile,'Radiance'));
            if isempty(find(energy(:,:,17),1))
                energy = energy(:,:,1:16);
            end
            dim_energy = size(energy);
            
            if dim_energy(3)==31
                data_wave = 400:10:700;
            elseif dim_energy(3)==16
                data_wave = 400:20:700;
            end
            
            photons  = Energy2Quanta(data_wave,energy);
            
        case 'depth'
            
            depthImage = single(py.pyexr.read(inputFile,'Pz'));
            
        case 'coordinates'
            coordinates(:,:,1) = single(py.pyexr.read(inputFile,'Px'));
            coordinates(:,:,2) = single(py.pyexr.read(inputFile,'Py'));
            coordinates(:,:,3) = single(py.pyexr.read(inputFile,'Pz'));
            
        case 'material'
            
            materialID = single(py.pyexr.read(inputFile,'MaterialId'));
            
        case 'normal'
            % to add
        case 'albedo'
            % to add; only support rgb for now, spectral albdeo needs to add;
        case 'instance'
            % to add
    end
end

%%
% Create a name for the ISET object
pbrtFile   = thisR.get('output basename');
ieObjName  = sprintf('%s-%s',pbrtFile,datestr(now,'mmm-dd,HH:MM'));

cameraType = thisR.get('camera subtype');
switch lower(cameraType)
    case {'pinhole','spherical','perspective'}
        ieObject = piSceneCreate(photons,'wavelength', data_wave);
        ieObject = sceneSet(ieObject,'name',ieObjName);
        if numel(data_wave)<31
            % interpolate data for gpu rendering
            ieObject = sceneInterpolateW(ieObject,wave);
        end
        
        if ~isempty(thisR)
            % PBRT may have assigned a field of view
            ieObject = sceneSet(ieObject,'fov',thisR.get('fov'));
        end
        
    case {'realistic'}
        % todo
    otherwise
        error('Unknown optics type %s\n',cameraType);
end
if exist('ieObject','var') && ~isempty(ieObject)
    ieObject = sceneSet(ieObject,'depth map',depthImage);
end
end





