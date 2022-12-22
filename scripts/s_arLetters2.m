% s_arLetters2
%

%%
 thisR = piRecipeCreate('macbeth checker');
 to = thisR.get('to') - [0.5 0 -0.8];
 delta = [0.15 0 0];
 for ii=1:numel('Lorem'), pos(ii,:) = to + ii*delta; end
 pos(end,:) = pos(end,:) + delta/2;  % Move the 'm' a bit
 thisR = charactersRender(thisR, 'Lorem','letterSize',[0.15,0.1,0.15],'letterRotation',[0,15,15],...
   'letterPosition',pos,'letterMaterial','wood-light-large-grain');
 thisR.set('skymap','sky-sunlight.exr');
 thisR.set('nbounces',4);
 piWRS(thisR);

%%
 thisR = piRecipeCreate('Cornell_Box');
 thisR.set('film resolution',[384 256]*2);
 to = thisR.get('to') - [0.32 -0.1 -0.8];
 delta = [0.09 0 0];
 str = 'marble';
 idx = piAssetSearch(thisR,'object name','003_cornell_box');
 piMaterialsInsert(thisR,'name','wood-light-large-grain');
 thisR.set('asset',idx,'material name','wood-light-large-grain');
 for ii=1:numel(str), pos(ii,:) = to + ii*delta; end
 thisR = charactersRender(thisR, str,'letterSize',[0.1,0.03,0.1]*0.7,...
    'letterRotation',[0,0,-10],'letterPosition',pos,'letterMaterial','marble-beige');
 thisR.set('skymap','sky-sunlight.exr');
 thisR.set('nbounces',4);
 piWRS(thisR);
