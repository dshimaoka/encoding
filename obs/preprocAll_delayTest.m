dur = 10; %[s]
frameRate = 120;%[Hz]
dsRate = 10;%[Hz];
stimTime = 2; %[s] when delta stim happens
timeVec_input = 1/frameRate:1/frameRate:dur;

paramIdx.cparamIdx = [];
paramIdx.gparamIdx = 2;
paramIdx.nlparamIdx = 1;
paramIdx.dsparamIdx = 1;
paramIdx.nrmparamIdx = [];
S = zeros(1,1,dur*frameRate);
S(:,:,stimTime*frameRate) = 1;
gparams = preprocWavelets_grid_GetMetaParams(paramIdx.gparamIdx);
%gparams.show_or_preprocess = 0; %necessary to obtain gaborparams
%[~, params] = preprocWavelets_grid(S, gparams);%just to obtain gabor bank parameters
tsize = gparams.tsize; %temporal window size in Frame

[S_fin, timeVec] = preprocAll(S, paramIdx, frameRate, dsRate);
msOut = mean(S_fin,2);

figure;
subplot(211);
plot(timeVec_input,squeeze(S));
vline(timeVec_input(stimTime*frameRate));
title(['frame rate: ' num2str(frameRate) 'Hz']);
ylabel('input to preprocAll');

subplot(212);
plot(timeVec, log(msOut));
xlabel('time [s]');
vline(timeVec_input(stimTime*frameRate));
vline([timeVec_input(stimTime*frameRate)-tsize/frameRate/2 timeVec_input(stimTime*frameRate)+tsize/frameRate/2],gca,'',[.5 .5 .5])
ylabel('output from preprocAll');
title(['down sampling rate: ' num2str(dsRate) 'Hz']);
screen2png(['dsRate' num2str(dsRate)]);
