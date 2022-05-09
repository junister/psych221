function [newMat, materialpresetsList] = piMaterialPresets(keyword,materialName)
% We create a library of material presets
% 
% Syntax: 
%    [newMat, materialpresetsList] = piMaterialPresets(keyword,materialName)
%
% Brief description
%    Return material (some with textures) with keyword.
%
% Inputs:
%    keyword      - Material preset name
%    materialName - Material name which is used to create new material.
% 
% Outputs:
%    newMat              - Material and a list of textures if used.
%    materialpresetsList - Avaliable material presets.
%
% Example:
%{
    % print out material presets names
    piMaterialPresets('listmaterial');
    % create material
    [new_material, ~] = piMaterialPresets('glass','material_demo');
%}
%    
%
% Zhenyi, 2022
keyword = ieParamFormat(keyword);
materialpresetsList ={'glass','glass-BK7','glass-BAF10','glass-LASF9','glass-F5','glass-F10','glass-F11'...
    'metal-Ag','metal-Al','metal-Au','metal-Cu','metal-CuZn','metal-MgO','metal-TiO2',...
    'red-glass', 'tire','rough-metal','metal-spotty-discoloration','wood-floor-merbau',...
    'fabric-leather-var1','fabric-leather-var2','fabric-leather-var3'};

addpath(genpath(fullfile(piRootPath,'data/material')));

switch keyword
    case 'glass'
        newMat.material = piMaterialCreate(materialName,'type',...
            'dielectric','roughness',0);
    case 'red-glass'
        newMat_glass = piMaterialCreate([materialName, '_mix_glass'], ...
            'type', 'dielectric','eta','glass-BK7');
        newMat_reflectance = piMaterialCreate([materialName, '_mix_reflectance'], ...
            'type', 'coateddiffuse',...
            'reflectance', [ 0.99 0.01 0.01 ], ...
            'roughness',0);
        mixMatString{1} = [materialName, '_mix_glass'];
        mixMatString{2} = [materialName, '_mix_reflectance'];
        newMat.material = piMaterialCreate(materialName,...
            'type','mix',...
            'amount',0.2,...
            'materials',mixMatString);
        
        newMat.mixMat{1} = newMat_glass;
        newMat.mixMat{2} = newMat_reflectance;

    case 'glass-bk7'
        newMat.material = piMaterialCreate(materialName,...
            'type','dielectric',...
            'roughness',0,'eta','glass-BK7');

    case 'glass-baf10'
        newMat.material = piMaterialCreate(materialName,...
            'type','dielectric',...
            'roughness',0,'eta','glass-BAF10');

    case 'glass-fk51a'
        newMat.material = piMaterialCreate(materialName,...
            'type','dielectric',...
            'roughness',0,'eta','glass-FK51A');

    case 'glass-lasf9'
        newMat.material = piMaterialCreate(materialName,...
            'type','dielectric',...
            'roughness',0,'eta','glass-LASF9');

    case 'glass-f5'
        newMat.material = piMaterialCreate(materialName,...
            'type','dielectric',...
            'roughness',0,'eta','glass-F5');

    case 'glass-f10'
        newMat.material = piMaterialCreate(materialName,...
            'type','dielectric',...
            'roughness',0,'eta','glass-F10');
         
    case 'glass-f11'
        newMat.material = piMaterialCreate(materialName,...
            'type','dielectric',...
            'roughness',0,'eta','glass-F11');

    case 'metal-ag'
        newMat.material = piMaterialCreate(materialName, ...
            'type', 'conductor','eta','metal-Ag-eta','k','metal-Ag-k');

    case {'metal-al','rim', 'chrome'}
        newMat.material = piMaterialCreate(materialName, ...
            'type', 'conductor','eta','metal-Al-eta','k','metal-Al-k');

    case 'metal-au'
        newMat.material = piMaterialCreate(materialName, ...
            'type', 'conductor','eta','metal-Au-eta','k','metal-Au-k');
        
    case 'metal-cu'
        newMat.material = piMaterialCreate(materialName, ...
            'type', 'conductor','eta','metal-Cu-eta','k','metal-Cu-k');
    case 'metal-cuzn'
        newMat.material = piMaterialCreate(materialName, ...
            'type', 'conductor','eta','metal-CuZn-eta','k','metal-CuZn-k');
    case 'metal-mgo'
        newMat.material = piMaterialCreate(materialName, ...
            'type', 'conductor','eta','metal-MgO-eta','k','metal-MgO-k');
    case 'metal-tio2'
        newMat.material = piMaterialCreate(materialName, ...
            'type', 'conductor','eta','metal-TiO2-eta','k','metal-TiO2-k');
    case 'tire'
        newMat.material = piMaterialCreate(materialName, ...
            'type', 'coateddiffuse','reflectance',[ 0.06394 0.06235 0.06235 ],'roughness',0.1);        
    case 'rough-metal'
        newMat.material = piMaterialCreate(materialName, ...
            'type', 'conductor','eta','metal-Al-eta','k','metal-Al-k',...
            'uroughness',0.05,'vroughness',0.05);
    case 'metal-spotty-discoloration'
        newMat = polligon_materialCreate(materialName,...
            'MetalSpottyDiscoloration001_COL_3K_METALNESS.png','coatedconductor'); 
    
    case 'wood-floor-merbau'
        newMat = polligon_materialCreate(materialName,...
            'WoodFlooringMerbauBrickBondNatural001_COL_3K.png','coateddiffuse'); 
        
    case 'fabric-leather-var1'
        newMat = polligon_materialCreate(materialName,...
            'FabricLeatherBuffaloRustic001_COL_VAR1_3K.png','coateddiffuse'); 

    case 'fabric-leather-var2'
        newMat = polligon_materialCreate(materialName,...
            'FabricLeatherBuffaloRustic001_COL_VAR2_3K.png','coateddiffuse');        
         
    case 'fabric-leather-var3'
        newMat = polligon_materialCreate(materialName,...
            'FabricLeatherBuffaloRustic001_COL_VAR3_3K.png','coateddiffuse');

    case 'listmaterial'
        % do nothing
        newMat = [];
        fprintf('\n---Material presets names ---\n');

        for ii = 1:numel(materialpresetsList)
            fprintf('%d: %s \n',ii, materialpresetsList{ii});
        end
        fprintf('---------------------\n');

    otherwise
        warning('No material presets found!');
end
end
function newMat = polligon_materialCreate(materialName, material_ref, materialType)
% material_ref is diffuse color texture in the folder which user 
% directly unzipped from the zip file downloaded from polligon website.
% 
% Polligon website: https://www.poliigon.com/textures/free

texfile = which(material_ref);
if isempty(texfile)
    error('File is not found! Make sure the file is existed!');
end

[texdir] = fileparts(texfile);

filelists = dir(texdir);


tex_ref    = piTextureCreate([materialName,'_tex_ref'],...
    'type','imagemap',...
    'filename',material_ref);
newMat.texture{1} = tex_ref;
normal_texture = [];
tex_displacement = [];
tex_roughness = [];
for ii = 1:numel(filelists)
    if contains(filelists(ii).name, 'NRM')
        normal_texture = filelists(ii).name;
    end

    if contains(filelists(ii).name, 'DISP16')
        displacement_texture = filelists(ii).name;

        tex_displacement = piTextureCreate([materialName,'_tex_displacement'],...
            'type','imagemap',...
            'format','float',...
            'filename',displacement_texture);
        newMat.texture{end+1} = tex_displacement;
    end

    if contains(filelists(ii).name, {'REFL','ROUGHNESS'})
        roughness_texture = filelists(ii).name;

        tex_roughness = piTextureCreate([materialName,'_tex_roughness'],...
            'type','imagemap',...
            'format','float',...
            'filename',roughness_texture);
        newMat.texture{end+1} = tex_roughness;
    end
end


switch materialType
    case 'coateddiffuse'
        material = piMaterialCreate(materialName,...
            'type','coateddiffuse',...
            'reflectance',[materialName,'_tex_ref']);
        if ~isempty(normal_texture')
            material.normalmap.value = normal_texture;
        end
        if ~isempty(tex_roughness)
            material.roughness.value = [materialName,'_tex_roughness'];
        end
        if ~isempty(tex_displacement)
            material.displacement.value = [materialName,'_tex_displacement'];
        end

    case 'coatedconductor'
         material = piMaterialCreate(materialName,...
            'type','coatedconductor',...
            'reflectance',[materialName,'_tex_ref'],...
            'interfaceroughness',0.01);
        if ~isempty(normal_texture')
            material.normalmap.value = normal_texture;
        end
        if ~isempty(tex_roughness)
            material.conductorroughness.type  = 'texture';
            material.conductorroughness.value = [materialName,'_tex_roughness'];
        end
        if ~isempty(tex_displacement)
            material.displacement.value = [materialName,'_tex_displacement'];
        end
end

newMat.material = material;

end







