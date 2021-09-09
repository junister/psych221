function material = piMaterialLookup(materialName)
% return a material struct by a specified material name
% reference: github.com/mmp/pbrt-v4-scenes
materialName = lower(materialName);
switch materialName
    
    case {'lambertian','diffuse'}
        material = piMaterialCreate('ISET-diffuse','type','diffuse');
        
    case {'glass'}
        material = piMaterialCreate('ISET-diffuse','type','dielectric');
        
    case {'metal'}
        material = piMaterialCreate('ISET-metal','type','conductor',...
            'eta','metal-Al-eta',...
            'k','metal-Al-k');
        
    case {'gold'}
        material = piMaterialCreate('ISET-metal','type','conductor',...
            'eta','spds/Au.eta.spd',...
            'k','spds/Au.k.spd');
        
    case {'silver'}
        material = piMaterialCreate('ISET-metal','type','conductor',...
            'eta','metal-Ag-eta',...
            'k','metal-Ag-k');
        
    case {'mirror'}
        material = piMaterialCreate('ISET-metal','type','conductor',...
            'roughness',0,...
            'eta','metal-Ag-eta',...
            'k','metal-Ag-k');
        
    case {'plastic'}
        material = piMaterialCreate('ISET-diffuse','type','coatteddiffuse',...
            'roughness',0.010408);
        
    otherwise
        error('No matched material name found.');
end

end
