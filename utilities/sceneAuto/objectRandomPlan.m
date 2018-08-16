function [objectPosition_list] = objectRandomPlan(sidewalk_list,object_list, object_number, offset)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function: This function randomly places objects on sidewalks
%
% Input:
%       sidewalk_list: include the information of each sidewalk(length, width, rotate, coordinate)
%       D----A
%       |    |
%       |    | road
%       |    |
%       |    |
%       C----B
%        For a sidewalk ABCD above, AB is the outside edge of the sidewalk.
%            length: the length of edge AB
%            width: the length of DA
%            direction: the clockwise rotating angle of sidework, base on this position.
%            coordinate: the coordinate of B.
%       object_list: generated from function
%       object_number: the number of objects on each sidewalk
%       offset: the distance from object to edge AB
% 
% Output:
%       objectPosition_list: include name, position, rotate and size of each object
% by SL, 2018.8
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% generate the list of objects' position information
x = size(sidewalk_list,2);
count = 0;
num = size(object_list,2);
for jj = 1 : x
    start_point = sidewalk_list(jj).coordinate - [cos(sidewalk_list(jj).direction*pi/180)*offset, -sin(sidewalk_list(jj).direction*pi/180)*offset];  
    for ii = 1 : object_number
        count = count + 1;
        %randomly choose position 
        rand_length = randi(floor(sidewalk_list(jj).length));
        coordinate_rand(1,1) = (rand_length * sin(sidewalk_list(jj).direction * pi/180));
        coordinate_rand(1,2) = (cos(sidewalk_list(jj).direction * pi/180) * rand_length);
        %randomly choose serial number of objects 
        objectPosition_list(count).name = sprintf('%s_%03d', object_list(1).name, randi(num));
        %got the list  of specific objects
        for kk = 1: num
            if (object_list(kk).geometry.name == objectPosition_list(count).name)
            break;
            end
        end
        objectPosition_list(count).size = object_list(kk).geometry.size;
        objectPosition_list(count).position = [start_point(1) + coordinate_rand(1), sidewalk_list(jj).height, start_point(2) + coordinate_rand(2)];
        objectPosition_list(count).rotate = sidewalk_list(jj).direction;
    end
end

