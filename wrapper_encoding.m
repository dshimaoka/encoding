%wrapper_encoding.m
%this script loads processed data by makeDataBase.m,
%fit one pixel with ridge regression
%evaluate the fit result with in-silico simulation

if ~ispc
    addpath(genpath('~/git'));
    addDirPrefs;
end

% expInfo.subject = 'CJ224';
% expInfo.date = '20221004';
% expInfo.nsName = 'CJ224.runPassiveMovies.033059';
% expInfo.expID = 19;
expInfo.nsName = 'CJ231.runPassiveMovies.010848';
expInfo.expID = 16;
expInfo.subject = 'CJ231';
expInfo.date = '20221130';


doTrain = 1; %train a gabor bank filter or use it for insilico simulation
omitSec = 5; %omit initial XX sec for training
rescaleFac = 0.10;%0.25;



%% draw slurm ID for parallel computation specifying ROI position
pen = getPen+1999; %1-narrays
narrays = 1000;

%% path
dataPaths = getDataPaths(expInfo,rescaleFac);

load( dataPaths.stimSaveName, 'dsRate', 'gaborBankParamIdx'); %NEI FIX THIS


%% estimation of filter-bank coefficients
trainParam.KFolds = 5; %cross validation
trainParam.ridgeParam = logspace(5,7,3); %[1 1e3 1e5 1e7]; %search the best within these values
trainParam.tavg = 0; %tavg = 0 requires 32GB ram. if 0, use avg within Param.lagFrames to estimate coefficients
trainParam.Fs = dsRate; %hz after downsampling
trainParam.lagFrames = round(0/dsRate):round(5/dsRate);%frame delays to train a neuron
trainParam.useGPU = 1; %for ridgeXs local GPU is not sufficient


%% stimuli
load(dataPaths.imageSaveName,'stimInfo')



%load(dataPaths.imageSaveName, 'nanMask');
%thisROI = imageData.meanImage;

load( dataPaths.stimSaveName, 'TimeVec_stim_cat', 'S_fin','gaborBankParamIdx');

%% load neural data
%TODO: copy timetable data to local
disp('Loading tabular text datastore');
ds = tabularTextDatastore(dataPaths.timeTableSaveName);


for JID = 1%:2
    roiIdx = pen + (JID-1)*narrays;
    
    %TODO: save data locally
    encodingSaveName = [dataPaths.encodingSavePrefix '_roiIdx' num2str(roiIdx) '.mat'];
    
    %% in-silico simulation
    RF_insilico = struct;
    RF_insilico.noiseRF.nRepeats = 80; %4
    RF_insilico.noiseRF.dwell = 15; %frames
    RF_insilico.noiseRF.screenPix = stimInfo.screenPix/8;%4 %[y x]
    %<screenPix(1)/screenPix(2) determines the #gabor filters
    
    RF_insilico.ORSF.screenPix = stimInfo.screenPix/4; %[y x]
    nORs = 10;
    oriList = pi/180*linspace(0,180,nORs+1)'; %[rad]
    RF_insilico.ORSF.oriList = oriList(1:end-1);
    %sfList = linspace(1/RF_insilico.ORSF.screenPix, 1/2, 5); %cycles per pixel
    sfList = [0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4]';
    RF_insilico.ORSF.sfList = sfList;
    RF_insilico.ORSF.nRepeats = 30;
    RF_insilico.ORSF.dwell = 45; %#stimulus frames
    
    
    if doTrain
        %% load gabor bank prediction data
        %TODO load data tolocal
        RF_insilico.Fs_visStim = gaborBankParamIdx.predsRate;
        
        %% estimate the energy-model parameters w cross validation
        nMovies = numel(stimInfo.stimLabels);
        movDur = stimInfo.duration;%[s]
        trainIdx = [];
        for imov = 1:nMovies
            trainIdx = [trainIdx (omitSec*dsRate+1:movDur*dsRate)+(imov-1)*movDur*dsRate];
        end
        
        
        %% fitting!
        tic;
        lagRangeS = [trainParam.lagFrames(1) trainParam.lagFrames(end)]/trainParam.Fs;
        trained = trainAneuron(ds, S_fin, roiIdx, trainIdx, trainParam.ridgeParam,  ...
            trainParam.KFolds, lagRangeS, ...
            trainParam.tavg, trainParam.useGPU);
        t1=toc %6s!
        screen2png([encodingSaveName(1:end-4) '_corr']);
        close;
        
        %clear S_fin
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
    screen2png([encodingSaveName(1:end-4) '_RF']);
    close;
    
%     RF_insilico = getInSilicoORSF(gaborBankParamIdx, trained, trainParam, RF_insilico, ...
%         [stimInfo.height stimInfo.width]);
%     showInSilicoORSF(RF_insilico);
%     RF_insilico = analyzeInSilicoORSF(RF_insilico, -1, [0 RF_insilico.ORSF.dwell/RF_insilico.ORSF.Fs_visStim]);
%     screen2png([encodingSaveName(1:end-4) '_ORSF']);
%     close;
    
    % %looks like RF_Cx and RF_Cy is swapped??
    save(encodingSaveName,'RF_insilico','-append');
    %par_save(encodingSaveName, 'trained','trainParam','RF_insilico');
end
