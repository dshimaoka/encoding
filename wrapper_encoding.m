%wrapper_encoding.m
%this script loads processed data by makeDataBase.m,
%fit one pixel with ridge regression
%evaluate the fit result with in-silico simulation

if ~ispc
    addpath(genpath('~/git'));
    % addDirPrefs; %BAD IDEA TO write matlabprefs.mat in a batch job!!    
    [~,narrays] = getArray('script_wrapper.sh');
else
    narrays = 1;
end


ID = 2;
doTrain = 1; %train a gabor bank filter or use it for insilico simulation
doRF = 1;
doORSF = 1;
subtractImageMeans = 0;
roiSuffix = '_Fovea';%'_v1v2_s_01hz_gparam11';
stimSuffix = '_right';
regressSuffix = '_nxv_gpu';

omitSec = 5; %omit initial XX sec for training
rescaleFac = 0.1;%0.5;

expInfo = getExpInfoNatMov(ID);

%% draw slurm ID for parallel computation specifying ROI position    
pen = getPen; 
%narrays = 1000;
ngIdx = [];

    
%% path
dataPaths = getDataPaths(expInfo,rescaleFac,roiSuffix, stimSuffix);
dataPaths.encodingSavePrefix = [dataPaths.encodingSavePrefix regressSuffix];

load( dataPaths.stimSaveName, 'TimeVec_stim_cat', 'dsRate','S_fin',...
    'gaborBankParamIdx','stimInfo');
if subtractImageMeans
    load(dataPaths.roiSaveName, 'imageMeans_proc');
else
    imageMeans_proc = [];
end
%% estimation of filter-bank coefficients
trainParam.regressType = 'ridge';
trainParam.ridgeParam = 1e6;%logspace(5,7,3); %[1 1e3 1e5 1e7]; %search the best within these values
trainParam.KFolds = 5; %cross validation. Only valid if numel(ridgeParam)>1
trainParam.tavg = 0; %tavg = 0 requires 32GB ram. if 0, use avg within Param.lagFrames to estimate coefficients
trainParam.Fs = dsRate; %hz after downsampling
trainParam.lagFrames = 2:3;%2:9;%round(0/dsRate):round(5/dsRate);%frame delays to train a neuron
trainParam.useGPU = 1;%1; %for ridgeXs local GPU is not sufficient

%% in-silico simulation
analysisTwin = [2 trainParam.lagFrames(end)/dsRate];


%% stimuli
%load(dataPaths.imageSaveName,'stimInfo')
stimSz = [stimInfo.height stimInfo.width];


%% load neural data
%TODO: copy timetable data to local
disp('Loading tabular text datastore');
ds = tabularTextDatastore(dataPaths.timeTableSaveName);

nTotPix = numel(ds.VariableNames)-1;
if ~isempty(ngIdx)
    maxJID=1;
else
    maxJID = numel(pen:narrays:nTotPix);
end
for JID = 1:maxJID
    disp([num2str(JID) '/' num2str(maxJID)]);
    
    if ~isempty(ngIdx)
        roiIdx = ngIdx(pen);
    else
        roiIdx = pen + (JID-1)*narrays;
    end
    
    %TODO: save data locally
    encodingSaveName = [dataPaths.encodingSavePrefix '_roiIdx' num2str(roiIdx) '.mat'];
    
    %% in-silico RF estimation
    RF_insilico = struct;
    RF_insilico.noiseRF.nRepeats = 80; %10 FIX
    RF_insilico.noiseRF.dwell = 15; %frames
    RF_insilico.noiseRF.screenPix = stimInfo.screenPix/2;%8 %[y x] %FIX %spatial resolution of noise stimuli
    RF_insilico.noiseRF.maxRFsize = 10; %deg in radius
    %<screenPix(1)/screenPix(2) determines the #gabor filters
    
    
    %% in-silico ORSF estimation
    RF_insilico.ORSF.screenPix = stimInfo.screenPix; %[y x]
    nORs = 10;
    oriList = pi/180*linspace(0,180,nORs+1)'; %[rad]
    RF_insilico.ORSF.oriList = oriList(1:end-1);
    SFrange_stim = getSFrange_stim(RF_insilico.ORSF.screenPix, stimSz);
    RF_insilico.ORSF.sfList = logspace(log10(SFrange_stim(1)), log10(SFrange_stim(2)), 6); %[cycles/deg];
    RF_insilico.ORSF.nRepeats = 15;
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
            trainParam.tavg, trainParam.useGPU, imageMeans_proc, trainParam.regressType);
        t1=toc %6s!
        screen2png([encodingSaveName(1:end-4) '_corr']);
        close;
        
        %clear S_fin
        save(encodingSaveName,'trained','trainParam');
    else
        load(encodingSaveName,'trained','trainParam');
    end
    
    
    %% in-silico simulation to obtain RF
    if doRF
        RF_insilico = getInSilicoRF(gaborBankParamIdx, trained, trainParam, ...
            RF_insilico, stimInfo.stimXdeg, stimInfo.stimYdeg);
        
        RF_insilico = analyzeInSilicoRF(RF_insilico, -1, analysisTwin);
        showInSilicoRF(RF_insilico, analysisTwin);
        screen2png([encodingSaveName(1:end-4) '_RF']);
        close;        
        save(encodingSaveName,'RF_insilico','-append');
    end
    
    %% in-silico simulation to obtain ORSF
    if doORSF
        RF_insilico = getInSilicoORSF(gaborBankParamIdx, trained, trainParam, ...
            RF_insilico, stimSz, 3);
        showInSilicoORSF(RF_insilico);
        
        RF_insilico = analyzeInSilicoORSF(RF_insilico, -1, analysisTwin, 1);
        screen2png([encodingSaveName(1:end-4) '_ORSF']);
        close;        
        save(encodingSaveName,'RF_insilico','-append');
    end

end
