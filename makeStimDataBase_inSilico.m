%% create stimuli for in-silico simulation. moved from wrapper_encoding
%stimInfo
%stimSz = [stimInfo.height stimInfo.width];
%gaborBankParamIdx
%dsRate

if isempty(getenv('COMPUTERNAME'))
    addpath(genpath('~/git'));
    % addDirPrefs; %BAD IDEA TO write matlabprefs.mat in a batch job!!
    [~,narrays] = getArray('script_wrapper.sh');
else
    narrays = 1;
end
%% draw slurm ID for parallel computation specifying ROI position
pen = getPen;

IDs = [1 2 3 8 9];

doRF = 0;
doORSF = 0;
doDIRSFTF = 1;

dsRate = 1;%[Hz] %sampling rate of hemodynamic coupling function
rescaleFac = 0.1;
roiSuffix = '';


for ididx = 1:numel(IDs)
    
    expID = IDs(pen + (ididx-1)*narrays);
    
    aparam = getAnalysisParam(expID);
    stimSuffix = aparam.stimSuffix;
    
    
    %stimulus parameters - must be identical to ones in makeStimDataBase.m
    switch expID
        case 1
            stimXrange = 24:156; %201:256; %1:left
            stimYrange = 5:139; %72-28+1:72+28;  %1:top
        case 2
            stimXrange = 161:238;
            stimYrange = 29:108;
        case 3
            stimXrange = 24:156; %201:256; %1:left
            stimYrange = 5:139; %72-28+1:72+28;  %1:top
        case 8
            stimXrange = 293:1080;
            stimYrange = 293:1080;
        case 9
            stimXrange = 816:1616;
            stimYrange = 280:1080;
    end
    
    % gabor bank filter
    gaborBankParamIdx.cparamIdx = 1;
    gaborBankParamIdx.gparamIdx = 2; %4 for only small RFs
    gaborBankParamIdx.nlparamIdx = 1;
    gaborBankParamIdx.dsparamIdx = 1;
    gaborBankParamIdx.nrmparamIdx = 1;
    gaborBankParamIdx.predsRate = 15; %Hz %mod(dsRate, predsRate) must be 0
    
    expInfo = getExpInfoNatMov(expID);
    dataPaths = getDataPaths(expInfo, rescaleFac, roiSuffix, stimSuffix);
    
    %% load cic and stimInfo
    load(dataPaths.imageSaveName,'cic','stimInfo');
    
    %% modify stimInfo
    [stimInfo.stimXdeg, stimInfo.stimYdeg] = stimPix2Deg(stimInfo, stimXrange, stimYrange);
    screenPixNew = [max(stimYrange)-min(stimYrange)+1 max(stimXrange)-min(stimXrange)+1];
    stimInfo.width = stimInfo.width * screenPixNew(2)/stimInfo.screenPix(2);
    stimInfo.height = stimInfo.height * screenPixNew(1)/stimInfo.screenPix(1);
    stimInfo.screenPix = screenPixNew;
    
    %% save in-silico data
    inSilicoRFStimName = [dataPaths.stimSaveName(1:end-4) '_insilicoRFstim.mat'];
    inSilicoORSFStimName = [dataPaths.stimSaveName(1:end-4) '_insilicoORSFstim.mat'];
    inSilicoDIRSFTFStimName = [dataPaths.stimSaveName(1:end-4) '_insilicoDIRSFTFstim.mat'];
    stimSz = [stimInfo.height stimInfo.width];
    
    if doRF
        RF_insilico = struct;
        RF_insilico.noiseRF.nRepeats = 80; %10 FIX
        RF_insilico.noiseRF.dwell = 15; %frames
        fac = mean(stimInfo.screenPix)/20; %NG18
        RF_insilico.noiseRF.screenPix = round(stimInfo.screenPix/fac);%4 %[y x] %FIX %spatial resolution of noise stimuli
        RF_insilico.noiseRF.maxRFsize = 10; %deg in radius
        
        try
            [inSilicoRFStim] = ...
                getInSilicoRFstim(gaborBankParamIdx, RF_insilico, dsRate, 1);
        catch err
            [inSilicoRFStim] = ...
                getInSilicoRFstim(gaborBankParamIdx, RF_insilico, dsRate, 0);
        end
        save(inSilicoRFStimName, 'inSilicoRFStim','gaborBankParamIdx',"RF_insilico",'-v7.3');
    end
    
    
    
    %% ORSF
    if doORSF
        ORSFfac = max(ceil(stimInfo.screenPix/300));
        RF_insilico = struct;
        RF_insilico.ORSF.screenPix = round(stimInfo.screenPix/ORSFfac); %/2 [y x]
        nORs = 10;
        oriList = pi/180*linspace(0,180,nORs+1)'; %[rad]
        RF_insilico.ORSF.oriList = oriList(1:end-1);
        SFrange_stim = [0.035 2.5];
        %SFrange_stim = getSFrange_stim(RF_insilico.ORSF.screenPix, stimSz);
        %SFrange_mdl = getSFrange_mdl(RF_insilico.ORSF.screenPix, stimSz, gaborBankParamIdx.gparamIdx);
        %RF_insilico.ORSF.sfList = logspace(log10(SFrange_stim(1)), log10(SFrange_stim(2)), 6); %5 %[cycles/deg];
        RF_insilico.ORSF.sfList = linspace(SFrange_stim(1), SFrange_stim(2), 12); %5 %[cycles/deg];
        RF_insilico.ORSF.nRepeats = 10;% 15;
        RF_insilico.ORSF.dwell = 45; %#stimulus frames
        
        try
            [inSilicoORSFStim] = ...
                getInSilicoORSFstim(gaborBankParamIdx, RF_insilico, dsRate, stimSz, 1);
        catch err
            [inSilicoORSFStim] = ...
                getInSilicoORSFstim(gaborBankParamIdx, RF_insilico, dsRate, stimSz, 0);
        end
        save(inSilicoORSFStimName, 'inSilicoORSFStim','gaborBankParamIdx',"RF_insilico",'stimSz','-v7.3');
    end
    
    %% ORSF
    if doDIRSFTF
        DIRSFTFfac = max(ceil(stimInfo.screenPix/300));
        RF_insilico = struct;
        RF_insilico.DIRSFTF.screenPix = round(stimInfo.screenPix/DIRSFTFfac); %/2 [y x]
        nORs = 8;
        dirList = pi/180*linspace(0,360,nORs+1)'; %[rad]
        RF_insilico.DIRSFTF.dirList = dirList(1:end-1);
        SFrange_stim = [0.035 2.5];
        RF_insilico.DIRSFTF.sfList = linspace(SFrange_stim(1), SFrange_stim(2), 12); %12 %[cycles/deg];
        RF_insilico.DIRSFTF.tfList = [.25 .5 1 2 4]; %[Hz]
        RF_insilico.DIRSFTF.nRepeats = 10;
        RF_insilico.DIRSFTF.dwell = 45; %#stimulus frames
        
        try
            [inSilicoDIRSFTFStim] = ...
                getInSilicoDIRSFTFstim(gaborBankParamIdx, RF_insilico, dsRate, stimSz, 1);
        catch err
            [inSilicoDIRSFTFStim] = ...
                getInSilicoDIRSFTFstim(gaborBankParamIdx, RF_insilico, dsRate, stimSz, 0);
        end
        save(inSilicoDIRSFTFStimName, 'inSilicoDIRSFTFStim','gaborBankParamIdx',"RF_insilico",'stimSz','-v7.3');
    end
end