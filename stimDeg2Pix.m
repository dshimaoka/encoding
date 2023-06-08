function [stimXpix, stimYpix] = stimDeg2Pix(stimInfo, stimXdeg, stimYdeg)
%[stimXpix, stimYpix] = stimDeg2Pix(stimInfo, stimXdeg, stimYdeg)
% returns screen pixels corresponding to visual field [deg]

 stimXpix = stimInfo.screenPix(2) / stimInfo.width * stimXdeg + 0.5*stimInfo.screenPix(2);
 stimYpix = stimInfo.screenPix(1) / stimInfo.height * stimYdeg + 0.5*stimInfo.screenPix(1);
