function ieObject = piEXR2ISET(inputFile, varargin)
% Read an exr-file rendered by PBRT, and return an ieObject or a
% metadataMap
%       ieObject =  piEXR2ISET(inputFile, varagin)
%
% Brief description:
%   We take an exr-file from pbrt as input and return an ISET object.
%
% Inputs
%   inputFile - Multi-spectral exr-file rendered by pbrt.
%
% Optional key/value pairs
%   label            -  Specify the type(s) of data: radiance, mesh, depth.
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
% p.addParameter('wave', 400:10:700, @isnumeric);

% For the OI case
p.addParameter('meanilluminancepermm2',5,@isnumeric);
p.addParameter('scalepupilarea',true,@islogical);

% For the pinhole case
p.addParameter('meanluminance',100,@isnumeric);

% determine how chatty we should be
% p.addParameter('verbose', 2, @isnumeric);

p.parse(inputFile,varargin{:});
label       = p.Results.label;
thisR       = p.Results.recipe;
% verbosity   = p.Results.verbose;

meanIlluminancepermm2 = p.Results.meanilluminancepermm2;
scalePupilArea        = p.Results.scalepupilarea;
meanLuminance         = p.Results.meanluminance;
% wave                  = p.Results.wave;
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


            % case 'depth'
            %    try
            %        depthImage = piReadEXR(inputFile, 'data type','depth');

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

                elseif isequal(label{ii},'depth')
                    depthImage = piReadEXR(inputFile, 'data type','depth');
                elseif isequal(label{ii},'zdepth')
                    depthImage = piReadEXR(inputFile, 'data type','zdepth');
                end

            catch
                warning('Can not find "Pz(?)" channel in %s, ignore reading depth', inputFile);
                continue
            end

            % case 'zdepth'
            %    depthImage = piReadEXR(inputFile, 'data type','zdepth');

        case 'coordinates'
            % Should the coordinates be ieObject?
            coordinates = piReadEXR(inputFile, 'data type','3dcoordinates');

        case 'material'
            % Should the materialID be ieObject?
            materialID = piReadEXR(inputFile, 'data type','material');

        case 'normal'
            % to add
        case 'albedo'
            % to add; only support rgb for now, spectral albdeo needs to add;

        case 'instance'
            % Should the instanceID be ieObject?
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
        % A scene radiance, not an oi
        % NB: This fails if we are only asked for depth!!
        ieObject = piSceneCreate(photons,...
            'wavelength', data_wave);
        ieObject = sceneSet(ieObject,'name',ieObjName);
        if ~isempty(thisR)
            % PBRT may have assigned a field of view
            ieObject = sceneSet(ieObject,'fov',thisR.get('fov'));
        end

        % In this case we cannot scale by the area because the aperture
        % is a pinhole.  The ieObject is a scene.  So we use the mean
        % luminance parameter (default is 100 cd/m2).
        if meanLuminance > 0
            ieObject = sceneAdjustLuminance(ieObject,meanLuminance);
        end
        ieObject = sceneSet(ieObject,'luminance',sceneCalculateLuminance(ieObject));

        %{
        % Pinhole and perspective mean the same thing.
        % In this camera type, we consider the data a scene.
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
        %}
    case {'realisticdiffraction','realistic','omni','raytransfer'}
        % If we used a lens, the ieObject is an optical image (irradiance).
        %
        % We specify the mean illuminance of the OI mean illuminance
        % with respect to a 1 mm^2 aperture. That way, if we change
        % the aperture, but nothing else, the illuminance level will
        % scale correctly.

        % We read the lens parameters differently for ray transfer type
        switch(cameraType)
            case 'raytransfer'
                % Just made stuff up for defaults at this point
                fNumber = [];
                focalLength = [];
                lensData = jsonread(thisR.camera.lensfile.value);
                if isfield(lensData,'fnumber')
                    fNumber = lensData.fnumber;
                end
                if isfield(lensData,'focallength')
                    focalLength = lensData.focallength;
                end

            otherwise
                % Try to find the optics parameters from the lensfile in the
                % PBRT recipe.  The function looks for metadata, if it cannot
                % find that slot it tries to decode the file name.  The file
                % name part should go away before too long because we can just
                % create the metadata once from the file name.
                [focalLength, fNumber] = piRecipeFindOpticsParams(thisR);
        end

        % Start building the oi
        ieObject = piOICreate(photons,'wavelength',data_wave);

        % Set the parameters the best we can from the lens file.
        if ~isempty(focalLength)
            ieObject = oiSet(ieObject,'optics focal length',focalLength);
        end
        if ~isempty(fNumber)
            ieObject = oiSet(ieObject,'optics fnumber',fNumber);
        end

        % Calculate and set the oi 'fov' using the film diagonal size
        % and the lens information.  First get width of the film size.
        % This could be a function inside of get.
        filmDiag = thisR.get('film diagonal')*10^-3;  % In meters
        res      = thisR.get('film resolution');
        x        = res(1); y = res(2);
        d        = sqrt(x^2 + y^2);        % Number of samples along the diagonal
        filmwidth   = (filmDiag / d) * x;  % Diagonal size by d gives us mm per step

        % Next calculate the fov
        focalLength = oiGet(ieObject,'optics focal length');
        fov         = 2 * atan2d(filmwidth / 2, focalLength);
        ieObject    = oiSet(ieObject,'fov',fov);

        ieObject = oiSet(ieObject,'name',ieObjName);

        ieObject = oiSet(ieObject,'optics model','iset3d');
        if ~isempty(thisR)
            lensfile = thisR.get('lens file');
            ieObject = oiSet(ieObject,'optics name',lensfile);
        else
            warning('Render recipe is not specified.');
        end

        % We set meanIlluminance per square millimeter of the lens
        % aperture.
        if(scalePupilArea)
            aperture = oiGet(ieObject,'optics aperture diameter');
            lensArea = pi*(aperture*1e3/2)^2;
            meanIlluminance = meanIlluminancepermm2*lensArea;

            ieObject        = oiAdjustIlluminance(ieObject,meanIlluminance);
            ieObject.data.illuminance = oiCalculateIlluminance(ieObject);
        end
    case {'realisticeye'}
        % A human eye model, and the ieObject is an optical image (irradiance).

        focalLength = thisR.get('retina distance','m');
        pupilDiameter = thisR.get('pupil diameter','m');
        fNumber = focalLength/pupilDiameter;

        % Start building the oi
        ieObject = piOICreate(photons,'wavelength',data_wave);

        % Set the parameters the best we can from the lens file.
        ieObject = oiSet(ieObject,'optics focal length',focalLength);
        ieObject = oiSet(ieObject,'optics fnumber',fNumber);

        % Calculate and set the oi 'fov'.
        fov = thisR.get('fov');
        ieObject    = oiSet(ieObject,'fov',fov);

        ieObject = oiSet(ieObject,'name',ieObjName);

        ieObject = oiSet(ieObject,'optics model','iset3d');
        if ~isempty(thisR)
            eyeModel = thisR.get('realistic eye model');
            ieObject = oiSet(ieObject,'optics name',eyeModel);
        else
            % This should never happen!
            warning('Render recipe is not specified.');
        end

        % We set meanIlluminance per square millimeter of the lens
        % aperture.
        if(scalePupilArea)
            aperture = oiGet(ieObject,'optics aperture diameter');
            lensArea = pi*(aperture*1e3/2)^2;
            meanIlluminance = meanIlluminancepermm2*lensArea;

            ieObject        = oiAdjustIlluminance(ieObject,meanIlluminance);
            ieObject.data.illuminance = oiCalculateIlluminance(ieObject);
        end
    otherwise
        error('Unknown optics type %s\n',cameraType);
end
if exist('ieObject','var') && ~isempty(ieObject) && exist('depthImage','var') && numel(depthImage) > 1
    ieObject = sceneSet(ieObject,'depth map',depthImage);
end

end
