% s_shapeExample
%
% In the newest version  of Human Eye in PBRT v4 (TG), we have the
% ability to give PBRT an arbitrary lookuptable to represent positions
% on the surface. This is supposed to reproduce the results from the
% legacy code that maps a position on the film to a position on a
% spherical surface.
%
% This script illustrates how we made a bumpy retina and rendered
% using the sceneEye with that.  Various quality of life things left
% to do, but it ran through the first visualization.
%
% See also
%

%% Define Bump (gaussian
center=[0 0];sigma=0.9;
height = 400*1e-3; % 0.4 mm
width= 400*1e-3; % 0.4 mm

maxnorm=@(x)x;
bump1=@(x,y) 2*height*maxnorm(exp(- ((x-center(1))^2+(y-center(2))^2)/(2*sigma^2)));
center=[2 0];sigma=0.9;
bump2=@(x,y) 2*height*maxnorm(exp(- ((x-center(1))^2+(y-center(2))^2)/(2*sigma^2)));
center=[-1.9 -2];sigma=0.9;
bump3=@(x,y) 2*height*maxnorm(exp(- ((x-center(1))^2+(y-center(2))^2)/(2*sigma^2)));

bump=@(x,y) (bump1(x,y) + bump2(x,y)+ bump3(x,y));


%% Define Retina
retinaDistance =16.320000;%mm  (This will be the lowest Z value of the surface)
retinaRadius= 12.000000; %mm
retinaSemiDiam = 3.942150; %mm

retinaDiag = retinaSemiDiam*1.4142*2; % sqrt(2)*2


%% Define film
filmDiagonal = 10; % mm
rowresolution = 256; % number of pixels
colresolution = 256; % number of pixels
rowcols = [rowresolution colresolution];

% Pixels are square by construction
pixelsize = filmDiagonal/sqrt(rowresolution^2+colresolution^2);

% Total size of the film in mm
row_physicalwidth= pixelsize*rowresolution;
col_physicalwidth= pixelsize*colresolution;


%% Sample positions for the lookup table

index = 1;
for r=1:rowcols(1)
    for c=1:rowcols(2)


        % Define the film index (r,c) in the 2d lookuptable
        pFilm = struct;
        pFilm.x=r;
        pFilm.y=c;


        % Map Point to sphere using the legacy realisticEye code
        filmRes= struct;        filmRes.x=rowcols(1);        filmRes.y=rowcols(2);
        point = mapToSphere(pFilm,filmRes,retinaDiag,retinaSemiDiam,retinaRadius,retinaDistance);



        % PBRT expects meters for lookuptable not milimeters
        mm2meter=1e-3;
        pointPlusBump_meter(index,:) = [point.x point.y point.z+bump(point.x,point.y)]*mm2meter;


        % Keep data for plotting the surface later
        Zref_mm(r,c)=point.z;
        Zbump_mm(r,c)=pointPlusBump_meter(index,3)/mm2meter;


        index=index+1;
    end
end


%% Plot surface
Zref_mm(Zref_mm>0)=nan;
Zbump_mm(Zbump_mm>-13)=nan;
fig=figure(5);clf
fig.Position = [700 487 560 145];
fig.Position=[700 487 560 145];
subplot(121)
s=surf(Zbump_mm);

s.EdgeColor = 'none';
zlim([-retinaDistance -15])
subplot(122)
imagesc(Zbump_mm,[-retinaDistance -15]);

%% From utilities/filmshape

% thisR = piRecipeDefault('scene name','lettersAtDepth');

thisSE = sceneEye('letters at depth','eye model','arizona');

fname = fullfile(pwd,'deleteMe.json');
piShapeWrite(fname, pointPlusBump_meter);

thisSE.set('film shape file',fname);
thisSE.get('film shape file')

fs = jsonread(fname);
% (x,y)
thisSE.set('film resolution',[fs.numberofpoints 1]);

%
thisD = dockerWrapper;
thisD.remoteCPUImage = 'digitalprodev/pbrt-v4-cpu';
thisD.gpuRendering = 0;

thisSE.set('sampler subtype','sobol');
thisSE.set('rays per pixel',64);
[oi,result] = thisSE.render('docker wrapper',thisD);

%%
% If a general case, we have (x,y,z) in the JSON file and
% corresponding radiance and illuminance ... 
illuminance = oiGet(oi,'illuminance');

% Try to find the mesh method in t_retinalShapes
%

% Each point in the rendered oi corresponds to a position specified by
% the lookup table.
%
% The film shape table specifies the point and its index
%
pixelvalue = zeros(fs.numberofpoints,1);
position = zeros(fs.numberofpoints,3);
for t=1:fs.numberofpoints
    pixelvalue(t) = illuminance(fs.table(t).index+1); 
    
    % Record position
    position(t,1:3)=fs.table(t).point;
end

ieNewGraphWin;
scatter3(position(:,1),position(:,2),position(:,3), 40, pixelvalue(:), 'filled')

mm2meter=1e-3;
zlim([-16.4 -15]*mm2meter);
xlim([-5 5]*mm2meter);
ylim([-5 5]*mm2meter);
colormap gray
view(-162,86)

%%
% If a grid, this would work
p = sceneGet(oi,'photons');
p = reshape(p,50,50,31);
oi = oiSet(oi,'photons',p);
oiWindow(oi);  

% If not a grid, you could still interpolate from position and
% pixelvalue to fill up an approximate photon data set

%% END

%% END



