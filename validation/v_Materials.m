% Need to add a validation script that runs through all materials!

% Starting code from the MaterialInsert test:
ieInit;
bunnyAsset = '001_001_Bunny_O';
thisR = piRecipeDefault('scene name','bunny');
thisR.set('skymap','room.exr');
thisR.set('asset',bunnyAsset,'scale',4);
thisR.set('nbounces',3);

%%
results = [];
allMaterials = piMaterialPresets('list');
for ii = 1:numel(allMaterials)
    try
        % we need to re-load so a broken material
        % doesn't cause us to error out
        thisR = piRecipeDefault('scene name','bunny');
        thisR.set('skymap','room.exr');
        thisR.set('asset',bunnyAsset,'scale',4);
        thisR.set('nbounces',3);
        piMaterialsInsert(thisR,'names',allMaterials{ii});
        thisR.set('asset',bunnyAsset,'material name',allMaterials{ii});
        piWRS(thisR);
        results = [results sprintf("Material: %s Succeeded\n",allMaterials{ii})];
    catch EX
        results = [results sprintf("Material: %s FAILED: %s\n",allMaterials{ii},EX.message)];
    end
end

for ii = 1:numel(results)   
    fprintf(results{ii});
end
%{ 
results as of Aug 5, 2022:
Material: diffuse-gray Succeeded
Material: diffuse-red Succeeded
Material: diffuse-white Succeeded
Material: glossy-black Succeeded
Material: glossy-gray Succeeded
Material: glossy-red Succeeded
Material: glossy-white Succeeded
Material: glass Succeeded
Material: red-glass FAILED: Render failed.
Material: glass-bk7 Succeeded
Material: glass-baf10 Succeeded
Material: glass-fk51a Succeeded
Material: glass-lasf9 Succeeded
Material: glass-f5 Succeeded
Material: glass-f10 Succeeded
Material: glass-f11 Succeeded
Material: mirror Succeeded
Material: metal-ag Succeeded
Material: chrome Succeeded
Material: rough-metal Succeeded
Material: metal-au Succeeded
Material: metal-cu Succeeded
Material: metal-cuzn Succeeded
Material: metal-mgo Succeeded
Material: metal-tio2 Succeeded
Material: tire Succeeded
Material: marble-beige Succeeded
Material: tiles-marble-sagegreen-brick Succeeded
Material: checkerboard Succeeded
Material: ringsrays Succeeded
Material: macbethchart Succeeded
Material: slantededge Succeeded
Material: dots Succeeded
Material: wood-floor-merbau Succeeded
Material: wood-medium-knots Succeeded
Material: wood-light-large-grain Succeeded
Material: wood-mahogany Succeeded
%}
