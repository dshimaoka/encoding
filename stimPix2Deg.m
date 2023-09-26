function [stimXdeg, stimYdeg] = stimPix2Deg(stimInfo, stimXpix, stimYpix)
% [stimXdeg, stimYdeg] = stimPix2Deg(stimInfo, stimXpix, stimYpix)
%
% INPUT:
% stimXpix: pixel number from left edge of the screen
% stimYpix: pixel number from top of the screen
%
% see also. stimDeg2Pix
%
% 9/26/23: invert output of stimYdeg
 
stimXdeg = stimInfo.width * (stimXpix-0.5*stimInfo.screenPix(2))/stimInfo.screenPix(2);
stimYdeg = -stimInfo.height * (stimYpix-0.5*stimInfo.screenPix(1))/stimInfo.screenPix(1);