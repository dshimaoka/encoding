
gparamIdx = 2;

rawDir = '\\storage.erc.monash.edu\shares\R-MNHS-Syncitium\Shared\Daisuke\recording\Nishimoto2011';
stimDir = '\\storage.erc.monash.edu\shares\R-MNHS-Syncitium\Shared\Daisuke\natural\nishimoto2011';
dsDir = '\\storage.erc.monash.edu\shares\R-MNHS-Syncitium\Shared\Daisuke\recording\Nishimoto2011_ds';
mkdir(dsDir);




%% neural data
for isub = 1:3

    isub
    
    load(fullfile(rawDir, ['VoxelResponses_subject' num2str(isub) '.mat']));
    %ei
    %roi
    %rt: 7200x73728
    %rva single trial:540x10x73728
    %rv avg across 10trials:540x73728 =squeeze(nanmean(rva,2))
    
    nVoxels = size(rt,2);
    
    observed = [rt; rv];%note rv but not rt is averaged across 10 repeats
    nFrames = size(observed,1);
    timeVec = single(1:nFrames)';
    TT = timetable(seconds(timeVec), observed);
    writetimetable(TT, fullfile(dsDir,['subject' num2str(isub) '.csv']));
    %< writetimetable/writematrix save numerics as long
end



%% stimulus and filter data
load(fullfile(stimDir, 'Stimuli.mat'),'st','sv');
S = cat(4,st,sv);
clear st sv

S  = single(S)/255;

% Conver to grayscale (luminance only)
cparams = preprocColorSpace_GetMetaParams(1);
[S_lum, cparams] = preprocColorSpace(S, cparams);
clear S

% Gabor wavelet processing
gparams = preprocWavelets_grid_GetMetaParams(gparamIdx);
[S_gab, gparams] = preprocWavelets_grid(S_lum, gparams);%filter assumes no time delay
nlparams = preprocNonLinearOut_GetMetaParams(1);
clear S_lum

% Compute log of each channel to scale down very large values
[S_nl, nlparams] = preprocNonLinearOut(S_gab, nlparams);
nrmparams = preprocNormalize_GetMetaParams(1);
clear S_gab

% Downsample data to the sampling rate of your fMRI data (the TR)
dsparams = preprocDownsample_GetMetaParams(1); % for TR=1; use (2) for TR=2
[S_ds, dsparams] = preprocDownsample(S_nl, dsparams);
clear S_nl

% Z-score each channel
[S_fin, nrmparams] = preprocNormalize(S_ds, nrmparams);
clear S_ds
S_fin = S_fin';

%impose delay so the filter uses signal only from the past
S_fin = circshift(S_fin, round(gparams.tsize/2), 2);
S_fin = S_fin';

timeVec = (1:size(S_fin,1))';
%test1: save as datastore ... NG loading is slow and no need to load each
%filters
% TTs = timetable(seconds(timeVec), S_fin);
% writetimetable(TTs, fullfile(dsDir,['gaborFilter' num2str(gparamIdx) '.csv']));
% ds_gabor = tabularTextDatastore(fullfile(dsDir,['gaborFilter' num2str(gparamIdx) '.csv']));
% ds_gabor.SelectedVariableNames = ds_gabor.VariableNames(2:end);
% S_fin = tall(ds_gabor);
% S_fin = gather(S_fin);
% S_fin = S_fin{:,:};


% test2: this is enough
save( fullfile(dsDir,['gaborFilter' num2str(gparamIdx) '.mat']), ...
    'timeVec', 'S_fin');
