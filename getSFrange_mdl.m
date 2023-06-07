function sfrange = getSFrange_mdl(screenPix, screenDeg, gparamIdx)
% sfrange = getSFrange_mdl(screenPix, screenDeg, gparamIdx)
% Note: this is a limitation imposed by encoding model, not visual stimuli
% See also: getSFrange_stim.m

[gaborparams_real] = getFilterParams(gparamIdx, screenPix, screenDeg);

%minimum and maximum SF that the motion energy model can compute
sfrange = prctile(gaborparams_real(4,:),[0 100]); %[cpd]

