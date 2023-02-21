%wrapper_encoding.m
%this script loads processed data by makeDataBase.m,
%fit one pixel with ridge regression
%evaluate the fit result with in-silico simulation

%% draw slurm ID for parallel computation
pen = getPen;

expInfo.subject = 'CJ224';
expInfo.date = '20221004';
expInfo.nsName = 'CJ224.runPassiveMovies.033059';
expInfo.expID = 19;

rescaleFac = 0.25;
%roiIdx = 7618;%1658;%roiIdx_tmp(noNanIdx);
roiIdx = 1;


%% path
dataPaths = getDataPaths(expInfo,rescaleFac);

% load( dataPaths.stimSaveName, 'dsRate'); %NEI FIX THIS
predsRate = 15; %hz
dsRate = [1 5];%[1 2 5 10];
delayMax = (pen+1); %[s]

for jj = 2    
   
    suffix = ['_dsRate' num2str(dsRate(jj))];
    suffix2 = [];%['_predsRate' num2str(predsRate)];
    
    %% estimation of filter-bank coefficients
    trainParam.KFolds = 5; %cross validation
    trainParam.ridgeParam = [1 1e3 1e5 1e7]; %search the best within these values
    trainParam.tavg = 1; %tavg = 0 requires loads of ram. if 0, use avg within Param.lagFrames to estimate coefficients
    trainParam.Fs = dsRate(jj); %hz after downsampling
    trainParam.lagFrames = round(0*dsRate(jj)):round(delayMax*dsRate(jj));%3:9 %frame delays to train a neuron
    trainParam.useGPU = 1; %for ridgeXs local GPU is not sufficient
    
    
    %% stimuli
    load(dataPaths.imageSaveName,'cic')
    stimInfo = getStimInfo(cic);
    
    nMovies = cic.nrTrials;
    movDur = stimInfo.duration;%[s]
    omitSec = 5; %omit initial XX sec for training
    trainIdx = [];
    for imov = 1:nMovies
        trainIdx = [trainIdx (omitSec*dsRate(jj)+1:movDur*dsRate(jj))+(imov-1)*movDur*dsRate(jj)];
    end
    %testIdx = (omitSec*dsRate(jj):movDur*dsRate(jj))+(nMovies-1)*movDur*dsRate(jj); %not really useful for testing - may have some abnormality at the start of stimulation
    
    
    %% in-silico simulation
    RF_insilico = struct;
    RF_insilico.nRepeats = 40;
    RF_insilico.screenPix = stimInfo.screenPix/4; %[y x]
    %<screenPix(1)/screenPix(2) determines the #gabor filters
    
    
    %% draw slurm ID for parallel computation
    pen = getPen;
    
    %% load neural data
    %TODO: copy timetable data to local
    ds = tabularTextDatastore([dataPaths.timeTableSaveName(1:end-4) suffix '.csv']);
    
    
    %% load gabor bank prediction data
    %TODO load data tolocal
    load( [dataPaths.stimSaveName(1:end-4) suffix suffix2 '.mat'], ...
        'TimeVec_stim_cat', 'S_fin','gaborBankParamIdx');
    
    % S_fin_train = single(S_fin(trainIdx,:));
    % S_fin_test = single(S_fin(testIdx,:));
    % nFilters = size(S_fin,2);
    
    %% estimate the energy-model parameters w cross validation
    tic;
    trained = trainAneuron(ds, S_fin, roiIdx, trainIdx, trainParam.ridgeParam,  ...
        trainParam.KFolds, [trainParam.lagFrames(1) trainParam.lagFrames(end)], ...
        trainParam.tavg, trainParam.useGPU);
    t1=toc %6s!
    
    
    
    %TODO: save data locally
    encodingSaveName = [dataPaths.encodingSavePrefix '_roiIdx' num2str(roiIdx) ...
        '_delayMax' num2str(delayMax) suffix suffix2 '.mat'];
    save(encodingSaveName,'trained','trainParam');%'rre','r0e','mse','lagFrames','tavg')
      
    set(gcf,'position',[0 0 1900 1000])
    screen2png([encodingSaveName(1:end-4) '_tcourse']);
    close;
    
 
end
%TODO: upload result to server
