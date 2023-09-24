%makeDataBase.m:
%this script process and save imaging and stimulus data(saveImageProcess & saveStimData), 
%that will be used for the model fitting (in MASSIVE) by wrapper_encoding.m
% as of 24/2, took 1.5h to complete


if ~ispc
    addpath(genpath('~/git'));
    addDirPrefs;
end

expID = 8;


roiSuffix = '';
stimSuffix = '_square';

%% imaging parameters
rescaleFac = 0.1;
procParam.cutoffFreq = 0.02; %0.1
procParam.lpFreq = []; %2
rotateInfo = [];
rebuildImageData = false;
makeMask = false;%true;
uploadResult = true;
dsRate = 1;%[Hz] %sampling rate of hemodynamic coupling function


%% stimulus parameters
%ID1,3
%stimXrange = 24:156; %201:256; %1:left
%stimYrange = 5:139; %72-28+1:72+28;  %1:top
%ID2
%stimXrange = 161:238;
%stimYrange = 29:108;
%ID8,9
stimXrange =768:768+247;%293:293+247;
stimYrange = 378:378+247;

% gabor bank filter 
gaborBankParamIdx.cparamIdx = 1;
gaborBankParamIdx.gparamIdx = 2;
gaborBankParamIdx.nlparamIdx = 1;
gaborBankParamIdx.dsparamIdx = 1;
gaborBankParamIdx.nrmparamIdx = 1;
gaborBankParamIdx.predsRate = 15; %Hz %mod(dsRate, predsRate) must be 0
%< sampling rate of gabor bank filter

expInfo = getExpInfoNatMov(expID);
dataPaths = getDataPaths(expInfo, rescaleFac, roiSuffix, stimSuffix);

%% save imaging raw and processed data
if exist(dataPaths.imageSaveName,'file') % && 
    disp(['Loading ' dataPaths.imageSaveName]);
    load(dataPaths.imageSaveName,'imageProc');
    
    try
        cic = imageProc.cic;
        stimInfo = imageProc.stimInfo;
    catch err
    end
else
    
    [imageProc, cic, stimInfo] = saveImageProcess(expInfo, rescaleFac, rebuildImageData);
    
       
    
    [~,imDataName] = fileparts(dataPaths.imageSaveName);
    
    dirPref = getpref('nsAnalysis','dirPref');
    imageSaveName = fullfile(fullfile(dirPref.rootDir,expInfo.subject,'processed'), [imDataName '.mat']);
    
    
    mkdir(fileparts(dataPaths.imageSaveName))
    
    status = movefile(imageSaveName, dataPaths.imageSaveName);
    if status==1
        disp([imDataName ' was successfully uploaded']);
    else
        disp([imDataName ' was NOT uploaded']);
    end
end

%% align image data
if expID==6
    load('\\ad.monash.edu\home\User006\dshi0006\Documents\MATLAB\2023ImagingPaper\image2Image_CJ235.mat',...
        'baseImage','inputImage','base_points','input_points');
    t_concord = cp2tform(rescaleFac * input_points, rescaleFac * base_points, 'nonreflective similarity');
    imageDim = size(imresize(inputImage, rescaleFac));
    tensor = reshape(imageProc.V, imageDim(1),imageDim(2),[]);
    tensor_rotated = imtransform(tensor,...
        t_concord,'XData',[1 imageDim(2)], 'YData',[1 imageDim(1)]);
    meanImage = mean(tensor_rotated,3);%imageData.meanImage;
    imageProc.V = reshape(tensor_rotated, size(tensor_rotated,1)*size(tensor_rotated,2),[]);
    clear tensor
    save(dataPaths.imageSaveName,'imageProc', '-append');
end


%% extract data within mask
load(dataPaths.imageSaveName,'imageData');
meanImage = imageData.meanImage;
if makeMask
    imagesc(imageData.meanImage);colormap(gray);
    roiAhand = images.roi.AssistedFreehand;
    draw(roiAhand);
    roi = createMask(roiAhand);
    nanMask = nan(size(roi));
    nanMask(roi) = 1;

    imageData.imstack = imageData.imstack.*(nanMask==1);
    imageData.imageMeans = squeeze(mean(mean(imageData.imstack)));
else
    nanMask = nan(size(imageData.meanImage));
    %nanMask(226:275,101:150) = 1;
    %     nanMask = nan(318,300);
    %     nanMask(246:255,121:130) = 1;
    %nanMask = nan(300,246);
    %nanMask(226:250,61:75) = 1; %CJ231 periV1
    %nanMask(31*5:50*5,43*5)=1;%CJ231 fovea
    %nanMask(221:280,61:100) = 1; %CJ224 periV1V2
end
imageProc.nanMask = nanMask;

%analysis in 2023 June. recycle ROI from previous analysis in March 
% saveDirBase = '/mnt/dshi0006_market/Massive/processed/';
% expDate = [expInfo.date(1:4) filesep expInfo.date(5:6) filesep expInfo.date(7:8)];
% expName = num2str(expInfo.expID);
% resizeDir = ['resize' num2str(rescaleFac*100)];
% encodingSavePrefix = fullfile(saveDirBase,expDate,resizeDir,...
%     ['encoding_' regexprep(expDate, filesep,'_') '_' expName '_resize' ...
%     num2str(rescaleFac*100) roiSuffix]);
% encodingSavePrefix = [encodingSavePrefix '_nxv'];
% encodingSavePrefix = dataPaths.encodingSavePrefix(1:end-5);
% load([encodingSavePrefix '_summary.mat'],'summary');
% %nanMask = summary.mask;
% nanMask = nan(size(summary.RF_Cx));
% %nanMask(summary.roiIdx) = 1;
% nanMask(~isnan(summary.RF_Cx))=1;

[theseIdx, X,Y] = getROIIdx(nanMask);
meanImage = imageData.meanImage;%summary.thisROI;
save(dataPaths.roiSaveName, 'X','Y','theseIdx','meanImage');

 
%% temporal filtering of pixels within mask
Fs = 1/median(diff(imageProc.OETimes.camOnTimes));
imageProc.V = filtV(imageProc.V(theseIdx,:), Fs, procParam.cutoffFreq, procParam.lpFreq);


%% image means, resampled
imageProc_tmp = imageProc;
imageMeans_tmp = imageData.imageMeans;
if length(imageProc.OETimes.camOnTimes) < numel(imageMeans_tmp)
    imageMeans_tmp = imageMeans_tmp(1:numel(imageProc.OETimes.camOnTimes));
end
imageProc_tmp.V = filtV(imageMeans_tmp, Fs, procParam.cutoffFreq, procParam.lpFreq);
[imageMeans_proc] = prepareObserved(imageProc_tmp, dsRate);
save(dataPaths.roiSaveName, 'imageMeans_proc','-append');


%% convert processed signal to a format compatible with fitting
[observed, TimeVec_ds_c] = prepareObserved(imageProc, dsRate);
%< TODO: BETTER WAY TO DO DOWNSAMPLING?
%< observed is NOT saved

%% save as timetable
TT = timetable(seconds(TimeVec_ds_c), observed);%instantaneous
writetimetable(TT, dataPaths.timeTableSaveName);%slow
clear TT


%% motion-energy model computation from visual stimuli
if ~exist(dataPaths.stimSaveName,'file') 
    
    [stimInfo.stimXdeg, stimInfo.stimYdeg] = stimPix2Deg(stimInfo, stimXrange, stimYrange);
    screenPixNew = [max(stimYrange)-min(stimYrange)+1 max(stimXrange)-min(stimXrange)+1];
    stimInfo.width = stimInfo.width * screenPixNew(2)/stimInfo.screenPix(2);
    stimInfo.height = stimInfo.height * screenPixNew(1)/stimInfo.screenPix(1);
    stimInfo.screenPix = screenPixNew;
    
    %% prepare model output SLOW
    [S_fin, TimeVec_stim_cat] = saveGaborBankOut(dataPaths.moviePath, imageProc.cic, ...
        dsRate, gaborBankParamIdx, 0, stimYrange, stimXrange);
        
    %% save gabor filter output as .mat
    save( dataPaths.stimSaveName, 'TimeVec_stim_cat', 'S_fin', ...
        'gaborBankParamIdx', 'dsRate','cic','stimInfo');
else
    save( dataPaths.stimSaveName, 'cic','stimInfo','-append');
end
