function newMat = polligon_materialCreate(materialName, material_ref, materialType)
% material_ref is diffuse color texture in the folder which user 
% directly unzipped from the zip file downloaded from polligon website.
% 
% Polligon website: https://www.poliigon.com/textures/free

texfile = which(material_ref);
if isempty(texfile)
    if ~exist(material_ref, 'file')
        error('File is not found! Make sure the file is existed!');
    end
end

[texdir,tex_name, ext] = fileparts(texfile);

filelists = dir(texdir);

[~, material_ref_fname,~] = fileparts(material_ref);
tex_ref    = piTextureCreate([materialName,'_tex_ref'],...
    'type','imagemap',...
    'filename',material_ref_fname);
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
        if contains(filelists(ii).name,'REFL')
            ref = imread(filelists(ii).name);
            ref = double(ref)/255;
            roughness = 1-ref;
            roughness_texture = strrep(roughness_texture, 'REFL', 'ROUGHNESS');
            imwrite((roughness/max2(roughness)), fullfile(filelists(ii).dir, roughness_texture));
        end
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