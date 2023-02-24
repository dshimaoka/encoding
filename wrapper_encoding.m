%wrapper_encoding.m
%this script loads processed data by makeDataBase.m,
%fit one pixel with ridge regression
%evaluate the fit result with in-silico simulation

if ~ispc
    addpath(genpath('~/git'));
    addDirPrefs;
end

expInfo.subject = 'CJ224';
expInfo.date = '20221004';
expInfo.nsName = 'CJ224.runPassiveMovies.033059';
expInfo.expID = 19;

doTrain = 1; %train a gabor bank filter or use it for insilico simulation
omitSec = 5; %omit initial XX sec for training
rescaleFac = 0.25;
%roiIdx = 7618;%1658;%roiIdx_tmp(noNanIdx);

%% draw slurm ID for parallel computation specifying ROI position
if ~ispc
    pen = getPen + 7617;
else
    pen = 7618;
end


%% path
dataPaths = getDataPaths(expInfo,rescaleFac);
%TODO: save data locally
encodingSaveName = [dataPaths.encodingSavePrefix '_roiIdx' num2str(pen) '.mat'];

load( dataPaths.stimSaveName, 'dsRate', 'gaborBankParamIdx'); %NEI FIX THIS


%% estimation of filter-bank coefficients
trainParam.KFolds = 5; %cross validation
trainParam.ridgeParam = [1 1e3 1e5 1e7]; %search the best within these values
trainParam.tavg = 0; %tavg = 0 requires 32GB ram. if 0, use avg within Param.lagFrames to estimate coefficients
trainParam.Fs = dsRate; %hz after downsampling
trainParam.lagFrames = round(0/dsRate):round(5/dsRate);%0:6;%3:6;%0:9 %frame delays to train a neuron
trainParam.useGPU = 1; %for ridgeXs local GPU is not sufficient


%% stimuli
load(dataPaths.imageSaveName,'stimInfo')

%% in-silico simulation
RF_insilico = struct;
RF_insilico.noiseRF.nRepeats = 5;
RF_insilico.noiseRF.dwell = 15; %frames
RF_insilico.screenPix = stimInfo.screenPix/4; %[y x]
%<screenPix(1)/screenPix(2) determines the #gabor filters



% load(dataPaths.imageSaveName, 'imageData');
% thisROI = imageData.meanImage;
% clear imageData;
% [Y,X,Z] = ind2sub(size(thisROI), roiIdx(pen));

if doTrain
    %% load gabor bank prediction data
    %TODO load data tolocal
    load( dataPaths.stimSaveName, 'TimeVec_stim_cat', 'S_fin','gaborBankParamIdx');
    RF_insilico.Fs_visStim = gaborBankParamIdx.predsRate;
    
    %% estimate the energy-model parameters w cross validation
    nMovies = numel(stimInfo.stimLabels);
    movDur = stimInfo.duration;%[s]
    trainIdx = [];
    for imov = 1:nMovies
        trainIdx = [trainIdx (omitSec*dsRate+1:movDur*dsRate)+(imov-1)*movDur*dsRate];
    end
    
    %% load neural data
    %TODO: copy timetable data to local
    ds = tabularTextDatastore(dataPaths.timeTableSaveName);

    tic;
    lagRangeS = [trainParam.lagFrames(1) trainParam.lagFrames(end)]/trainParam.Fs;
    trained = trainAneuron(ds, S_fin, roiIdx, trainIdx, trainParam.ridgeParam,  ...
        trainParam.KFolds, lagRangeS, ...
        trainParam.tavg, trainParam.useGPU);
    t1=toc %6s!
    
    save(encodingSaveName,'trained','trainParam');
else
    load(encodingSaveName,'trained','trainParam');
end


%% in-silico simulation to obtain RF
tic
RF_insilico = getInSilicoRF(gaborBankParamIdx, trained, trainParam, RF_insilico, ...
    [stimInfo.height stimInfo.width]);
t2=toc

analysisTwin = [0 trainParam.lagFrames(end)/dsRate];
RF_insilico = analyzeInSilicoRF(RF_insilico, -1, analysisTwin);
showInSilicoRF(RF_insilico, analysisTwin);
screen2png([encodingSaveName(1:end-4) '_RF_dwell' num2str(dwells(rr))]);

%RF_insilico = getInSilicoORSF(gaborBankParamIdx, trained, trainParam, RF_insilico);

% %looks like RF_Cx and RF_Cy is swapped??
save(encodingSaveName,'RF_insilico','-append');

%TODO: upload result to server
