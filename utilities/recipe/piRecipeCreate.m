function thisR = piRecipeCreate(rName,varargin)
% Return a recipe that can be rendered immediately with piWRS
%
% Synopsis
%   thisR = piRecipeCreate(rName,varargin)
%
% Briewf
%   Many of the piRecipeDefault cases still need a light or to position the
%   camera to be rendered.  This routine adjusts the recipe so that it can
%   be rendered with piWRS immediately.
%
% Input
%   rName - Recipe name from the piRecipeDefaults list
%
% Key/Val pairs
%
% Return
%   thisR - the recipe
%
% See also
%   piRecipeDefault, thisR.list
%

% TODO
%   Maybe this should replace piRecipeDefault

% Examples:
%{
 thisR = piRecipeCreate('macbeth checker');
 piWRS(thisR);
%}
%{
 thisR = piRecipeCreate('Cornell_Box');
 piWRS(thisR);
%}
%{
 thisR = piRecipeCreate('Cornell Box Reference');
 piWRS(thisR);
%}
%{
 thisR = piRecipeCreate('Simple scene');
 piWRS(thisR);
%}
%{
 thisR = piRecipeCreate('teapot set');
 piWRS(thisR);
%}

%% Input parsing
varargin = ieParamFormat(varargin);

p = inputParser;
p.addRequired('rName',@ischar);
p.parse(rName,varargin{:});

%% 
%{
  rList = thisR.list;
   1 {'ChessSet'               } - OK
    {'CornellBoxReference'    } - Requires HDR because light is bright
    {'MacBethChecker'         } - Needs a light
    {'SimpleScene'            } - Renders
   5 {'arealight'             } - Broken
    {'bunny'                  } - Needs a light
    {'car'                    } - Needs a light
    {'checkerboard'           } - OK
    {'coordinate'             } - Needs a light
   10 {'cornell_box'            }- Needs a light
    {'flatSurface'            } - OK but boring.
    {'flatSurfaceWhiteTexture'} Not sure about the texture
    {'lettersAtDepth'         } - OK
    {'materialball'           } - OK
   15 {'materialball_cloth'     } - OK
    {'slantedEdge'            } - Needs a light
    {'sphere'                 } - Needs a light
    {'stepfunction'           } - OK
    {'teapot'                 } - Many problems
    20 {'teapotset'             } - Bad file name
    {'testplane'              } - Bad FBX

thisR = piRecipeDefault('scene name',rList{4});
piWRS(thisR);

%}

%%
switch ieParamFormat(rName)
    case 'macbethchecker'
        thisR = piRecipeDefault('scene name',rName);
        thisR = piLightDelete(thisR, 'all');

        % Add an equal energy distant light for uniform lighting
        spectrumScale = 1;
        lightSpectrum = 'equalEnergy';
        lgt = piLightCreate('new distant',...
            'type', 'distant',...
            'specscale float', spectrumScale,...
            'spd spectrum', lightSpectrum,...
            'cameracoordinate', true);
        thisR.set('light', lgt, 'add');
        
        thisR.set('integrator subtype','path');
        thisR.set('rays per pixel', 16);
        thisR.set('fov', 30);
        thisR.set('filmresolution', [640, 360]);
        thisR.set('render type', {'radiance', 'depth'});

    case 'cornell_box'
        thisR = piRecipeDefault('scene name',rName);

        thisR.set('rays per pixel',128);
        thisR.set('nbounces',5);
        piLightDelete(thisR,'all');
        distantLight = piLightCreate('distantLight', ...
            'type','spot',...
            'cameracoordinate', true);
        thisR.set('light',distantLight,'add');

        % By default, the fov is setted as horizontal and vertical
        fov = [25 25];
        thisR.set('fov',fov);

        % Increase the spatial resolution a bit
        filmRes = [384 256];
        thisR.set('film resolution',filmRes);
    case 'cornellboxreference'
        thisR = piRecipeDefault('scene name','CornellBoxReference');
        warning('Requires HDR because light source is bright.')
    case 'simplescene'
        thisR = piRecipeDefault('scene name',rName);
    case 'arealight'
        thisR = piRecipeDefault('scene name',rName);
    case 'bunny'
        thisR = piRecipeDefault('scene name',rName);
        bIDX = piAssetSearch(thisR,'object name','bunny');
        bPos = thisR.get('asset',bIDX,'world position');
        thisR.set('to',bPos);
        thisR.set('object distance',0.5);

        spectrumScale = 1;
        lightSpectrum = 'equalEnergy';
        lgt = piLightCreate('new distant',...
            'type', 'distant',...
            'specscale float', spectrumScale,...
            'spd spectrum', lightSpectrum,...
            'cameracoordinate', true);
        thisR.set('light', lgt, 'add');
        warning('Single, isolated bunny.  Might use piAssetInsert')
    case 'car'
        % The materials do not look right.  Rendering needs help.
        thisR = piRecipeDefault('scene name',rName);
        thisR.set('object distance',6);
        thisR.set('to',[-1 1.2 -5.6]);
        
        spectrumScale = 1;
        lightSpectrum = 'equalEnergy';
        lgt = piLightCreate('new distant',...
            'type', 'distant',...
            'specscale float', spectrumScale,...
            'spd spectrum', lightSpectrum,...
            'cameracoordinate', true);
        thisR.set('light', lgt, 'add');
        warning('Car scene needs work.')
    case 'checkerboard'
        thisR = piRecipeDefault('scene name',rName);
    case 'coordinate'
        thisR = piRecipeDefault('scene name',rName);
        spectrumScale = 1;
        lightSpectrum = 'equalEnergy';
        lgt = piLightCreate('new distant',...
            'type', 'distant',...
            'specscale float', spectrumScale,...
            'spd spectrum', lightSpectrum,...
            'cameracoordinate', true);
        thisR.set('light', lgt, 'add');
        idx = piAssetSearch(thisR,'object name','origin');
        thisR.set('to',thisR.get('asset',idx,'world position'));
        warning('Not visible in HDR mode.')
    case 'flatsurface'
        thisR = piRecipeDefault('scene name',rName);
        idx = piAssetSearch(thisR,'object name','Cube');
        thisR.set('to',thisR.get('asset',idx,'world position'));
    case 'flatsurfacewhitetexture'
        thisR = piRecipeDefault('scene name',rName);
        idx = piAssetSearch(thisR,'object name','Cube');
        thisR.set('to',thisR.get('asset',idx,'world position'));
        thisR.set('lights','all','delete');

        spectrumScale = 1;
        lightSpectrum = 'equalEnergy';
        lgt = piLightCreate('new distant',...
            'type', 'distant',...
            'specscale float', spectrumScale,...
            'spd spectrum', lightSpectrum,...
            'cameracoordinate', true);
        thisR.set('light', lgt, 'add');
        idx = piAssetSearch(thisR,'object name','Cube');
        thisR.set('to',thisR.get('asset',idx,'world position'));
        warning('No obvious texture.  Use checkerboard.')

    case 'lettersatdepth'
        thisR = piRecipeDefault('scene name',rName);
    case 'materialball'
        thisR = piRecipeDefault('scene name',rName);
    case 'materialball_cloth'
        thisR = piRecipeDefault('scene name',rName);
    case {'slantededge','slantedbar'}
        rName = 'slantededge';
        thisR = piRecipeDefault('scene name',rName);
        spectrumScale = 1;
        lightSpectrum = 'equalEnergy';
        lgt = piLightCreate('new distant',...
            'type', 'distant',...
            'specscale float', spectrumScale,...
            'spd spectrum', lightSpectrum,...
            'cameracoordinate', true);
        thisR.set('light', lgt, 'add');

        idx = piAssetSearch(thisR,'object name','Plane');
        thisR.set('to',thisR.get('asset',idx,'world position'));
    case 'sphere'
        thisR = piRecipeDefault('scene name',rName);
        spectrumScale = 1;
        lightSpectrum = 'equalEnergy';
        lgt = piLightCreate('new distant',...
            'type', 'distant',...
            'specscale float', spectrumScale,...
            'spd spectrum', lightSpectrum,...
            'cameracoordinate', true);
        thisR.set('light', lgt, 'add');
    case 'stepfunction'
        thisR = piRecipeDefault('scene name',rName);
        warning('No assets.  Maybe use slanted edge.')
    case 'teapotset'
        thisR = piRecipeDefault('scene name',rName);
    case 'testplane'
        thisR = piRecipeDefault('scene name',rName);
    otherwise
        error('Unknown recipe name %s\n',rName);
end

end

