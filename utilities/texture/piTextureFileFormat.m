function thisR = piTextureFileFormat(thisR)
% Convert textures to PNG format.
%     thisR = piTextureFileFormat(thisR)
%
% Brief description:
%   We convert any texture files used in the scene to PNG format.
%
% Inputs:
%   thisR: render recipe.
%
% Outputs:
%   thisR: render recipe with updated textures.
%
%
% Note (Zhenyi): There is a weird case for me, when I use a JPG texture, the
%                PBRT runs without error, however the surface reflection
%                which used a JPG texture is missing.
%
% ZL Scien Stanford, 2022
%%
textureList = values(thisR.textures.list);

inputDir = thisR.get('input dir');

for ii = 1:numel(textureList)
    
    if ~isfield(textureList{ii},'filename')
        continue;
    end
    [path, name, ext] = fileparts(textureList{ii}.filename.value);
    texSlotName = textureList{ii}.filename.value;
    thisImgPath = fullfile(inputDir, texSlotName);

    if isempty(find(strcmp(ext, {'.png','.PNG','.exr'}),1))
        if exist(thisImgPath, 'file')
            
            outputPath = fullfile(inputDir, path, [name,'.png']);
            
            if ~exist(outputPath,'file')
                thisImg = imread(thisImgPath);
                imwrite(thisImg,outputPath);
            end
            
            % update texture slot
            textureList{ii}.filename.value = fullfile(path, [name,'.png']);
            thisR.textures.list(textureList{ii}.name) = textureList{ii};
            
            fprintf('Texture: %s is converted \n',textureList{ii}.filename.value);
            
            % remove the original jpg textures.
            %             delete(thisImgPath);
        else
            warning('Texture: %s is missing',textureList{ii}.filename.value);
        end
    end
    
    % convert RGB to alpha map
    if contains(textureList{ii}.name,{'tex_','.alphamap.'}) && ...
            exist(fullfile(inputDir, texSlotName),'file')
        
        outputPath = fullfile(inputDir, path, [name,'_alphamap.png']);
        thisImg = imread(thisImgPath);
        thisImg = thisImg(:,:,1);
        thisImg(thisImg~=0)=255;
        imwrite(thisImg,outputPath);
        textureList{ii}.filename.value = fullfile(path, [name,'_alphamap.png']);
        thisR.textures.list(textureList{ii}.name) = textureList{ii};
        
        fprintf('Texture: %s is converted \n',textureList{ii}.filename.value);
    end
end

% Update normal textures
matKeys = keys(thisR.materials.list);

for ii = 1:numel(matKeys)
    thisMat = thisR.materials.list(matKeys{ii});
    thisMat.normalmap.type = 'string';
    normalImgPath = thisMat.normalmap.value;
    thisImgPath = fullfile(inputDir, normalImgPath);
    
    if isempty(normalImgPath)
        continue;
    end
    
    if exist(thisImgPath, 'file') && ~isempty(normalImgPath)
        
        [path, name, ext] = fileparts(dockerWrapper.pathToLinux(normalImgPath));
        
        thisImg = imread(thisImgPath);
        outputPath = fullfile(inputDir, path, [name,'.png']);
        
        imwrite(thisImg,outputPath);
        % update texture slot
        % This is a problem if we are running on Windows and
        % rendering on Linux
        if ispc
            thisMat.normalmap.value = dockerWrapper.pathToLinux(fullfile(path, [name,'.png']));
        else
            thisMat.normalmap.value = fullfile(path, [name,'.png']);
        end
        thisR.materials.list(matKeys{ii}) = thisMat;
        
        fprintf('Normal Map: %s is converted \n',normalImgPath);
        
        % remove the original jpg textures.
        %         delete(thisImgPath);
    else
        warning('Normal Map: %s is missing',normalImgPath);
    end
    
end


end
