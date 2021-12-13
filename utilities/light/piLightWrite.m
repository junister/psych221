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
    thisLight = thisR.lights{ii};
    spectrumScale = piLightGet(thisLight, 'specscale val');
    scaleTxt = sprintf('"float scale" %f',spectrumScale);
    %% Write out lightspectrum to the file if the data is from file
    specVal = piLightGet(thisLight, 'spd val');
    if ~isempty(specVal)
        if ischar(specVal)
            [~,~,ext] = fileparts(specVal);
            outputDir = thisR.get('output dir');
            if isequal(ext,'.spd')
                % User has a local file that will be copied
                thisLightfile = fullfile(outputDir,specVal);
                spds = textread(thisLightfile);
                wavelength = spds(:,1);
                data = spds(:,2);
            else
                % Read the mat file.  Should have a mat extension.
                % This is the wavelength hardcoded in PBRT
                wavelength = 365:5:705;
                if isequal(ext,'.mat') || isempty(ext)
                    data = ieReadSpectra(specVal, wavelength, 0);
                else
                    error('Light extension seems wrong: %s\n',ext);
                end
                lightSpdDir = fullfile(outputDir, 'spds', 'lights');
                thisLightfile = fullfile(lightSpdDir,...
                    sprintf('%s_%f.spd', specVal, spectrumScale));
                if ~exist(lightSpdDir, 'dir'), mkdir(lightSpdDir); end
            end
            % Saving the light information in the spd sub-directory
            fid = fopen(thisLightfile, 'w');
            for jj = 1: length(data)
                fprintf(fid, '%f %.7f \n', wavelength(jj), data(jj)*spectrumScale);
            end
            fclose(fid);
            
            
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
            
            lghtDef = sprintf("%s %s",lghtDef, scaleTxt);
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
            lghtDef = sprintf("%s %s",lghtDef, scaleTxt);
            lightSourceText{ii}.line = [lightSourceText{ii}.line lghtDef];
            
            
        case 'goniometric'
            % Construct the light definition line
            [~, lghtDef] = piLightGet(thisLight, 'type', 'pbrt text', true);
            
            % spectrum
            [~, spdTxt] = piLightGet(thisLight, 'spd val', 'pbrt text', true);
            if ~isempty(spdTxt)
                lghtDef = strcat(lghtDef, spdTxt);
            end
            
            % mapname
            [~, mapnameTxt] = piLightGet(thisLight, 'mapname val', 'pbrt text', true);
            if ~isempty(mapnameTxt)
                lghtDef = strcat(lghtDef, mapnameTxt);
            end
            
            lghtDef = sprintf("%s %s",lghtDef, scaleTxt);
            lightSourceText{ii}.line = [lightSourceText{ii}.line lghtDef];
            
        case 'infinite'
            % First check if there is any rotation, translation or
            % concatransformation
            transTxt = piLightGenerateTransformText(thisLight);
            lightSourceText{ii}.line = [lightSourceText{ii}.line transTxt];
            
            % Construct the light definition line
            [~, lghtDef] = piLightGet(thisLight, 'type', 'pbrt text', true);
            
            if isempty(thisLight.mapname.value)
                % spectrum
                [~, spdTxt] = piLightGet(thisLight, 'spd val', 'pbrt text', true);
                if ~isempty(spdTxt)
                    lghtDef = strcat(lghtDef, spdTxt);
                end
            else
                % mapname
                [mapName, mapnameTxt] = piLightGet(thisLight, 'mapname val', 'pbrt text', true);
                if ~isempty(mapnameTxt)
                    lghtDef = strcat(lghtDef, mapnameTxt);
                    
                    if ~exist(fullfile(thisR.get('output dir'),mapName),'file')
                        mapFile = which(mapName);
                        if ~isempty(mapFile)
                            copyfile(mapFile,thisR.get('output dir'));
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
            
            
            
            lghtDef = sprintf("%s %s",lghtDef, scaleTxt);
            lightSourceText{ii}.line = [lightSourceText{ii}.line lghtDef];
            
        case 'projection'
            % Construct the light definition line
            [~, lghtDef] = piLightGet(thisLight, 'type', 'pbrt text', true);
            
            % spectrum
            [~, spdTxt] = piLightGet(thisLight, 'spd val', 'pbrt text', true);
            if ~isempty(spdTxt)
                lghtDef = strcat(lghtDef, spdTxt);
            end
            
            % mapname
            [~, mapnameTxt] = piLightGet(thisLight, 'mapname val', 'pbrt text', true);
            if ~isempty(mapnameTxt)
                lghtDef = strcat(lghtDef, mapnameTxt);
            end
            
            % fov
            [~, fovTxt] = piLightGet(thisLight, 'fov val', 'pbrt text', true);
            if ~isempty(fovTxt)
                lghtDef = strcat(lghtDef, fovTxt);
            end
            
            lghtDef = sprintf("%s %s",lghtDef, scaleTxt);
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
            
            lghtDef = sprintf("%s %s",lghtDef, scaleTxt);
            lightSourceText{ii}.line = [lightSourceText{ii}.line lghtDef];
            
            
        case 'area'
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

            
%             lightSourceText{ii}.line = [lightSourceText{ii}.line lghtDef];
            if thisLight.ReverseOrientation.value==true
                rOTxt = 'ReverseOrientation';
                lightSourceText{ii}.line = [lightSourceText{ii}.line rOTxt];
            end
            % Attach shape
            if isfield(thisLight.shape,'value')
                [~, shpTxt] = piLightGet(thisLight, 'shape val', 'pbrt text', true);
            else
                [~, shpTxt] = piLightGet(thisLight, 'shape struct', 'pbrt text', true);
            end

%             lghtDef = sprintf("%s %s",lghtDef, scaleTxt);
            lightSourceText{ii}.line = [lightSourceText{ii}.line sprintf("%s %s",lghtDef, scaleTxt) shpTxt ];
            
            
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