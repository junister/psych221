function [thisR, out] = recipeSet(thisR, param, val, varargin)
% Set a recipe class value
%
% Syntax
%   [thisR, out] = recipeSet(thisR, param, val, varargin)
%     Returns us (thisR) as the primary result, which should be un-needed because
%     we are a by-reference (handle) class. Second result is an optional
%     error code or other return value.
%
% Description:
%   The recipe class manages the PBRT rendering parameters.  The class
%   has many fields specifying camera and rendering parameters. This
%   method is only capable of setting one parameter at a time.
%
% Parameter list (in progress, many more to be added)
%
%   Data management
%    'input file'
%    'output file
%    'rendered file'
%
%  %Scene
%    'mm units'   - Logical (true/false)
%    'exporter'   - Information about where the PBRT file came from
%    'lookat'     - includes the 'from','to', and 'up' vectors
%    'from'       - Position of the camera
%    'to'         - Position the camera is pointed to
%    'up'         - The up direction, not always the y-direction
%
%  % Lights
%    'skymap'     - Name of environmental light exr file
%    'skymap', 'rotation val', <over-ride default rotatio>
%    'skymap, <name>, <optional attribute>, <attribute value>
%
%  % Camera
%    'camera'     - Struct with camera information
%    'camera subtype' - The valid camera subtypes are
%                       {'pinhole','realistic','realisticEye','omni'}
%    'camera exposure'
%    'camera body'      - Do not use
%
%    'object distance' - Distance between from and to
%    'accommodation'   - Inverse of the focus distance
%    'exposure time'   - forces shutteropen to 0
%    'shutteropen'     - time for shutter opening
%    'shutterclose'    - time at which shutter closes
%    'focus distance'  - Distance to where the camera is in best focus
%    'focal distance'  - Used with pinhole to define image plane distance
%                        from the pinhole
%    'n microlens'     - Number of microlenses in front of the sensor
%    'n subpixels'     - Number of pixels behind each microlens
%    'light field film resolution' - ????
%
%   % Lens
%     'lens file'    - JSON file for omni.  Older models (realistic) use dat-file
%     'lens radius'  - Only for perspective camera.  Use aperture diameter
%                      for omni
%     'aperture diameter' - mm
%     'fov'
%     'diffraction'
%     'chromatic aberration'
%
%   % Film
%     'film diagonal'
%     'film distance'
%     'spatial samples'
%
%   % RealisticEye (human optics)
%     'retina distance' - mm
%     'eye radius'      - mm
%     'retina semdiam'  - mm
%     'pupil diameter'  - mm
%     'ior1','ior2','ior3','ior4' - Index of refraction data for Navarro eye
%                          model
%
%  Film/sensor
%    'film diagonal'
%    'film distance'
%    'film resolution'
%    'rays per pixel'
%
%  Rendering
%    'integrator num ca bands'
%    'integrator subtype'
%    'sampler'
%    'filter'
%    'rays per pixel'
%    'crop window'
%    'nbounces'
%    'autofocus'
%
%  Assets
%    TODO
%
%  Materials
%    TODO
% ---
%    'materials'
%    'materials output file'
%    'fluorophore concentration'
%    'fluorophore eem'
%    'concentration'
%
%  Programming related
%    'verbose'
% ---

%  ISETAuto special:
%    'traffic flow density'%
%    'traffic time stamp'
%
% BW ISETBIO Team, 2017
%
% PBRT information that explains man
% Generally
% https://www.pbrt.org/fileformat-v3.html#overview
%
% Specifically
% https://www.pbrt.org/fileformat-v3.html#cameras
%
% See also
%    @recipe, recipeGet

% Examples:
%{
%}

%% Set up

if isequal(param,'help')
    doc('recipe.recipeSet');
    return;
end

out = [];

%% Parse
p = inputParser;
p.KeepUnmatched = true;

vFunc = @(x)(isequal(class(x),'recipe'));
p.addRequired('thisR',vFunc);
p.addRequired('param',@ischar);
p.addRequired('val');

p.addParameter('lensfile','dgauss.22deg.12.5mm.dat',@(x)(exist(x,'file')));
p.addParameter('verbose', thisR.verbose, @isnumeric);

p.parse(thisR, param, val);
param = ieParamFormat(p.Results.param);
verbosity = p.Results.verbose;

%% Act

switch param

    % Rendering and Docker related
    case {'outputfile'}
        % thisR.set('outputfile',fullfilepath);
        %

        %{
        % The outputfile has a default initial string.  When we set,
        % we check that the new directory exists. If not, we make it.
        % If there were files in the previous directory we copy them
        % to the new directory.  Maybe there should be an option to
        % stop the copy.
        %
        % I think it is strange that we are doing this in a set. (BW).

        newDir     = fileparts(val);
        if ~exist(newDir,'dir')
            if verbosity > 1
                fprintf('Creating output folder %s\n',newDir);
            end
            mkdir(newDir);
        end
        %}
        newDir = fileparts(val);

        thisR.outputFile = val;

    case {'inputfile'}
        % thisR.set('input file',filename);
        val = which(val);
        thisR.inputFile = val;
        if ~exist(val,'file'), warning('No input file found yet'); end
    case {'verbose'}
        thisR.verbose = val;
    case {'exporter'}
        % thisR.set('exporter',val);
        % a string that identifies how the PBRT file was build
        % We have 'C4D','Copy','Unknown'
        thisR.exporter = val;
    case 'renderedfile'
        % thisR.set('rendered file',fname);
        % Set the full path
        thisR.renderedfile = val;

        % Scene parameters
    case 'objectdistance'
        % The 'from' spot, is the camera location.  The 'to' spot is
        % the point the camera is looking at.  Both are specified in
        % meters.
        %
        % This routine adjusts the the 'from' position, moving the
        % camera position. It does so by keeping the 'to' position the
        % same, so the camera is still looking at the same location.
        % Thus, this set moves the camera closer or further from the 'to'
        % position.
        %
        % What is the relationship to the focal distance?  If we move
        % the camera, the focal distance is always with respect to the

        % camera, right?  Or is it always at the 'to' distance???  You can
        % force it to be the 'to' by using
        %
        % thisR.set('focal distance',thisR.get('object distance'))
        %

        assert(val > 0);  % We do not change which side of 'to' this way.

        % Unit length vector  objDir = ('to' - 'from')
        % So, 'from' + objDir moves towards 'to'
        %     'from' - objDir moves away from 'to'
        objDirection = thisR.get('object direction');

        % Change in distance (in meters).  If val is bigger, delta is
        % negative and adding moves away from 'to'.  If val is smaller,
        % delta is positive and we move towards 'to'.
        delta = thisR.get('object distance') - val;

        % Test: If we set val to 0, the new from should be at 'to',
        thisR.lookAt.from = thisR.lookAt.from + objDirection*delta;

    case {'accommodation'}
        % Special case where we allow setting accommodation or focal
        % distance.  My optometrist friends insist.
        thisR.set('focal distance',1/val);

    case {'focusdistance','focaldistance'}
        % lens.set('focus distance',m)
        %
        % This is the distance (m) to the object in the scene that
        % will be in focus.  The film distance is derived by PBRT from
        % this parameter.  It is possible that there is no film
        % distance for certain (say very near) focus distances.
        %
        % This variable is related to the lookat settings.  That
        % parameter says where the camera is pointing.  But the
        % distance to the object (objectdistance) may not be the same
        % as this focus distance. That is because it is possible to
        % look at an object but have it not be the object that is in
        % focus.
        %
        % Depending on the camera type, the parameter name is either
        % focusdistance or focaldistance. Historical annoyance in PBRT.
        if isequal(thisR.camera.subtype,'pinhole')||...
                isequal(thisR.camera.subtype,'perspective')
            thisR.camera.focaldistance.value = val;
            thisR.camera.focaldistance.type = 'float';
            % pbrt v4 gets mad if we don't get rid of the field
            if isfield(thisR.camera,'focusdistance')
                thisR.camera = rmfield(thisR.camera,'focusdistance');
            end
        else
            % When there is a lens.  Omni.  Realistic.
            thisR.camera.focusdistance.value = val;
            thisR.camera.focusdistance.type = 'float';
        end

        % Camera
    case 'camera'
        % val = piCameraCreate('pinhole'); thisR = recipe;
        % thisR.set('camera',val);
        %
        % The whole camera struct
        thisR.camera = val;
        %{

        % This deprecated code is very bizarre for recipeSet. So I replaced
        % it.  But probably this change will break stuff.  We will have to
        % fix.
        thisR.camera = piCameraCreate(val,'lensFile',p.Results.lensfile);

        % For the default camera, the film size is 35 mm
        thisR.set('film diagonal',35);

        %}
    case 'scale'
        % Scale something?? Was missing until December 11, 2021.
        % Will experiment with what it does.  There is a slot for it in
        % piWrite().
        if numel(val) == 3,     thisR.scale = val(:)';
        elseif numel(val) == 1, thisR.scale = ones(3,1)*val;
        else, warning('Bad scale value.  Must be scalar or 3-vector');
        end

    case 'mmunits'
        % thisR.set('mm units',true/false)
        %
        % Indicate whether we are in millimeter units or not
        thisR.camera.mmUnits.type = 'bool';
        if val
            % val is true, so we are in millimeter units
            thisR.camera.mmUnits.value = 'true';
        else
            % We are probably in units of meters, not millimeters
            thisR.camera.mmUnits.value = 'false';
        end
    case {'transformtimesstart'}
        thisR.transformTimes.start = val;
        if ~isfield(thisR.transformTimes, 'end')
            warning('Adding transform end time: %.4f', val + 1);
            thisR.transformTimes.end = val + 1;
        end
    case {'transformtimesend'}
        if ~isfield(thisR.transformTimes, 'start')
            warning('Adding transform start time: %.4f', 0);
            thisR.transformTimes.start = 0;
        end
        thisR.transformTimes.end = val;
    case 'cameratype'
        % This should always be 'Camera'
        if ~isequal(val,'Camera')
            error('Check your code');
        end
    case {'camerasubtype'}
        % I don't think the sub is needed.  But there it is.
        thisR.camera.subtype = val;

        % Camera motion
    case {'cameramotiontranslatestart'}
        % thisR.set('camera motion translate start',vector)
        thisR.camera.motion.activeTransformStart.pos = val;

    case {'cameramotiontranslateend'}
        % thisR.set('camera motion translate end',vector)
        thisR.camera.motion.activeTransformEnd.pos = val;

    case {'cameramotionrotatestart'}
        % thisR.set('camera motion rotate start',rotMatrix)
        thisR.camera.motion.activeTransformStart.rotate = val;

    case {'cameramotionrotateend'}
        % thisR.set('camera motion rotate end',rotMatrix)
        thisR.camera.motion.activeTransformEnd.rotate = val;

        % Camera exposure
    case {'cameraexposure','exposuretime'}
        % Shutter duration in sec
        % Shutter open is always at time zero
        thisR.camera.shutteropen.type  = 'float';
        thisR.camera.shutteropen.value = 0;

        thisR.camera.shutterclose.type = 'float';
        thisR.camera.shutterclose.value = val;
    case {'shutteropen'}
        % thisR.set('shutter open',time)
        if isfield(thisR.camera,'shutterclose')
            if val > thisR.camera.shutterclose.value
                warning('Open time later than open time');
            end
        end
        thisR.camera.shutteropen.type  = 'float';
        thisR.camera.shutteropen.value = val;
    case {'shutterclose'}
        % thisR.set('shutter close',time)
        if isfield(thisR.camera,'shutteropen')
            if val < thisR.camera.shutteropen.value
                warning('Close time earlier than open time');
            end
        end
        thisR.camera.shutterclose.type = 'float';
        thisR.camera.shutterclose.value = val; %single(val);

        % Lens related
    case 'lensfile'
        % lens.set('lens file',val)   (string)
        % Typically a JSON file defining the camera.  But for realisticEye
        % we are still using dat files (e.g., navarro.dat).
        if ~exist(val,'file')
            % Sometimes we set this without the file being copied yet.
            % Let's see if this warning does us any good.
            warning('Lens file in out dir not yet found (%s)\n',val);
        end
        thisR.camera.lensfile.value = val;
        thisR.camera.lensfile.type = 'string';

    case {'lensradius'}
        % lens.set('lens radius',val (mm))
        %
        % Should only be set for perspective cameras
        %
        if isequal(thisR.camera.subtype,'perspective')
            thisR.camera.lensradius.value = val;
            thisR.camera.lensradius.type = 'float';
        else
            warning('Lens radius is set for perspective camera.  Use aperture diameter for omni');
        end

        % Human eye model related
    case {'retinadistance'}
        % Specified in mm
        thisR.camera.retinaDistance.value = val;
        thisR.camera.retinaDistance.type = 'float';
    case {'eyeradius','retinaradius'}
        % Specified in mm
        thisR.camera.retinaRadius.value = val;
        thisR.camera.retinaRadius.type = 'float';
    case {'retinasemidiam'}
        % Specified in mm
        thisR.camera.retinaSemiDiam.value = val;
        thisR.camera.retinaSemiDiam.type = 'float';
    case {'pupildiameter'}
        % Specified in mm
        thisR.camera.pupilDiameter.value = val;
        thisR.camera.pupilDiameter.type = 'float';

    case {'ior1','ior2','ior3','ior4'}
        % thisR.set('ior1',fullfilename);
        %
        % For the realisticEye Camera we store spd files that specify the
        % indices of refraction. for each of the different human optics
        % components.
        if ~isequal(thisR.get('camera subtype'),'realisticEye')
            warning('No ior slot except for realisticEye camera subtype.');
        else
            switch param(end)
                case '1'
                    % cornea
                    thisR.camera.ior1.value = val;
                    thisR.camera.ior1.type = 'spectrum';
                case '2'
                    % acqueous
                    thisR.camera.ior2.value = val;
                    thisR.camera.ior2.type = 'spectrum';
                case '3'
                    % lens
                    thisR.camera.ior3.value = val;
                    thisR.camera.ior3.type = 'spectrum';
                case '4'
                    % vitreous
                    thisR.camera.ior4.value = val;
                    thisR.camera.ior4.type = 'spectrum';
            end
        end

        % More general camera parameters
    case {'aperture','aperturediameter'}
        % lens.set('aperture diameter',val (mm))
        %
        % Set 'aperture diameter' should look at the aperture in the
        % lens file, which represents the largest possible aperture.
        % It should not allow a value bigger than that.  (ZL/BW).

        % Throw a warning for perspective camera
        if isequal(thisR.camera.subtype,'pinhole') ||...
                isequal(thisR.camera.subtype,'perspective')
            warning('Perspective/pinhole camera - setting "lens radius".')
            thisR.set('lens radius',val/2);
            return;
        end

        thisR.camera.aperturediameter.value = val;
        thisR.camera.aperturediameter.type = 'float';
    case 'fov'
        % This sets a horizontal fov
        % We should check that this is a pinhole, I think
        % This is only used for pinholes, not realistic camera case.
        if isequal(thisR.camera.subtype,'pinhole')||...
                isequal(thisR.camera.subtype,'perspective')
            if length(val)==1
                thisR.camera.fov.value = val;
                thisR.camera.fov.type = 'float';
            else
                % camera types:  omni, realisticeye,

                % if two fov is given [hor, ver], we should resize film
                % acoordingly.  This is the current number of spatial
                % samples for the two dimensions
                filmRes = thisR.get('spatial samples');

                % Set the field of view to the minimum of the two values
                fov = min(val);

                % horizontal resolution/ vertical resolution
                resRatio = tand(val(1)/2)/tand(val(2)/2);

                % Depending on which is the governing dimension, adjust the
                % number of spatial samples, using the resolution ratio.
                if fov == val(1)
                    thisR.set('spatial samples',[max(filmRes)*resRatio, max(filmRes)]);
                else
                    thisR.set('spatial samples',[max(filmRes), max(filmRes)/resRatio]);
                end
                thisR.camera.fov.value = fov;
                thisR.camera.fov.type = 'float';
                disp('film ratio is changed!')
            end
        else
            warning('fov not set for camera models');
        end
    case 'diffraction'
        % thisR.set('diffraction');
        %
        % Turn on diffraction rendering.  Works with realistic eye and
        % omni.  Probably realisticEye, but we should ask TL.
        if val
            thisR.camera.diffractionEnabled.value = 'true';
        else
            thisR.camera.diffractionEnabled.value = 'false';
        end
        thisR.camera.diffractionEnabled.type = 'bool';

    case 'chromaticaberration'
        % Enable chrommatic aberration, and potentially set the number
        % of wavelength bands.  (Default is 8).
        %   thisR.set('chromatic aberration',true);
        %   thisR.set('chromatic aberration',false);
        %   thisR.set('chromatic aberration',16);

        % Enable or disable
        thisR.camera.chromaticAberrationEnabled.type = 'bool';

        % User turned off chromatic abberations
        if isequal(val,false)
            % Use path, not spectralpath, integrator and set nunCABand to
            % 1.
            thisR.camera.chromaticAberrationEnabled.value = false;
            thisR.set('integrator subtype','path');
            thisR.set('integrator num ca bands',1);
            return;
        end

        % User sent in true or an integer number of bands which implies
        % true.
        thisR.camera.chromaticAberrationEnabled.value = true;

        % This is the integrator that manages chromatic aberration.
        thisR.set('integrator subtype','spectralpath');

        % Set the number of bands.  These are divided evenly into bands
        % between 400 and 700 nm. There are  31 wavelength samples, so we
        % should not have more than 30 wavelength bands
        if islogical(val), val = 8;  end % Default number of bands
        thisR.set('integrator num cabands',val);

    case {'integratorsubtype','integrator'}
        % thisR.set('integrator subtype',val)
        %
        % Different integrators are needed depending on the materials in
        % the scene, and also for chromatic aberration calculations.  For
        % example spectralpath is needed for CA.  bdpt is needed when there
        % are scattering media.
        thisR.integrator.type = 'Integrator';
        thisR.integrator.subtype = val;

    case 'integratornumcabands'
        thisR.integrator.type = 'Integrator';
        thisR.integrator.numCABands.value = val;
        thisR.integrator.numCABands.type = 'integer';

    case{'maxdepth','bounces','nbounces'}
        % thisR.set('n bounces',val);
        % Number of surfaces a ray can bounce from
        %
        % This can be set for some, but not all integrators.
        % Also, sometimes the integrator slot is empty.  I am not sure what
        % happens then (BW).

        if(~strcmp(thisR.integrator.subtype,'path')) &&...
                (~strcmp(thisR.integrator.subtype,'bdpt'))
            disp('Changing integrator sub type to "bdpt"');

            % When multiple bounces are needed, use this integrator
            thisR.integrator.subtype = 'bdpt';
        end
        thisR.integrator.maxdepth.value = val;
        thisR.integrator.maxdepth.type = 'integer';

    case 'autofocus'
        % Should deprecate this.  Let's run it for a while and see how
        % often it turns up.
        %
        % thisR.set('autofocus',true);
        % Sets the film distance so the lookAt to point is in good focus
        warning('Bad autofocus set in recipe.  Fix!');
        if val
            fdist = thisR.get('focal distance');
            if isnan(fdist)
                error('Camera is probably too close (%f) to focus.',thisR.get('object distance'));
            end
            thisR.set('film distance',fdist);
        end

        % Camera position related.  The units are in ????
    case 'lookat'
        % Includes the from, to and up in a struct
        if isstruct(val) &&  isfield(val,'from') && isfield(val,'to')
            thisR.lookAt = val;
        end
    case {'from','cameraposition'}
        thisR.lookAt.from = val(:)';  % Force row vector
    case 'to'
        thisR.lookAt.to = val(:)';
    case 'up'
        thisR.lookAt.up = val(:)';


        % Microlens
    case 'microlens'
        % Not sure about what this means.  It is on or off
        thisR.camera.microlens_enabled.value = val;
        thisR.camera.microlens_enabled.type = 'float';
    case 'nmicrolens'
        % Number of microlens/pinhole samples for a light field camera
        %
        if length(val) == 1, val(2) = val(1); end
        thisR.camera.num_pinholes_h.value = val(1);
        thisR.camera.num_pinholes_h.type = 'float';
        thisR.camera.num_pinholes_w.value = val(2);
        thisR.camera.num_pinholes_w.type = 'float';
    case 'lightfieldfilmresolution'
        % This is printed out in the pbrt scene file
        % It should only be a get, not a set.
        %{
        nMicrolens = thisR.get('n microlens');
        nSubpixels = thisR.get('n subpixels');
        thisR.set('film resolution', nMicrolens .* nSubpixels);
        %}
    case 'nsubpixels'
        % How many pixels behind each microlens/pinhole
        % The type is not included because this is not passed to pbrt.  It
        % is specified in the lens file made by the Docker container.  See
        % instructions about modeling light field cameras.
        thisR.camera.subpixels_h = val(1);
        thisR.camera.subpixels_w = val(2);

        % Film parameters
    case 'filmdiagonal'
        % thisR.set('film diagonal',val)
        % Default units are millimeters, Sigh.
        thisR.film.diagonal.type = 'float';
        thisR.film.diagonal.value = val;
    case {'filmdistance'}
        % Set in meters. Sigh again.
        thisR.camera.filmdistance.type = 'float';
        thisR.camera.filmdistance.value = val;
    case {'spatialsamples','filmresolution','spatialresolution'}
        % thisR.set('spatial samples',256);
        %
        % Number of spatial samples on the film (or retinal) surface. The
        % number of samples may be spread over larger or smaller field of
        % view.
        if length(val) == 1, val(2) = val(1); end
        thisR.film.xresolution.value = val(1);
        thisR.film.yresolution.value = val(2);
        thisR.film.xresolution.type = 'integer';
        thisR.film.yresolution.type = 'integer';

        % Sampler
    case 'samplersubtype'
        % thisR.set('sampler subtype','halton')
        %
        thisR.sampler.type = 'Sampler';
        thisR.sampler.subtype = val;
    case {'raysperpixel','pixelsamples'}
        % thisR.set('rays per pixel')
        % How many rays from each pixel
        if isempty(thisR.sampler)
            thisR.sampler.type = 'Sampler';
            thisR.sampler.subtype = 'pmj02bn';
        end
        thisR.sampler.pixelsamples.value = val;
        thisR.sampler.pixelsamples.type = 'integer';

    case{'cropwindow'}
        thisR.film.cropwindow.value = [val(1) val(2) val(3) val(4)];
        thisR.film.cropwindow.type = 'float';

        % SUMO parameters stored in recipe metadata
    case {'trafficflowdensity'}
        thisR.metadata.sumo.trafficflowdensity = val;
    case {'traffictimestamp'}
        thisR.metadata.sumo.timestamp = val;

    case 'filter'
        % Spatial filter for interpolating rays onto the film sampling grid
        % Options for the filter are
        %
        %    'box', 'triangle','gaussian','mitchell', 'sinc'
        %
        thisR.filter = val;

        % Getting ready for camera level recipe information.
        % Not really used yet and may never get used.
    case {'camerabody'}
        % Notice that val is rather special in this case. Which we are not
        % yet using.
        thisR.set('camera',val.camera);
        thisR.set('film',val.film);
        thisR.filter = thisR.set('filter',val.filter);

        % Materials should be built up here.
    case {'materials', 'material'}
        % Act on the list of materials
        %
        % thisR.set('material', materialList);
        % thisR.set('material', matName, newMaterial);
        % thisR.set('material', 'add', newMaterial);
        % thisR.set('material', 'delete', matName);
        % thisR.set('material', matName, 'PARAM TYPE', VAL);

        % In this case, we completely replace the material list.
        if isempty(varargin)
            if isa(thisR.materials.list, 'containers.Map')
                thisR.materials.list = val;
            else
                warning('Please provide a list of materials in a containers.Map')
            end
            return;
        end
        % Get index and material struct from the material list
        % Search by name or index
        if isstruct(val)
            % They sent in a struct
            if isfield(val,'name'), matName = val.name;
                % It has a name slot.
                thisMat = thisR.materials.list(matName);
            else
                error('Bad struct.');
            end
        elseif ischar(val)
            % It is either a special command or the material name
            switch val
                case {'add'}
                    newMat = varargin{1};
                    thisR.materials.list(newMat.name) = newMat;
                    return;
                case {'delete', 'remove'}
                    if isnumeric(varargin{1})
                        thisR.materials.list(varargin{1}) = [];
                    else
                        remove(thisR.materials.list, varargin{1})
                    end
                    return;
                case {'replace'}
                    thisR.materials.list(varargin{1}) = varargin{2};
                    return;
                otherwise
                    % Probably the material name.
                    matName = val;
                    thisMat = thisR.materials.list(val);
            end
        end

        % At this point we have the material.
        if numel(varargin{1}) == 1
            % A material struct was sent in as the only argument.  We
            % should check it, make sure its name is unique, and then set
            % it.
            thisR.materials.list(matName) = varargin{1};
        else
            % A material name and property was sent in.  We set the
            % property and then update the material in the list.
            thisMat = piMaterialSet(thisMat, varargin{1}, varargin{2});
            thisR.set('materials', matName, thisMat);
        end

    case {'materialsoutputfile'}
        % Deprecated?
        thisR.materials.outputfile = val;

    case {'textures', 'texture'}
        % thisR = piRecipeDefault('scene name', 'flatSurfaceRandomTexture');

        if isempty(varargin)
            if iscell(val)
                thisR.textures.list = val;
            else
                warning('Please provide a list of textures in cell array')
            end
            return;
        end
        % Get index and texture struct from the texture list
        % Search by name or index
        if isstruct(val)
            % They sent in a struct
            if isfield(val,'name'), textureName = val.name;
                % It has a name slot.
                thisTexture = thisR.textures.list(textureName);
            else
                error('Bad struct.');
            end
        elseif ischar(val)
            % It is either a special command or the texture name
            newTexture = varargin{1};
            switch val
                case {'add'}
                    % thisR.set('textures', 'add', texture struct);
                    thisR.textures.list(newTexture.name) = varargin{1};
                    return;
                case {'delete', 'remove'}
                    % thisR.set('texture', 'delete', idxORname);
                    remove(thisR.textures.list, varargin{1}.name)
                    return;
                case {'replace'}
                    % thisR.set('texture','replace', idxORname-1, newtexture-2)
                    thisR.textures.list(varargin{1}) = varargin{2};
                    return;
                case {'basis'}
                    % thisR.set('texture', 'basis', tName, wave, basisfunctions)
                    % basisfunctions need to have size of 3 x numel(wave)
                    if isequal(thisR.textures.list(varargin{1}).type, 'imagemap')
                        wave = varargin{2};
                        piTextureSetBasis(thisR, varargin{1}, wave, 'basis functions', varargin{3});
                    else
                        warning('Basis function only applies to image map.')
                    end
                    return;
                otherwise
                    % Probably the material name.
                    textureName = val;
                    [textureName, thisTexture] = piTextureFind(thisR.textures.list, 'name', textureName);
            end
        end

        % At this point we have the material.
        if numel(varargin{1}) == 1
            % A material struct was sent in as the only argument.  We
            % should check it, make sure its name is unique, and then set
            % it.
            thisTexture = varargin{1};
            thisR.textures.list(thisTexture.name) = varargin{1};
        else
            % A material name and property was sent in.  We set the
            % property and then update the material in the list.
            thisTexture = piTextureSet(thisTexture, varargin{1}, varargin{2});
            thisR.set('textures', textureName, thisTexture);
        end

    case {'skymap'} 
        % thisR.set('skypmap',filename)
        % add a skymap by filename
        
        skymapFileName = val;
        
        % if the map isn't already in the output dir, we have to copy it
        if ~isfolder(fullfile(thisR.get('output dir')))
            mkdir(fullfile(thisR.get('output dir')));
        end
        if ~isfile(fullfile(thisR.get('output dir'),skymapFileName))
            
            % If it is not in the local directory, check the data/lights
            if isfile(fullfile(piRootPath,'data','lights', skymapFileName))
                copyfile(fullfile(piRootPath,'data','lights', skymapFileName),...
                    thisR.get('output dir'));
            else
                % Not found yet, look for it on the path
                exrFile = which(skymapFileName);
                if ~isempty(exrFile)
                    fprintf('Using skymap:  %s\n',exrFile);
                    copyfile(exrFile,thisR.get('output dir'));
                else
                    warning("Unable to find skymap: %s\n", skymapFileName);
                    return % can't create the light
                end
            end
        end
        
        % Create a sky light with default params.
        [~, f, ~] = fileparts(skymapFileName);
        
        lName = f; % in case we want to get fancy later
        envLight = piLightCreate(lName, ...
            'type', 'infinite',...
            'mapname', skymapFileName);
        thisR.set('lights', envLight, 'add');
                        
        if ~isempty(varargin) && isequal(varargin{1},'rotation val')
            thisR.set('light', lName, 'rotate', varargin{2});
        else
            thisR.set('light', lName, 'rotate', [-90 0 0]);
        end

        % out = rLight;
        % We need to return rLight to our caller!

    case {'light', 'lights'}
        % Examples
        % After making light consistant with assets:
        % thisR.set('light', newLight, 'add');
        % thisR.set('light', newLightCellArray, 'add');
        % thisR.set('light', lightName, 'delete');
        % thisR.set('light', 'all', 'delete');
        % thisR.set('light', lightName, 'rotate', [XROT, YROT, ZROT], ORDER)
        % thisR.set('light', lghtName, 'translate', [XSFT, YSFT, ZSFT], FROMTO);
        % thisR.set('light', lightname, 'specscale', val);
        
        % Calling convention, val is lightName, varargin{1} is the
        % parameter(or action), and varargin{2} is the value, if needed.
        if isnumeric(val)
            thisLight = thisR.get('light', val);
            lghtName = thisLight.name;
            lghtName = piLightNameFormat(lghtName);
        elseif ischar(val)
            lghtName = val;
            lghtName = piLightNameFormat(lghtName);
        elseif isstruct(val) || iscell(val) % A light struct or a cell array
            newLight = val;
        else
            error('Unknown light parameter!');
        end
        
        param = varargin{1};
        
        if numel(varargin) == 2, val = varargin{2}; end
        
        switch ieParamFormat(param)
            case 'add'
                % thisR.set('light', newLight, 'add')
                if isstruct(newLight)
                    % Check if light name has '_L' in the end
                    newLight.name = piLightNameFormat(newLight.name);
                    newLightAsset = piAssetCreate('type', 'light');
                    newLightAsset.name = newLight.name;
                    newLightAsset.lght{1} = newLight;
                    defaultBranch = piAssetCreate('type', 'branch');
                    defaultBranch.name = [newLight.name(1:end-1), 'B'];
                    thisR.set('asset', 'root_B', 'add', defaultBranch);
                    thisR.set('asset', defaultBranch.name, 'add', newLightAsset);
                elseif iscell(newLight)
                    for ii=1:numel(newLight)
                        thisR.set('light', newLight{ii}, 'add');
                    end
                end
                return;
            case {'delete', 'remove'}
                % thisR.set('light', lightName, 'delete');
                if isequal(lghtName, 'all')
                    lgtNames = thisR.get('light', 'names');
                    for ii=1:numel(lgtNames)
                        thisR.set('asset', lgtNames{ii}, 'delete');
                    end
                else
                    thisR.set('asset', lghtName, 'delete');
                end
                return;
            case 'replace'
                % thisR.set('light', lightName, 'replace', newLight);
                thisLgtAsset = thisR.get('light', lghtName);
                val.name = piLightNameFormat(val.name);
                thisLgtAsset.lght{1} = val;
                thisLgtAsset.name = val.name;
                thisR.set('asset', lghtName, thisLgtAsset);
                return;
            case {'rotate', 'rotation'}
                % Rotate the direction, angle in degrees
                % thisR.set('light', lghtName, 'rotate', [XROT, YROT, ZROT], ORDER)
                % See piLightRotate
                lghtAsset = thisR.get('light', lghtName);
                lght = lghtAsset.lght{1};
                
                % This might not be elegant enough..? (ZLY)
                % If it has no from field, then the transformation will
                % be applied to the branch node (for infinite and area light).
                if ~isfield(lght, 'from')
                    thisR.set('asset', lghtName, 'rotate', val);
                    return;
                end
                
                % Else it has from field, treat it differently.
                % [lgtIdx, lght] = piLightFind(thisR.lights, 'name', varargin{1});
                
                if numel(varargin) == 2
                    xRot = varargin{2}(1);
                    yRot = varargin{2}(2);
                    zRot = varargin{2}(3);
                end
                if numel(varargin) == 3
                    order = varargin{3};
                else
                    order = ['x', 'y', 'z'];
                end
                
                lght = piLightRotate(lght, 'xrot', xRot,...
                    'yrot', yRot,...
                    'zrot', zRot,...
                    'order', order);
                thisR.set('asset', lghtName, 'lght', lght);
                return;
            case {'translate', 'translation'}
                % thisR.set('light', lghtName, 'translate', [XSFT, YSFT, ZSFT], FROMTO)
                % See piLightRotate
                % [lgtIdx, lght] = piLightFind(thisR.lights, 'name', varargin{1});
                lghtAsset = thisR.get('light', lghtName);
                lght = lghtAsset.lght{1};
                
                % If it has no from field, then the transformation will
                % be applied to the branch node (for infinite and area light).
                if ~isfield(lght, 'from')
                    thisR.set('asset', lghtName, 'translate', varargin{2});
                    return;
                end
                
                if numel(varargin) == 2
                    xSft = varargin{2}(1);
                    ySft = varargin{2}(2);
                    zSft = varargin{2}(3);
                    
                end
                if numel(varargin) == 3
                    fromto = varargin{3};
                else
                    fromto = 'both';
                end
                up = thisR.get('up');
                
                % If the light is at the same position of camera
                if lght.cameracoordinate
                    if isfield(lght, 'from')
                        lght = piLightSet(lght, 'from val', thisR.get('from'));
                    end
                    if isfield(lght, 'to')
                        lght = piLightSet(lght, 'to val', thisR.get('to'));
                    end
                end
                lght = piLightTranslate(lght, 'xshift', xSft,...
                    'yshift', ySft,...
                    'zshift', zSft,...
                    'fromto', fromto,...
                    'up', up);
                thisR.set('asset', lghtName, 'lght', lght);
                return;
            otherwise
                % Probably the light name.
                thisLightAsset = thisR.get('light', lghtName);
                thisLight = thisLightAsset.lght{1};
        end
        
        % At this point we have the light.
        if numel(varargin{1}) == 1
            % thisR.set('light', lghtName, lightStruct);
            % A light struct was sent in as the only argument.  We
            % should check it, make sure its name is unique, and then set
            % it.
            % thisR.lights{lgtIdx} = varargin{1};
            thisR.set('light', lghtName, 'replace', varargin{1});
        else
            % thisR.set('light', lightName, param, val)
            % A light name and property was sent in.  We set the
            % property and then update the material in the list.
            thisLight = piLightSet(thisLight, param, val);
            thisR.set('asset', lghtName, 'lght', thisLight);
        end
        
        
        %{
        % This is the case where we add a list of light
        if isempty(varargin)
            if iscell(val)
                % thisR.lights = val;
                for ii=1:numel(val)
                    % Create new light asset
                    newLightAsset = piAssetCreate('type', 'light');
                    newLightAsset.name = val{ii}.name;
                    newLightAsset.lght{1} = val{ii};
                    thisR.set('asset', 'add', newLightAsset);
                end
            else
                warning('Please provide a list of lights in cell array')
            end
            return;
        end

        % Get index and light struct from light list
        % Search by name or index
        if isnumeric(val) && val <= numel(thisR.lights)
            lgtIdx = val;
            thisLight = thisR.get('light', val);
        elseif isstruct(val)
            % Sent in a struct
            if isfield(val, 'name'), lgtName = val.name;
                % [lgtIdx, thisLight] = piLightFind(thisR.lights, 'name', lgtName);
                thisLight = thisR.get('light', lgtName);
            else
                error('Bad struct.');
            end
        elseif ischar(val)
            % It is either a special command or the light name
            switch val
                case {'add'}
                    newLightAsset = piAssetCreate('type', 'light');
                    newLightAsset.name = val.name;
                    newLightAsset.lght{1} = val;
                    thisR.set('asset', 'add', newLightAsset);
                    %{
                    nLight = thisR.get('n light');
                    thisR.lights{nLight + 1} = varargin{1};
                    %}
                    return;
                case {'delete', 'remove'}
                    % thisR.set('light', 'delete', idxORname);
                    if isnumeric(varargin{1})
                        % thisR.lights(varargin{1}) = [];
                        lgtNames = thisR.get('light', 'names');
                        thisR.set('asset', lgtNames{varargin{1}}, 'delete');
                    elseif isequal(varargin{1}, 'all')
                        lgtNames = thisR.get('light', 'names');
                        for ii=1:numel(lgtNames)
                            thisR.set('asset', lgtNames{ii}, 'delete');
                        end
                    else
                        % Search by name
                        thisR.set('asset', varargin{1}, 'delete');
                        %{
                        [lgtIdx, ~] = piLightFind(thisR.lights, 'name', varargin{1});
                        thisR.lights(lgtIdx) = [];
                        %}
                    end
                    return;
                case {'replace'}
                    thisLgtAsset = thisR.get('light', varargin{1});
                    thisLgtAsset.lght{1} = varargin{2};
                    thisLgtAsset.name = varargin{2}.name;
                    thisR.set('asset', varargin{1}, thisLgtAsset);
                    %{
                    idx = piLightFind(thisR.lights, 'name', varargin{1});
                    thisR.lights{idx} = varargin{2};
                    %}
                    return;
                case {'rotate', 'rotation'}
                    % Rotate the direction, angle in degrees
                    % thisR.set('light', 'rotate', lghtName, [XROT, YROT, ZROT], ORDER)
                    % See piLightRotate
                    lghtAsset = thisR.get('light', varargin{1});
                    lght = lghtAsset.lght{1};
                    
                    % This might not be elegant enough..? (ZLY)
                    % If it has no from field, then the transformation will
                    % be applied to the branch node (for infinite and area light).
                    if ~isfield(lght, 'from')
                        thisR.set('asset', varargin{1}, 'rotate', varargin{2});
                        return;
                    end
                    
                    % Else it has from field, treat it differently.
                    % [lgtIdx, lght] = piLightFind(thisR.lights, 'name', varargin{1});

                    if numel(varargin) == 2
                        xRot = varargin{2}(1);
                        yRot = varargin{2}(2);
                        zRot = varargin{2}(3);
                    end
                    if numel(varargin) == 3
                        order = varargin{3};
                    else
                        order = ['x', 'y', 'z'];
                    end

                    lght = piLightRotate(lght, 'xrot', xRot,...
                        'yrot', yRot,...
                        'zrot', zRot,...
                        'order', order);
                    thisR.set('asset', varargin{1}, 'lght', lght);
                    return;

                case {'translate', 'translation'}
                    % thisR.set('light', 'translate', lghtName, [XSFT, YSFT, ZSFT], FROMTO)
                    % See piLightRotate
                    % [lgtIdx, lght] = piLightFind(thisR.lights, 'name', varargin{1});
                    lghtAsset = thisR.get('light', varargin{1});
                    lght = lghtAsset.lght{1};
                    
                    % If it has no from field, then the transformation will
                    % be applied to the branch node (for infinite and area light).
                    if ~isfield(lght, 'from')
                        thisR.set('asset', varargin{1}, 'translate', varargin{2});
                        return;
                    end
                    
                    if numel(varargin) == 2
                        xSft = varargin{2}(1);
                        ySft = varargin{2}(2);
                        zSft = varargin{2}(3);

                    end
                    if numel(varargin) == 3
                        fromto = varargin{3};
                    else
                        fromto = 'both';
                    end
                    up = thisR.get('up');

                    % If the light is at the same position of camera
                    if lght.cameracoordinate
                        if isfield(lght, 'from')
                            lght = piLightSet(lght, 'from val', thisR.get('from'));
                        end
                        if isfield(lght, 'to')
                            lght = piLightSet(lght, 'to val', thisR.get('to'));
                        end
                    end
                    lght = piLightTranslate(lght, 'xshift', xSft,...
                        'yshift', ySft,...
                        'zshift', zSft,...
                        'fromto', fromto,...
                        'up', up);
                    thisR.set('asset', varargin{1}, 'lght', lght);
                    return;
                    
                otherwise
                    % Probably the light name.
                    lgtName = val;
                    thisLightAsset = thisR.get('light', lgtName);
                    thisLight = thisLightAsset.lght{1};
                    % [lgtIdx, thisLight] = piLightFind(thisR.lights, 'name', lgtName);
            end
        end

        % At this point we have the light.
        if numel(varargin{1}) == 1
            % A light struct was sent in as the only argument.  We
            % should check it, make sure its name is unique, and then set
            % it.
            % thisR.lights{lgtIdx} = varargin{1};
            thisR.set('light', 'replace', lgtName, varargin{1});
        else
            % A light name and property was sent in.  We set the
            % property and then update the material in the list.
            thisLight = piLightSet(thisLight, varargin{1}, varargin{2});
            thisR.set('asset', lgtName, 'lght', thisLight);
        end
        %}
    case {'asset', 'assets','node','nodes'}
        % Typical:    thisR.set(param,val)
        % This case:  thisR.set('asset',assetNameOrID, param, val);
        %          or thisR.set('asset', assetName/assetStruct, action);
        %          or thisR.set('asset', assetName, action, val);
        %
        % These operations need the whole tree, so we send in the
        % recipe that contains the asset tree, thisR.assets.

        % We are slowly starting to call nodes nodes, rather than
        % assets.  We think of an asset now as, say, a car with all of
        % its parts.  A node is the node in a tree that contains
        % multiple assets. (BW, Sept 2021).

        % Given the calling convention, val is assetName and
        % varargin{1} is the param, and varargin{2} is the value, if
        % needed.
        if isnumeric(val)
            % Person sent in an id, so we get the name here
            [id,thisAsset] = piAssetFind(thisR,'id',val);
            if val == 1, assetName = 'root';
            else, assetName = thisAsset{1}.name;
            end
        else
            assetName = val;
            id = thisR.get('asset', assetName, 'id');
        end
        param = varargin{1};
        % If only one element in varargin, it should be a node struct.
        if numel(varargin) == 1 && ~ischar(varargin{1})
            thisR.assets = thisR.assets.set(id, varargin{1});
            out = varargin{1};
            thisR.assets = thisR.assets.uniqueNames;
            return;
        end
        % Else we are setting a parameter value
        if numel(varargin) == 2, val   = varargin{2}; end

        % Some of these functions should be edited to return the new
        % branch.  Some have been.
        switch ieParamFormat(param)
            case 'add'
                % thisR.set('asset',parentName,newAsset);
                out = piAssetAdd(thisR, assetName, val);
            case {'cancellasttransformation', 'removelasttransformation',...
                    'cancellasttrans', 'removelasttrans',...
                    'cancellastaction', 'removelastaction'}
                % Note: this is for transformation only, not
                % motion/animation
                piAssetRemoveLastTrans(thisR, assetName);
            case {'clearmotion', 'removemotion', 'cancelmotion'}
                piAssetSet(thisR, assetName, 'motion', []);
            case {'delete', 'remove'}
                % thisR.set('asset',assetName,'delete');
                piAssetDelete(thisR, assetName);
            case {'insert'}
                % thisR.set('asset',assetName,'insert');
                out = piAssetInsert(thisR, assetName, val);
            case {'parent'}
                % thisR.set('asset',assetName,'parent',id)
                piAssetSetParent(thisR, assetName, val);
            case {'translate', 'translation'}
                % thisR.set('asset',assetName,'translate',val);
                out = piAssetTranslate(thisR, assetName, val);
            case {'worldtranslate', 'worldtranslation'}
                % Translate in world axis orientation.
                rotM = thisR.get('asset', assetName, 'world rotation matrix'); % Get new axis orientation
                % newTrans = inv(rotM) * [reshape(val, numel(val), 1); 0];
                newTrans = rotM \ [reshape(val, numel(val), 1); 0];

                % Get the scale
                worldScale = thisR.get('asset', assetName, 'world scale');
                out = piAssetTranslate(thisR, assetName, newTrans(1:3)./worldScale(:));
            case {'rotate', 'rotation'}
                % Figures out the rotation from the angles in val and sets
                % the rotation matrix
                out = piAssetRotate(thisR, assetName, val);
            case {'rotationmatrix'}
                % Just set the rotation matrix
                % id = piAssetFind(thisR.assets,'name',assetName);
                % Check that val is a rotation matrix
                if size(val) == [4,4]
                    piAssetSet(thisR, assetName, 'rotation',val);
                else
                    error('val must be 4x4 matrix');
                end

                %thisR.assets.Node{id}.rotation = val;
            case {'worldrotate', 'worldrotation'}
                % Get current rotation matrix
                curRotM = thisR.get('asset', assetName, 'world rotation matrix'); % Get new axis orientation
                [~, rotDeg] = piTransformRotationInAbsSpace(val, curRotM);
                %{
                % This section was wrapped in piTransformRotationInAbsSpace.
                newRotM = eye(4);
                % Loop through the three rotation
                for ii=1:numel(val)
                    if ~isequal(val(ii), 0)
                        % Axis in world space
                        axWorld = zeros(4, 1);
                        axWorld(ii) = 1;

                        % Axis orientation in world space
                        % axObj = inv(curRotM) * axWorld;
                        axObj = curRotM \ axWorld;
                        thisAng = val(ii);

                        % Get the rotation matrix in world space
                        thisM = piTransformRotation(axObj, thisAng);
                        newRotM = thisM * newRotM;
                    end
                end
                % Get rotation deg around x, y and z axis in object
                % space.
                rotDeg = piTransformRotM2Degs(newRotM);
                %}
                out = thisR.set('asset', assetName, 'rotate', rotDeg);
            case {'worldposition'}
                % thisR.set('asset', assetName, 'world position', [1 2 3]);
                % First get the position
                pos = thisR.get('asset', assetName, 'world position');

                % Set a translation to (1) cancel the current translation
                % and (2) move the object to the target position
                newTrans = -pos + varargin{2}(:)';

                [~, out] = thisR.set('asset', assetName, 'world translation', newTrans);
            case {'scale'}
                out = piAssetScale(thisR,assetName,val);
            case {'move', 'motion'}
                % varargin{2:end} contains translation and rotation info
                out = piAssetMotionAdd(thisR, assetName, varargin{2:end});
            case {'obj2light'}
                piAssetObject2Light(thisR, assetName, val);
            case {'graft', 'subtreeadd'}
                % thisR.set('asset',nodeForGraft,'graft',subtree);
                id = thisR.get('node', assetName, 'id');
                rootSTID = thisR.assets.nnodes + 1;
                thisR.assets = thisR.assets.graft(id, val);
                thisR.assets = thisR.assets.uniqueNames;
                % Get the root node of the subtree.
                out = thisR.get('asset', rootSTID);
            case {'graftwithmaterial', 'graftwithmaterials'}
                % thisR.set('asset',assetName,'graft with materials',assetFileName)
                [assetTree, matList] = piAssetTreeLoad(val);
                [~,out] = thisR.set('asset', assetName, 'graft', assetTree);
                keyList = keys(matList);
                for ii=1:numel(keyList)
                    thisR.set('material', 'add', matList(keyList{ii}));
                end
            case {'chop', 'cut'}
                id = thisR.get('asset', assetName, 'id');
                thisR.assets = thisR.assets.chop(id);
            otherwise
                % Set a parameter of an asset to val
                % rotation is a parameter, but it is stopped above via the
                % call to rotation matrix.
                piAssetSet(thisR, assetName, varargin{1},val);
        end
        % reassign unique names for delete/chop;
        thisR.assets = thisR.assets.uniqueNames;

        % ZLY added fluorescent sets
    case {'fluorophoreconcentration'}
        % thisR.set('fluorophore concentration',val,idx)
        if isempty(varargin), error('Material name or index required'); end

        % material name
        materialName = varargin{1};

        matName = val; % for older version
        switch thisR.recipeVer
            case 2
                % A modern recipe. So we set using modern methods.  The
                % function reads the fluorophore (fluorophoreRead) and
                % returns the EEM and sets it.  It uses the wavelength
                % sampling in the recipe to determine the EEM wavelength
                % sampling.
                thisR = piMaterialSet(thisR,materialName,'fluorophore concentration',val);

            otherwise
                % This is the original framing, before re-writing the
                % materials.list organization by Zheng.
                disp('Please update to version 2 of the recipe');
                disp('This will be deprecated');
                if ~isfield(thisR.materials.list, matName)
                    error('Unknown material name %s\n', matName);
                end
                thisR.materials.list.(matName).floatconcentration = val;
        end
    case {'fluorophoreeem'}
        % thisR.set('fluorophore eem',val,idx)
        %
        % val - the name of the fluorophore.
        % idx - a numerical index to the material or it can be a string
        % which is the name of the mater
        if isempty(varargin), error('Material name or index required'); end

        % material name
        materialName = varargin{1};

        matName = val;
        switch thisR.recipeVer
            case 2
                % A modern recipe. So we set using modern methods.  The
                % function reads the fluorophore (fluorophoreRead) and
                % returns the EEM and sets it.  It uses the wavelength
                % sampling in the recipe to determine the EEM wavelength
                % sampling.
                thisR = piMaterialSet(thisR,materialName,'fluorophore eem',val);

            otherwise
                % This is the original framing, before re-writing the
                % materials.list organization by Zheng.
                disp('Please update to version 2 of the recipe');
                disp('This will be deprecated');
                if ~isfield(thisR.materials.list, matName)
                    error('Unknown material name %s\n', matName);
                end
                if length(val) == 1
                    error('Donaldson matrix is empty\n');
                end
                if length(varargin) > 2
                    error('Accept only one Donaldson matrix\n');
                end

                fluorophoresName = val{2};
                if isempty(fluorophoresName)
                    thisR.materials.list.(matName).photolumifluorescence = '';
                    thisR.materials.list.(matName).floatconcentration = [];
                else
                    wave = 365:5:705; % By default it is the wavelength range used in pbrt
                    fluorophores = fluorophoreRead(fluorophoresName,'wave',wave);
                    % Here is the excitation emission matrix
                    eem = fluorophoreGet(fluorophores,'eem');
                    %{
                       fluorophorePlot(Porphyrins,'donaldson mesh');
                    %}
                    %{
                       dWave = fluorophoreGet(FAD,'delta wave');
                       wave = fluorophoreGet(FAD,'wave');
                       ex = fluorophoreGet(FAD,'excitation');
                       ieNewGraphWin;
                       plot(wave,sum(eem)/dWave,'k--',wave,ex/max(ex(:)),'r:')
                    %}

                    % The data are converted to a vector like this
                    flatEEM = eem';
                    vec = [wave(1) wave(2)-wave(1) wave(end) flatEEM(:)'];
                    thisR.materials.list.(matName).photolumifluorescence = vec;
                end
        end
    case {'concentration'}
        matName = val{1};
        if ~isfield(thisR.materials.list, matName)
            error('Unknown material name %s\n', matName);
        end
        if length(val) == 1
            error('Concentration is empty\n');
        end
        if length(val) > 2
            error('Accept single number as concentration\n');
        end
        thisR.materials.list.(matName).floatconcentration = val{2};
    case {'rendertype','filmrendertype'}
        thisR.metadata.rendertype = val;
        for ii = 1:numel(val)
            switch val{ii}
                case 'radiance'
                    thisR.film.saveRadiance.type  = 'bool';
                    thisR.film.saveRadiance.value = true;
                    thisR.film.saveRadianceAsBasis.type  = 'bool';
                    thisR.film.saveRadianceAsBasis.value =false;
                case 'radiancebasis'
                    thisR.film.saveRadianceAsBasis.type  = 'bool';
                    thisR.film.saveRadianceAsBasis.value = true;
                    thisR.film.saveRadiance.type  = 'bool';
                    thisR.film.saveRadiance.value = false;
                case 'depth'
                    % depth
                    thisR.film.saveDepth.type  = 'bool';
                    thisR.film.saveDepth.value = true;
                case 'material'
                    thisR.film.saveMaterial.type  = 'bool';
                    thisR.film.saveMaterial.value = true;
                case 'instance'
                    thisR.film.saveInstance.type  = 'bool';
                    thisR.film.saveInstance.value = true;
                case 'illuminance'
                    illumR = piRecipeCopy(thisR);
                    illumR.film.saveRadiance.type  = 'bool';
                    illumR.film.saveRadiance.value = true;
                    illumR.film.saveRadianceAsBasis.type  = 'bool';
                    illumR.film.saveRadianceAsBasis.value =false;
                    % using radiance render type, but modify material
                    matList = keys(illumR.materials.list);
                    for jj = 1: numel(matList)
                        thisMat = illumR.materials.list(matList{jj});
                        thisMat.reflectance.type = 'spectrum';
                        thisMat.reflectance.value = [300 1 800 1];
                        illumR.materials.list(matList{jj}) = thisMat;
                    end

                    [dir, fname, ext]=fileparts(thisR.outputFile);
                    illumR.outputFile = fullfile(dir, [fname,'_illuminance',ext]);
                    thisR.metadata.illuminanceRecipe = illumR;
            end
        end
    otherwise
        error('Unknown parameter %s\n',param);
end

end
