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










