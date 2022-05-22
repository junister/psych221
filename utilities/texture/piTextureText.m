function val = piTextureText(texture, thisR, varargin)
% Compose text for textures
%
% Input:
%   texture - texture struct
%
% Outputs:
%   val     - text
%
% ZLY, 2021
%
% See also

%% Parse input
p = inputParser;
p.addRequired('texture', @isstruct);
p.addRequired('thisR', @(x)(isa(x,'recipe')));
p.parse(texture, thisR, varargin{:});

%% Concatenate string
% Name
if ~strcmp(texture.name, '')
    valName = sprintf('Texture "%s" ', texture.name);
else
    error('Bad texture structure')
end

% format
formTxt = sprintf(' "%s" ', texture.format);
val = strcat(valName, formTxt);

% type
tyTxt = sprintf(' "%s" ', texture.type);
val = strcat(val, tyTxt);

%% For each field that is not empty, concatenate it to the text line
textureParams = fieldnames(texture);

for ii=1:numel(textureParams)
    if ~isequal(textureParams{ii}, 'name') && ...
            ~isequal(textureParams{ii}, 'type') && ...
            ~isequal(textureParams{ii}, 'format') && ...
            ~isempty(texture.(textureParams{ii}).value)
         thisType = texture.(textureParams{ii}).type;
         thisVal = texture.(textureParams{ii}).value;

         if ischar(thisVal)
             thisText = sprintf(' "%s %s" "%s" ',...
                 thisType, textureParams{ii}, thisVal);
         elseif isnumeric(thisVal)
            if isinteger(thisType)
                thisText = sprintf(' "%s %s" [%s] ',...
                     thisType, textureParams{ii}, num2str(thisVal, '%d'));
            else
                thisText = sprintf(' "%s %s" [%s] ',...
                     thisType, textureParams{ii}, num2str(thisVal, '%.4f '));
            end
         end

         % val = strcat(val, thisText);

         if isequal(textureParams{ii}, 'filename')
            if ~exist(fullfile(thisR.get('output dir'),thisVal),'file')
                % PBRT V4 files from Matt had references to
                % ../landscape/mumble ... For the barcelona-pavillion
                % I copied the files.  But this may happen again.
                % Very annoying that one scene refers to textures and
                % geometry from a completely different scene.  This is
                % a hack, but probably I should fix the original scene
                % directories. I am worried how often this happens. (BW)


                % See if we can find the file.
                [p,n,e] = fileparts(thisVal);
                if ~isequal('textures',p)
                    % Do we have the file in textures?
                    thisVal = fullfile(thisR.get('output dir'),'textures',[n,e]);
                    if exist(thisVal,'file')
                        imgFile = thisVal;
                        warning('Texture file found, but not in specified directory.');
                    else
                        % impatient "fix" by DJC
                        imgFile = which([n e]);
                        % force it
                    end
                else
                    % See if it is in the root of the scene directory.
                    imgFile = which(thisVal);
                    if ~isempty(imgFile)
                        if ~isequal(fileparts(imgFile),thisR.get('input dir'))
                            error('Can not find the file %s',thisVal);
                        end
                    end
                end

                if isempty(imgFile) || isequal(imgFile,'')
                    thisText = '';
                    val = strrep(val,'imagemap', 'constant');
                    val = strcat(val, ' "rgb value" [0.7 0.7 0.7]');
                    warning('Texture %s not found! Changing it to difuse', thisVal);
                else
                    if ispc % try to fix filename for the Linux docker container                        
                        imgFile = dockerWrapper.pathToLinux(imgFile);
                    end
                    
                    % In the future we might want to copy the texture files
                    % into a folder.
                    % thisText = strrep(thisText,thisVal, imgFile);
                    % piTextureFileFormat(imgFile);
                    % copyfile(imgFile,thisR.get('output dir'));
                end
            end
         end
         val = strcat(val, thisText);

    end
end
