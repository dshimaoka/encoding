stimInfo.screenPix = [144 256]; %FIXED

%CJ220,224,229 and onwards
stimInfo.width = 25;
stimInfo.height = 45;

%CJ231 and onwards
% stimInfo.width = 40;
% stimInfo.height = 70;

[stimXdeg, stimYdeg] = stimPix2Deg(stimInfo, [1 stimInfo.screenPix(2)], [1 stimInfo.screenPix(1)]);
screenDeg = [diff(stimXdeg) diff(stimYdeg) ];

gparamIdx = 2;
sfrange_stim = getSFrange_stim(stimInfo.screenPix, screenDeg)
sfrange_mdl = getSFrange_mdl(stimInfo.screenPix, screenDeg, gparamIdx)

