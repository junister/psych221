%  Converting the radiance in a rendered image into something
%  plausible
%

% This was a kitchen scene
%

E = sceneGet(scene,'energy');
wave = sceneGet(scene,'wave');

size(E)
[E,r,c] = RGB2XWFormat(E);
E = E';

s = max(E);
lst = s>1e-4;
Es = E(:,lst);
s = max(Es);
for ii = 1:size(Es,2)
    Es(:,ii) = (1/s(ii))*Es(:,ii);
end
[U,S,V] = svd(Es,'econ');

% Radiance basis
ieNewGraphWin;
plotRadiance(wave,U(:,1:6));

cumsum(diag(S.^2))/sum(diag(S.^2))
[coef, score, latent] = pca(Es);

% Radiance basis via pca
ieNewGraphWin;
plotRadiance(wave,score(:,1:6));

L = sceneGet(scene,'illuminant energy');
ieNewGraphWin;
plot(wave,L);

% Reflectance, sort of
R = diag(1./L)*Es;
[W,D,Y] = svd(R,'econ');

cumsum(diag(D.^2))/sum(diag(D.^2))

ieNewGraphWin;
plotReflectance(wave,W(:,1:6));

%% We could replace the simulated radiance or reflectance functions
%
% This might be done by choosing a desired radiance or radiance basis,
% and then using that to replace the simulated radiance (or
% reflectance).
%

E = sceneGet(scene,'energy');
wave = sceneGet(scene,'wave');
size(E)

[E,r,c] = RGB2XWFormat(E);
E = E';
ieNewGraphWin;
plot(wave,E(:,randi(5000,50)));

L = sceneGet(scene,'illuminant energy');
R = diag(1./L)*E;
ieNewGraphWin;
plot(wave,R(:,randi(5000,50)));


% Our default 8 dimensional basis
b1 = ieReadSpectra('reflectanceBasis.mat',wave);

% Rapprox = R;
nDims = 8;
bsmall = b1(:,1:nDims);
Rapprox = bsmall*(bsmall'* R);

% ieNewGraphWin;
% plot(wave,Rapprox(:,randi(5000,50)));

%
Eapprox = diag(L)*Rapprox;
Eapprox = XW2RGBFormat(Eapprox',r,c);

sceneb1 = sceneSet(scene,'energy',Eapprox);
sceneb1 = sceneSet(sceneb1,'name',sprintf('dim %d',nDims));

sceneWindow(sceneb1);

%% 

scene = ieGetObject('scene');

