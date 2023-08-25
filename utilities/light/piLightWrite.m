function lightSourceText = piLightWrite(thisR, varargin)
% Write a file with the lights for this recipe
%
% Synopsis
%   piLightWrite(thisR)
%
% Brief description
%  This function writes out the file containing the descriptions of the
%  scene lights for the PBRT scene. The scene_lights file is included by
%  the main scene file.
%
% Input
%   thisR - ISET3d recipe
%
% Optional key/value pairs
%   N/A
%
% Outputs
%   N/A
%
% See also
%  piLightGet

% Examples:
%{
 thisR = piRecipeDefault;
 piLightGet(thisR);
 piWrite(thisR);
 scene = piRender(thisR);
 sceneWindow(scene);
%}

%% parse inputs
varargin = ieParamFormat(varargin);

p = inputParser;
p.addRequired('thisR', @(x)isequal(class(x), 'recipe'));
p.addParameter('writefile', true);
p.parse(thisR, varargin{:});

writefile = p.Results.writefile;

%% Write out light sources one by one
lightSourceText = cell(1, numel(thisR.lights));

%% Check all applicable parameters for every light
for ii = 1:numel(thisR.lights)
    % Why do I need this again?  3rd time today. BW
    % if ~iscell(thisR.lights), thisR.lights = {thisR.lights}; end

    thisLight = thisR.lights{ii};
    
    % Sometimes this parameter is empty.  So we set it to 1.
    spectrumScale = piLightGet(thisLight, 'specscale val');
    if isempty(spectrumScale), spectrumScale = 1; end
    % scaleTxt = sprintf('"float scale" %f',spectrumScale);    

    %% Write out lightspectrum to the file if the data is from file
    specVal = piLightGet(thisLight, 'spd val');
    if ~isempty(specVal)
        if ischar(specVal)
            [~,~,ext] = fileparts(specVal);
            if isequal(ext,'.spd')
                % User has a local file that will be copied
            else
                % Read the mat file.  Should have a mat extension.
                % This is the wavelength hardcoded in PBRT
                wavelength = 365:5:705;
                if isequal(ext,'.mat') || isempty(ext)
                    data = ieReadSpectra(specVal, wavelength, 0);
                else
                    error('Light extension seems wrong: %s\n',ext);
                end

                % Saving the light information in the spd sub-directory
                outputDir = thisR.get('output dir');
                lightSpdDir = fullfile(outputDir, 'spds', 'lights');

                thisLightfile = fullfile(lightSpdDir,...
                    sprintf('%s.spd', ieParamFormat(specVal)));
                if ~exist(lightSpdDir, 'dir'), mkdir(lightSpdDir); end

                fid = fopen(thisLightfile, 'w');
                for jj = 1: length(data)
                    fprintf(fid, '%d %d \n', wavelength(jj), data(jj));
                end
                fclose(fid);

            end
        elseif isnumeric(specVal)
            % Numeric.  Do nothing
        else
            % Not numeric or char but not empty.  So, something wrong.
            error('Incorrect light spectrum.');
        end
    end

    %% Construct a lightsource structure
    % Different types of lights that we know how to add.
    type = piLightGet(thisLight, 'type');

    % We would use attributeBegin/attributeEnd for all cases
    lightSourceText{ii}.line{1} = 'AttributeBegin';


    switch type
        case 'point'
            % Whether coordinate at camera pos
            if thisLight.cameracoordinate
                lightSourceText{ii}.line{end + 1} = 'CoordSysTransform "camera"';
            end

            % First check if there is any rotation, translation or
            % concatransformation
            transTxt = piLightGenerateTransformText(thisLight);
            lightSourceText{ii}.line = [lightSourceText{ii}.line transTxt];

            % Construct the light definition line
            [~, lghtDef] = piLightGet(thisLight, 'type', 'pbrt text', true);

            % spectrum
            [~, spdTxt] = piLightGet(thisLight, 'spd val', 'pbrt text', true);
            if ~isempty(spdTxt)
                lghtDef = strcat(lghtDef, spdTxt);
            end

            % From
            [~, fromTxt] = piLightGet(thisLight, 'from val', 'pbrt text', true);
            if ~isempty(fromTxt)
                lghtDef = strcat(lghtDef, fromTxt);
            end
            % scale
            [~, specscaleTxt] = piLightGet(thisLight, 'specscale val', 'pbrt text', true);
            if ~isempty(specscaleTxt)
                lghtDef = strcat(lghtDef, specscaleTxt);
            end
            
            lightSourceText{ii}.line = [lightSourceText{ii}.line lghtDef];

        case 'distant'
            % Whether coordinate at camera pos
            if thisLight.cameracoordinate
                lightSourceText{ii}.line{end + 1} = 'CoordSysTransform "camera"';
            end

            % First check if there is any rotation, translation or
            % concatransformation
            transTxt = piLightGenerateTransformText(thisLight);
            lightSourceText{ii}.line = [lightSourceText{ii}.line transTxt];

            % Construct the light definition line
            [~, lghtDef] = piLightGet(thisLight, 'type', 'pbrt text', true);
            [~, spdTxt] = piLightGet(thisLight, 'spd val', 'pbrt text', true);
            lghtDef = strcat(lghtDef, spdTxt);
            % lghtDef = sprintf('LightSource "distant" "%s L" %s', spectrumType, lightSpectrum);

            % From
            [~, fromTxt] = piLightGet(thisLight, 'from val', 'pbrt text', true);
            if ~isempty(fromTxt)
                lghtDef = strcat(lghtDef, fromTxt);
            end

            % To
            [~, toTxt] = piLightGet(thisLight, 'to val', 'pbrt text', true);
            if ~isempty(toTxt)
                lghtDef = strcat(lghtDef, toTxt);
            end
            % scale
            [~, specscaleTxt] = piLightGet(thisLight, 'specscale val', 'pbrt text', true);
            if ~isempty(specscaleTxt)
                lghtDef = strcat(lghtDef, specscaleTxt);
            end
            
            lightSourceText{ii}.line = [lightSourceText{ii}.line lghtDef];


        case 'goniometric'

            % Whether coordinate at camera pos
            if thisLight.cameracoordinate
                lightSourceText{ii}.line{end + 1} = 'CoordSysTransform "camera"';
            end

            % First check if there is any rotation, translation or
            % concatransformation
            transTxt = piLightGenerateTransformText(thisLight);
            lightSourceText{ii}.line = [lightSourceText{ii}.line transTxt];

            % Construct the light definition line
            [~, lghtDef] = piLightGet(thisLight, 'type', 'pbrt text', true);

            % spectrum
            [~, spdTxt] = piLightGet(thisLight, 'spd val', 'pbrt text', true);
            if ~isempty(spdTxt)
                lghtDef = strcat(lghtDef, spdTxt);
            end

            % mapname
            [~, mapnameTxt] = piLightGet(thisLight, 'filename val', 'pbrt text', true);
            if ~isempty(mapnameTxt)
                lghtDef = strcat(lghtDef, mapnameTxt);
            end
            % scale
            [~, specscaleTxt] = piLightGet(thisLight, 'specscale val', 'pbrt text', true);
            if ~isempty(specscaleTxt)
                lghtDef = strcat(lghtDef, specscaleTxt);
            end

            lightSourceText{ii}.line = [lightSourceText{ii}.line lghtDef];

            % We keep the goniometric maps in the root directory for now
            fname = thisLight.filename.value;
            if ~isfile(fullfile(thisR.get('output dir'),'skymaps',fname))
                % Look for it in the skymaps directory
                gonioFile = fullfile(piDirGet('skymaps'),fname);                
                if isfile(gonioFile)
                    gonioDir = fullfile(thisR.get('output dir'),'skymaps');
                    if ~isfolder(gonioDir), mkdir(gonioDir); end
                    copyfile(gonioFile,gonioDir);
                    fprintf('Copying goniometric light file from skymaps directory. %s\n',gonioFile);
                else
                    warning('Could not find the goniometric light file %s\n',fname)
                end
            end

        case 'infinite'
            % First check if there is any rotation, translation or
            % concatransformation
            transTxt = piLightGenerateTransformText(thisLight);
            lightSourceText{ii}.line = [lightSourceText{ii}.line transTxt];

            % Construct the light definition line
            [~, lghtDef] = piLightGet(thisLight, 'type', 'pbrt text', true);

            if isempty(thisLight.filename.value)
                % spectrum
                [~, spdTxt] = piLightGet(thisLight, 'spd val', 'pbrt text', true);
                if ~isempty(spdTxt)
                    lghtDef = strcat(lghtDef, spdTxt);
                end
            else
                % V4 uses filename.  (We used to use mapname.)
                [mapName, mapnameTxt] = piLightGet(thisLight, 'filename val', 'pbrt text', true);
                if ~isempty(mapnameTxt)
                    lghtDef = strcat(lghtDef, mapnameTxt);

                    if ~exist(fullfile(thisR.get('output dir'),'skymaps',mapName),'file')
                        % mapFile = which(mapName);
                        mapFile = fullfile(piDirGet('skymaps'),mapName);
                        if isfile(mapFile)
                            skymapDir = [thisR.get('output dir'),filesep,'skymaps'];
                            if ~isfolder(skymapDir), mkdir(skymapDir); end
                            copyfile(mapFile,skymapDir);
                        end
                    end
                end
            end

            % lghtDef = sprintf('LightSource "infinite" "%s L" %s', spectrumType, lightSpectrum);

            % nsamples
            [~, nsamplesTxt] = piLightGet(thisLight, 'nsamples val', 'pbrt text', true);
            if ~isempty(nsamplesTxt)
                lghtDef = strcat(lghtDef, nsamplesTxt);
            end

            % scale
            [~, specscaleTxt] = piLightGet(thisLight, 'specscale val', 'pbrt text', true);
            if ~isempty(specscaleTxt)
                lghtDef = strcat(lghtDef, specscaleTxt);
            end
            lightSourceText{ii}.line = [lightSourceText{ii}.line lghtDef];

        case 'projection'

            % Whether coordinate at camera pos
            if thisLight.cameracoordinate
                lightSourceText{ii}.line{end + 1} = 'CoordSysTransform "camera"';
            end

            % First check if there is any rotation, translation or
            % concatransformation
            transTxt = piLightGenerateTransformText(thisLight);
            lightSourceText{ii}.line = [lightSourceText{ii}.line transTxt];

            % Construct the light definition line
            [~, lghtDef] = piLightGet(thisLight, 'type', 'pbrt text', true);

            % filename -- used to be mapname -- this is our projected image
            [~, filenameTxt] = piLightGet(thisLight, 'filename val', 'pbrt text', true);
            if ~isempty(filenameTxt)
                lghtDef = strcat(lghtDef, filenameTxt);
            end

            % fov
            [~, fovTxt] = piLightGet(thisLight, 'fov val', 'pbrt text', true);
            if ~isempty(fovTxt)
                lghtDef = strcat(lghtDef, fovTxt);
            end

            % power
            [~, powerTxt] = piLightGet(thisLight, 'power val', 'pbrt text', true);
            if ~isempty(powerTxt)
                lghtDef = strcat(lghtDef, powerTxt);
            end

            % scale
            [~, scaleTxt] = piLightGet(thisLight, 'scale val', 'pbrt text', true);
            if ~isempty(scaleTxt)
                lghtDef = strcat(lghtDef, scaleTxt);
            end

            lightSourceText{ii}.line = [lightSourceText{ii}.line lghtDef];

        case {'spot', 'spotlight'}
            % Whether coordinate at camera pos
            if thisLight.cameracoordinate
                lightSourceText{ii}.line{end + 1} = 'CoordSysTransform "camera"';
            end

            % First check if there is any rotation, translation or
            % concatransformation
            transTxt = piLightGenerateTransformText(thisLight);
            lightSourceText{ii}.line = [lightSourceText{ii}.line transTxt];

            % Construct the light definition line
            [~, lghtDef] = piLightGet(thisLight, 'type', 'pbrt text', true);

            % spectrum
            [~, spdTxt] = piLightGet(thisLight, 'spd val', 'pbrt text', true);
            if ~isempty(spdTxt)
                lghtDef = strcat(lghtDef, spdTxt);
            end

            % From
            [~, fromTxt] = piLightGet(thisLight, 'from val', 'pbrt text', true);
            if ~isempty(fromTxt)
                lghtDef = strcat(lghtDef, fromTxt);
            end

            % To
            [~, toTxt] = piLightGet(thisLight, 'to val', 'pbrt text', true);
            if ~isempty(toTxt)
                lghtDef = strcat(lghtDef, toTxt);
            end

            % Cone angle
            [~, coneangleTxt] = piLightGet(thisLight, 'coneangle val', 'pbrt text', true);
            if ~isempty(coneangleTxt)
                lghtDef = strcat(lghtDef, coneangleTxt);
            end

            % Cone delta angle
            [~, conedeltaangleTxt] = piLightGet(thisLight, 'conedeltaangle val', 'pbrt text', true);
            if ~isempty(conedeltaangleTxt)
                lghtDef = strcat(lghtDef, conedeltaangleTxt);
            end

            % scale
            [~, specscaleTxt] = piLightGet(thisLight, 'specscale val', 'pbrt text', true);
            if ~isempty(specscaleTxt)
                lghtDef = strcat(lghtDef, specscaleTxt);
            end
            
            lightSourceText{ii}.line = [lightSourceText{ii}.line lghtDef];


        case 'area'
            %
            % First check if there is any rotation, translation or
            % concatransformation
            % Also, area lights can have a shape.
            %
            transTxt = piLightGenerateTransformText(thisLight);
            lightSourceText{ii}.line = [lightSourceText{ii}.line transTxt];

            % Construct the light definition line
            [~, lghtDef] = piLightGet(thisLight, 'type', 'pbrt text', true);

            % spectrum
            [~, spdTxt] = piLightGet(thisLight, 'spd val', 'pbrt text', true);
            if ~isempty(spdTxt)
                lghtDef = strcat(lghtDef, spdTxt);
            end
            % lghtDef = sprintf('AreaLightSource "diffuse" "%s L" %s', spectrumType, lightSpectrum);

            % lightSourceText{ii}.line = [lightSourceText{ii}.line lghtDef];
            %
            % if thisLight.ReverseOrientation.value==true
            %     rOTxt = 'ReverseOrientation';
            %     lightSourceText{ii}.line = [lightSourceText{ii}.line rOTxt];

            % nsamples
            [~, nsamplesTxt] = piLightGet(thisLight, 'nsamples val', 'pbrt text', true);
            if ~isempty(nsamplesTxt)
                lghtDef = strcat(lghtDef, nsamplesTxt);
            end

            % scale
            [~, specscaleTxt] = piLightGet(thisLight, 'specscale val', 'pbrt text', true);
            if ~isempty(specscaleTxt)
                lghtDef = strcat(lghtDef, specscaleTxt);
            end

                        % scale
            [~, spreadTxt] = piLightGet(thisLight, 'spread val', 'pbrt text', true);
            if ~isempty(spreadTxt)
                lghtDef = strcat(lghtDef, spreadTxt);
            end

            % twosided
            [~, twosidedTxt] = piLightGet(thisLight, 'twosided val', 'pbrt text', true);
            if ~isempty(twosidedTxt)
                lghtDef = strcat(lghtDef, twosidedTxt);
            end

            % lghtDef = sprintf("%s %s",lghtDef, scaleTxt);
            %
            % This is what it used to be
            % lightSourceText{ii}.line = [lightSourceText{ii}.line sprintf("%s %s",lghtDef, scaleTxt) shpTxt ];
            %
            lightSourceText{ii}.line = [lightSourceText{ii}.line lghtDef];

            % Attach shape            
            for nshape = 1:numel(thisLight.shape) % allow multiple shape
                if ~iscell(thisLight.shape)
                    dummylight.shape = thisLight.shape;
                else
                    dummylight.shape = thisLight.shape{nshape};
                end
                if isfield(dummylight.shape,'value')
                    [~, shpTxt] = piLightGet(dummylight, 'shape val', 'pbrt text', true);
                else
                    [~, shpTxt] = piLightGet(dummylight, 'shape struct', 'pbrt text', true);
                end
                
                lightSourceText{ii}.line = [lightSourceText{ii}.line shpTxt];
            end
    end
    lightSourceText{ii}.line{end+1} = 'AttributeEnd';

end



if writefile
    %% Write to scene_lights.pbrt file
    [workingDir, n] = fileparts(thisR.outputFile);
    fname_lights = fullfile(workingDir, sprintf('%s_lights.pbrt', n));

    fid = fopen(fname_lights, 'w');
    fprintf(fid, '# Exported by piLightWrite on %i/%i/%i %i:%i:%0.2f \n',clock);

    for ii = 1:numel(lightSourceText)
        for jj = 1:numel(lightSourceText{ii}.line)
            fprintf(fid, '%s \n',lightSourceText{ii}.line{jj});
        end
        fprintf(fid,'\n');
    end
    fclose(fid);
end
end
