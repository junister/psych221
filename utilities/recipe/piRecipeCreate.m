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
%%
varargin = ieParamFormat(varargin);

p = inputParser;
p.addRequired('rName',@ischar);
p.parse(rName,varargin{:});

%% 
%{
  rList = thisR.list;
   1 {'ChessSet'               } - OK
    {'CornellBoxReference'    } - Seems black on ISETBio.  Maybe HDR?
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
    20 {'teapot-set'             } - Bad file name
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
        newDistant = piLightCreate('new distant',...
            'type', 'distant',...
            'specscale float', spectrumScale,...
            'spd spectrum', lightSpectrum,...
            'cameracoordinate', true);
        thisR.set('light', newDistant, 'add');
        
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
    case 'simplescene'
        thisR = piRecipeDefault('scene name',rName);

    otherwise
        error('Unknown recipe name %s\n',rName);
end

end

