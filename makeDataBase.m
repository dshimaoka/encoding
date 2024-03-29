%makeDataBase.m:
%this script process and save imaging  data(saveImageProcess), 
%that will be used for the model fitting (in MASSIVE) by wrapper_encoding.m
% as of 24/2, took 1.5h to complete


if ~ispc
    addpath(genpath('~/git'));
    addDirPrefs;
end

expID = 1;


roiSuffix = '';
stimSuffix = '';

%% imaging parameters
rescaleFac = 0.1;
doRegistration = 0; %17/10/23
procParam.cutoffFreq = 0.02; %0.1
procParam.lpFreq = []; %2
rotateInfo = [];
rebuildImageData = false;
makeMask = true;
uploadResult = true;
dsRate = 1;%[Hz] %sampling rate of hemodynamic coupling function


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
    
    [imageProc, cic, stimInfo] = saveImageProcess(expInfo, rescaleFac, ...
        rebuildImageData,doRegistration);
    
       
    
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

cic = imageProc.cic;
stimInfo = imageProc.stimInfo;
save(dataPaths.imageSaveName, 'cic','stimInfo','-append');


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
    
    [theseIdx, X,Y] = getROIIdx(nanMask);
    meanImage = imageData.meanImage;%summary.thisROI;
    save(dataPaths.roiSaveName, 'X','Y','theseIdx','meanImage');

else
    load(dataPaths.roiSaveName, 'X','Y','theseIdx','meanImage');
    nanMask = nan(size(imageData.meanImage));
    nanMask(theseIdx) = 1;
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


 
%% temporal filtering of pixels within mask
filterEachPix = 1;
Fs = 1/median(diff(imageProc.OETimes.camOnTimes));
imageProc.V = filtV(imageProc.V(theseIdx,:), Fs, procParam.cutoffFreq, ...
procParam.lpFreq, filterEachPix);


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



