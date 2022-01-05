function ieObject = piEXR2ISET(inputFile, varargin)
% Read an exr-file rendered by PBRT, and return an ieObject or a
% metadataMap
%       ieObject =  piEXR2ISET(inputFile, varagin)
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
%   ieObject- if label is radiance with omni/realistic lens: optical image;
%             if label is radiance with other types of lens: scene;
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
p.addParameter('label',{'radiance'},@(x)(ischar(x)||iscell(x)));

p.addParameter('recipe',[],@(x)(isequal(class(x),'recipe')));
p.addParameter('wave', 400:10:700, @isnumeric);

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

for ii = 1:numel(label)
    
    switch label{ii}
        case {'radiance','illuminance'}
            energy = piReadEXR(inputFile, 'data type','radiance');
            
            if isempty(find(energy(:,:,17),1))
                energy = energy(:,:,1:16);
                data_wave = 400:20:700;
            else
                data_wave = 400:10:700;
            end            
            photons  = Energy2Quanta(data_wave,energy);

        case {'depth', 'zdepth'}
            try
                % we error if x & y are missing 
                % unless we call zdepth -- we should probably
                % just have the ReadEXR code be more resilient
                % we might already have the output, but it might or
                % might not have a suffix?
                [dir, file, ~] = fileparts(inputFile);
                exrFile = fullfile(dir, file);
                depthFile = sprintf('%s_%d_%d_Pz',exrFile, thisR.film.yresolution.value, ...
                        thisR.film.xresolution.value);
                if isfile(depthFile)
                    [fid, ~] = fopen(depthFile, 'r');
                    serializedImage = fread(fid, inf, 'float');
                    ieObject = reshape(serializedImage, thisR.film.yresolution.value, thisR.film.xresolution.value, 1);
                    fclose(fid);
                    delete(depthFile);

                else
                    depthImage = piReadEXR(inputFile, 'data type','zdepth');
                end
                
            catch
                warning('Can not find "Pz(?)" channel in %s, ignore reading depth', inputFile);
                continue
            end
            
        case 'coordinates'
            coordinates = piReadEXR(inputFile, 'data type','3dcoordinates');
            
        case 'material'   
            materialID = piReadEXR(inputFile, 'data type','material');
            
        case 'normal'
            % to add
        case 'albedo'
            % to add; only support rgb for now, spectral albdeo needs to add;
        case 'instance'
            instanceID = piReadEXR(inputFile, 'data type','instanceId');
    end
end

%%
% Create a name for the ISET object
if ~isempty(thisR)
    pbrtFile   = thisR.get('output basename');
    ieObjName  = sprintf('%s-%s',pbrtFile,datestr(now,'mmm-dd,HH:MM'));
    cameraType = thisR.get('camera subtype');
else
    ieObjName  = sprintf('ISETScene-%s',datestr(now,'mmm-dd,HH:MM'));
    cameraType = 'perspective';
end

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
        
    case {'omni'}
        % todo
        %% HACK ALERT: Copy other case code here to see what happens:
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

    otherwise
        error('Unknown optics type %s\n',cameraType);
end
if exist('ieObject','var') && ~isempty(ieObject) && exist('depthImage','var')
    ieObject = sceneSet(ieObject,'depth map',depthImage);
end
end





