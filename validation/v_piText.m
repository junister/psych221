%% v_piText
% 
% Validation for inserting text into a recipe
% 
% Make the double character instance work

%%
% thisR = piRecipeCreate('macbeth checker');
thisR = piRecipeCreate('simple scene');

piMaterialsInsert(thisR,'name','wood-light-large-grain');

str = 'abc';
piTextInsert(thisR,str);
thisR.show;


to = thisR.get('to') - [0.5 0 -0.8];
delta = [0.15 0 0];
pos = zeros(numel(str),3);
for ii=1:numel(str), pos(ii,:) = to + ii*delta; end
pos(end,:) = pos(end,:) + delta/2;  % Move the 'm' a bit

piObjectInstance(thisR);
thisR.show;


thisR = charactersRender(thisR, str,'letterSize',[0.15,0.1,0.15],'letterRotation',[0,15,15],...
    'letterPosition',pos,'letterMaterial','wood-light-large-grain');

thisR.set('skymap','sky-sunlight.exr');
thisR.set('nbounces',4);
piWRS(thisR);

%% END