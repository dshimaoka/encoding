screenDeg = [15 27]; %[deg] coverage of the presented stimulus 
screenPix = [144 256];%/4; %#pixels of the original movie before projecting it to the screen
gparamIdx = 2;

[gaborparams_real] = getFilterParams(gparamIdx, screenPix, screenDeg);

%maximum SF that the motion energy model can compute
sfmax_mdl = max(gaborparams_real(4,:)); %[cpd]

%maximum SF included in the visual stimulus 
pixPerDeg = mean(screenPix./screenDeg);
sfmax_stim = 0.25 * pixPerDeg;%[cpd]
%justification for sfmax_stim:
% [cycles/deg] = pixPerDeg * [cycles/pix]
% maximum allowed cycles per pixel is 0.5 when the OR = 0 or 90
% in other ORs, practically maximum is 0.25
%hence maxim allowed cycles per degree is 0.25*pixPerDeg

%cf marmoset vision - basically 10times worse than that of macaque
%maximum SF @fovea: 10cpd
%maximum SF @parafovea: 1cpd
