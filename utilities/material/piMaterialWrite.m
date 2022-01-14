function piMaterialWrite(thisR)
%%
% Synopsis:
%   piMaterialWrite(thisR)
%
% Brief description:
%   Write material and texture information in material pbrt file.
%
% Inputs:
%   thisR   - recipe.
%
% Outputs:
%   None
%
% Description:
%   Write the material file from PBRT V3, as input from Cinema 4D
%
%   The main scene file (scene.pbrt) includes a scene_materials.pbrt
%   file.  This routine writes out the materials file from the
%   information in the recipe.
%
% ZL, SCIEN STANFORD, 2018
% ZLY, SCIEN STANFORD, 2020

%%
p = inputParser;
p.addRequired('thisR',@(x)isequal(class(x),'recipe'));
p.parse(thisR);

%% Create txtLines for texture struct array
% Texture txt lines creation are moved into piTextureText function.

if isfield(thisR.textures,'list') && ~isempty(thisR.textures.list)
%     textureTxt = cell(1, thisR.textures.list.Count);
    textureKeys = keys(thisR.textures.list);
    tt = 1;
    nn = 1;
    TextureTex = [];
    textureTxt = [];
    for ii = 1:numel(textureKeys)
        tmpTxt = piTextureText(thisR.textures.list(textureKeys{ii}), thisR);
        if piContains(tmpTxt,'texture tex')
            % This texture has a property defined by another texture
            TextureTex{tt} = tmpTxt;
            tt=tt+1;
        else
            textureTxt{nn} = tmpTxt;
            nn=nn+1;
        end
    end
    % ZLY: if special texture cases exist, append them to the end
    if numel(TextureTex) > 0
        textureTxt(nn:nn+numel(TextureTex)-1) = TextureTex;
    end
else
    textureTxt = {};
end

%% Create txtLines for the material struct array
if isfield(thisR.materials, 'list') && ~isempty(thisR.materials.list)
    materialTxt = cell(1, thisR.materials.list.Count);
    materialKeys= keys(thisR.materials.list);
    for ii=1:length(materialTxt)
        % Converts the material struct to text
        materialTxt{ii} = piMaterialText(thisR.materials.list(materialKeys{ii}));
    end
else
    materialTxt{1} = '';
end

% check mix material, make sure mix material reference the material after the definition
mixMatIndex = piContains(materialTxt,'mix');
mixMaterialText = materialTxt(mixMatIndex);
nonMixMaterialText = materialTxt(~mixMatIndex);

%% Write to scene_material.pbrt texture-material file
output = thisR.get('materials output file');
fileID = fopen(output,'w');
fprintf(fileID,'# Exported by piMaterialWrite on %i/%i/%i %i:%i:%0.2f \n',clock);

if ~isempty(textureTxt)
    % Add textures
    for row=1:length(textureTxt)
        fprintf(fileID,'%s\n',textureTxt{row});
    end
end

% write out nonMix materials first
for row=1:length(nonMixMaterialText)
    fprintf(fileID,'%s\n',nonMixMaterialText{row});
end
% write out mix materials
for row=1:length(mixMaterialText)
    fprintf(fileID,'%s\n',mixMaterialText{row});
end

%% Write media to xxx_materials.pbrt

if ~isempty(thisR.media)
    for m=1:length(thisR.media.list)
        fprintf(fileID, piMediumText(thisR.media.list(m), thisR.get('working directory')));
    end
end


fclose(fileID);

[~,n,e] = fileparts(output);
%fprintf('Material file %s written successfully.\n', [n,e]);

end


%% function that converts the struct to text
function val = piMediumText(medium, workDir)
% For each type of material, we have a method to write a line in the
% material file.
%

val_name = sprintf('MakeNamedMedium "%s" ',medium.name);
val = val_name;
val_string = sprintf(' "string type" "%s" ',medium.type);
val = strcat(val, val_string);

resDir = fullfile(fullfile(workDir,'spds'));
if ~exist(resDir,'dir')
    mkdir(resDir);
end

if ~isempty(medium.absFile)
    fid = fopen(fullfile(resDir,sprintf('%s_abs.spd',medium.name)),'w');
    fprintf(fid,'%s',medium.absFile);
    fclose(fid);

    val_floatindex = sprintf(' "string absFile" "spds/%s_abs.spd"',medium.name);
    val = strcat(val, val_floatindex);
end

if ~isempty(medium.vsfFile)
    fid = fopen(fullfile(resDir,sprintf('%s_vsf.spd',medium.name)),'w');
    fprintf(fid,'%s',medium.vsfFile);
    fclose(fid);

    val_floatindex = sprintf(' "string vsfFile" "spds/%s_vsf.spd"',medium.name);
    val = strcat(val, val_floatindex);
end


end
