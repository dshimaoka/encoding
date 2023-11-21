function trainAndSimulate(trainParam, ds, S_fin, roiIdx, trainIdx, stimInfo, ...
    imageMeans_proc, gaborBankParamIdx, encodingSaveName, inSilicoRFStimName,...
    inSilicoORSFStimName,analysisTwin,...
    doTrain, doRF, doORSF)

%from wrapper_encoding.m

if doTrain
    %% fitting!
    tic;
    lagRangeS = [trainParam.lagFrames(1) trainParam.lagFrames(end)]/trainParam.Fs;
    trained = trainAneuron(ds, S_fin, roiIdx, trainIdx, trainParam.ridgeParam,  ...
        trainParam.KFolds, lagRangeS, ...
        trainParam.tavg, trainParam.useGPU, imageMeans_proc, trainParam.regressType);
    t1=toc %6s!
    screen2png([encodingSaveName(1:end-4) '_corr']);
    saveas(gcf,[encodingSaveName(1:end-4) '_corr.fig']);
    close;
    
    %clear S_fin
    save(encodingSaveName,'trained','trainParam');
else
    load(encodingSaveName,'trained','trainParam','RF_insilico');
end


%% in-silico simulation to obtain RF
if doRF
    %TODO load data tolocal
    RF_insilico.Fs_visStim = gaborBankParamIdx.predsRate;
    
    %load InSilicoRFstim data
    if exist(inSilicoRFStimName,'file')>0 && ~exist('inSilicoRFStim','var')
        noiseStim = load(inSilicoRFStimName, 'inSilicoRFStim','RF_insilico');
        inSilicoRFStim = noiseStim.inSilicoRFStim;
        RF_insilico.noiseRF = noiseStim.RF_insilico.noiseRF;
        clear noiseStim
    elseif  ~exist(inSilicoRFStimName,'file')
        disp(['Missing ' inSilicoRFStimName]);
    end
    
    %compute RF_insilico
    RF_insilico = getInSilicoRF(gaborBankParamIdx, trained, trainParam, ...
        RF_insilico, stimInfo.stimXdeg, stimInfo.stimYdeg,inSilicoRFStim);
    
    RF_insilico = analyzeInSilicoRF(RF_insilico, -1, analysisTwin);
    showInSilicoRF(RF_insilico, analysisTwin);
    screen2png([encodingSaveName(1:end-4) '_RF']);
    close;
    save(encodingSaveName,'RF_insilico','-append');
end

%% in-silico simulation to obtain ORSF
if doORSF
    if exist(inSilicoORSFStimName,'file') && ~exist('inSilicoORSFStim','var')
        ORSFStim = load(inSilicoORSFStimName, 'inSilicoORSFStim','RF_insilico');
        inSilicoORSFStim = ORSFStim.inSilicoORSFStim;
        RF_insilico.ORSF = ORSFStim.RF_insilico.ORSF;
        clear ORSFStim
    elseif  ~exist(inSilicoORSFStimName,'file')
        disp(['Missing ' inSilicoORSFStimName]);
    end
    
    stimSz = [stimInfo.height stimInfo.width];

    RF_insilico = getInSilicoORSF(gaborBankParamIdx, trained, trainParam, ...
        RF_insilico, stimSz, inSilicoORSFStim);
    showInSilicoORSF(RF_insilico);
    
    RF_insilico = analyzeInSilicoORSF(RF_insilico, -1, analysisTwin, 1);
    screen2png([encodingSaveName(1:end-4) '_ORSF']);
    close;
    save(encodingSaveName,'RF_insilico','-append');
end
end