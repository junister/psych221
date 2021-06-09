%% pbrt v4 introduction 
% CPU only
% using local compiled pbrt

%%
%{
./pbrt --toply /Users/zhenyi/git_repo/dev/iset3d/data/V4/teapot-set/TeaTime.pbrt > /Users/zhenyi/git_repo/dev/iset3d/local/formatted/teapot-set/TeaTime.pbrt
%}

% Read the reformatted car recipe
recipeV4 = piReadv4(formatted_fname);