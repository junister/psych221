%% Proto script for turning pbrt characters into
%  assets that we can merge

% Initial trial balloon
characterRecipe = '1-pbrt.pbrt';
thisR = piRead(characterRecipe);
thisR.set('lights','all','delete');
% Not sure what character position is
n = thisR.get('asset names');

% Some conversions set the merge name, but maybe we can just use
% what's there?
% thisR.set('asset',n{2},'name','head_B');

characterDir = piDirGet('characters');

saveFile = [erase(characterRecipe,'.pbrt') '.mat'];

oFile = thisR.save(fullfile(characterDir,saveFile));

% No clue if this is correct
mergeNode = n{2};
save(oFile,'mergeNode','-append');
