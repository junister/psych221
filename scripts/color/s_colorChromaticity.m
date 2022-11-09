%% Chromaticity example
%
% We create a sphere, illuminated by a point source.  We render it through
% a typical oi, sensor and ip routine.
%
% Then we look at the chromaticity and luminance components of the image.
% We note that the chromaticity calculation removes most of the
% illumination variation.  
%

%%
ieInit;
if ~piDockerExists, piDockerConfig; end

%% Render a sphere illuminated with a point source

thisR = piRecipeDefault('scene name','sphere');

thisLight = piLightCreate('point','type','point','cameracoordinate', true);
thisR.set('light',thisLight, 'add');
thisR.set('light',thisLight.name,'specscale',0.5);
thisR.set('light',thisLight.name,'spd',[0.5 0.4 0.2]);

thisR.set('film resolution',[192 192]);
thisR.set('rays per pixel',128);
thisR.set('n bounces',1); % Number of bounces
thisR.set('render type', {'radiance', 'depth'});

scene = piWRS(thisR);

%%  Convert the scene into an image through a sensor
oi = oiCreate;
oi = oiCompute(oi,scene);
sensor = sensorCreate;
sensor = sensorSet(sensor,'fov',sceneGet(scene,'fov'),oi);
sensor = sensorCompute(sensor,oi);
ip = ipCreate;
ip = ipCompute(ip,sensor);

ipWindow(ip);

%%  Plot the values through the middle

sz = ipGet(ip,'size');
ipPlot(ip,'horizontal line',[1,round(sz(2)/2)]);

%%  Look at the linear data corrected for the luminance level
%
% Remember that the sphere has the same reflectance everywhere, and the
% variations are due to the lighting

srgb = ipGet(ip,'srgb');
lrgb = srgb2lrgb(srgb);

% Get the luminance level and compute the chromaticity map
% If lum is very small, the chromaticity is unreliable.  So, clean it up
lum = sum(lrgb,3);
dark = lum < 0.01;
chr = zeros(size(lrgb));
for ii=1:3
    thisC = lrgb(:,:,ii)./lum;
    thisC(dark) = 0;
    chr(:,:,ii) = thisC;
end

%% Show the results as an image

ieNewGraphWin;
mimg = montage({chr,lum}); axis image; axis off
sz = size(mimg.CData);
row = round(sz(1)/2);

%% Plot a horizontal line through the data
ieNewGraphWin;
plot(lum(row,:),'k-'); hold on;
plot(chr(row,:,1),'r:');
plot(chr(row,:,2),'g:');
grid on; xlabel('Position'); ylabel('Relative intensity');


%% END
