function [stimXdeg, stimYdeg] = stimPix2Deg(stimInfo, stimXpix, stimYpix)
% [stimXdeg, stimYdeg] = stimPix2Deg(stimInfo, stimXpix, stimYpix)
 stimXdeg = stimInfo.width * (stimXpix-0.5*stimInfo.screenPix(2))/stimInfo.screenPix(2);
 stimYdeg = stimInfo.height * (stimYpix-0.5*stimInfo.screenPix(1))/stimInfo.screenPix(1);