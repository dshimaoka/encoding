clear all

%original data
loadFile = 'CJ199_revcor0009.mat';
stimFreq = 60; %guessed from labArchives

%motion energy model
gparamIdx = 2;
dsFreq = 30; %down sampling 

loadDir = '\\storage.erc.monash.edu\shares\R-MNHS-Syncitium\Shared\MarmosetData\CJ199_StimulusFiles\';
saveDir = '\\storage.erc.monash.edu\shares\R-MNHS-Syncitium\Shared\Daisuke\natural\CJ199';

load(fullfile(loadDir, loadFile),'Stim','Scr','Saving')

%% retrieve screen info
%taken from [Stim, Scr, Saving] = RFStim_Marmo_Define(Stim)
Stim.xList = Stim.xneg:Stim.Diam:Stim.xpos; % (deg) x-center position of patch
Stim.yList = Stim.yneg:Stim.Diam:Stim.ypos;
Stim.PDpos = [Stim.TLX Stim.TLY Stim.BRX Stim.BRY];

Stim.nX = length(Stim.xList);
Stim.nY = length(Stim.yList);


n = Stim.nTrialTot;%number of frames

%% initialize seed
oldStream = RandStream('mt19937ar','Seed',Stim.rSeed);
RandStream.setGlobalStream(oldStream);

%% retrieve stimulus of each frame
imageMatrix = zeros(Stim.nY, Stim.nX, n, 'single'); %'unint8'
for f = 1:n
tmp=rand(1,Stim.nTrialTypes); 

black=tmp<=1/3;
grey=tmp>1/3 & tmp<2/3;
white=tmp>=2/3;

%DISPLAY++
tmp(black)=Scr.black;
tmp(grey)=Scr.white/2;
tmp(white)=Scr.white;
% %DISPLAY++
% tmp(black)=0;
% tmp(grey)=0.5;
% tmp(white)=1;
% 
% %DISPLAY++ 1-6-16 what the hell??
tmp(black)=0;
tmp(grey)=127;
tmp(white)=255;


imageMatrix(:,:,f)=reshape(tmp,Stim.nY,Stim.nX);

end

%% make the screen square for motion energy model
stimLen = min(Stim.nX, Stim.nY);
stimCentY = round(Stim.nY/2);
stimCentX = round(Stim.nX/2);
ypix = stimCentY-floor(stimLen/2):stimCentY-floor(stimLen/2)+stimLen-1;
xpix = stimCentX-floor(stimLen/2):stimCentX-floor(stimLen/2)+stimLen-1;
imageMatrix_sq = single(imageMatrix(ypix, xpix, :));
clear imageMatrix


%% motion energry model
% Gabor wavelet processing
gparams = preprocWavelets_grid_GetMetaParams(gparamIdx);
[S_gab, gparams] = preprocWavelets_grid(imageMatrix_sq, gparams);%filter assumes no time delay
nlparams = preprocNonLinearOut_GetMetaParams(1);

% Compute log of each channel to scale down very large values
[S_nl, nlparams] = preprocNonLinearOut(S_gab, nlparams);
nrmparams = preprocNormalize_GetMetaParams(1);
clear S_gab

% Downsample data to the sampling rate of your fMRI data (the TR)
%dsparams = preprocDownsample_GetMetaParams(1); % for TR=1; use (2) for TR=2
dsparams.dsType = 'box';
dsparams.imHz = stimFreq;     % movie / image sequence frame rate
dsparams.sampleSec = 1/dsFreq; % TR
dsparams.frameshifts = []; % empty = no shift
dsparams.gaussParams = []; %[1,2]; % sigma,mean

[S_ds, dsparams] = preprocDownsample(S_nl, dsparams);
clear S_nl

% Z-score each channel
[S_fin, nrmparams] = preprocNormalize(S_ds, nrmparams);
clear S_ds
S_fin = S_fin';

%impose delay so the filter uses signal only from the past
S_fin = circshift(S_fin, round(gparams.tsize/2), 2);
S_fin = S_fin';

timeVec = 1/dsFreq*(1:size(S_fin,1))'; %[s]

save( fullfile(saveDir,['gaborFilter' num2str(gparamIdx) '_' loadFile]), ...
    'timeVec', 'S_fin','-v7.3');

%% imageMatrix is used in DeclanEdit3...
% in RFStim_Marmo_Init_Saman(Stim,Scr,Saving) to initialise PTB and get screen parameters
%[Scr.w, Scr.rect] = PsychImaging('OpenWindow', screenNumber, 127.5, [], 32, 2);
%<Scr.w is a pointer to the screen
% from RFStim_Marmo_MakeTex(Scr,Stim) 
% imageMatrix=reshape(tmp,Stim.nY,Stim.nX);
% Tex=Screen('MakeTexture', Scr.w, imageMatrix);
% for fr = 1:Stim.frOn
%     Screen('Drawtexture',Scr.w,Tex,[],[Stim.destRect],[],0);
% end

