function [xd,yd]=relpos2deg(xp,yp,screenWidth,screenHeight)
% [xd,yd]=pix2deg(xp,yp,screenWidth,screenHeight)
%xp: relative position on the screen [0 1]

xd = screenWidth*(xp - .5);
yd = screenHeight*(yp - .5);


