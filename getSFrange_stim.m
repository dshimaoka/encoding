function sfrange = getSFrange_stim(screenPix, screenDeg)
% sfrange = getSFrange_stim(screenPix, screenDeg)
% returns minimum and maximum SF included in the visual stimulus in cycles per deg
%
% INPUT
% screenPix: number of pixels used for visual stimulation [height width]
% screenDeg: visual angle in degree used for visual stimulation [height width]

pixPerDeg = mean(screenPix./screenDeg);

minSF = 1/max(screenPix) * pixPerDeg; %[cpd] 
maxSF = 0.25 * pixPerDeg;%[cpd]
%justification for maxSF:
% [cycles/deg] = pixPerDeg * [cycles/pix]
% maximum allowed cycles per pixel is 0.5 when the OR = 0 or 90
% in other ORs, practically maximum is 0.25
%hence maxim allowed cycles per degree is 0.25*pixPerDeg

%cf marmoset vision - basically 10times worse than that of macaque
%maximum SF @fovea: 10cpd
%maximum SF @parafovea: 1cpd

sfrange = [minSF maxSF];