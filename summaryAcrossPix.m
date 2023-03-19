if ~ispc
    addpath(genpath('~/git'));
    addDirPrefs;
end


ID = 1;
useGPU = 1;
rescaleFac = 0.10;
dsRate = 1;
reAnalyze = 1;
ORSFfitOption = 1; %3:peakSF,fitOR


%% path
expInfo = getExpInfoNatMov(ID);
dataPaths = getDataPaths(expInfo,rescaleFac);
%TODO: save data locally
%dataPaths.encodingSavePrefix = ['Z:\Shared\Daisuke\recording\processed\2022\11\30\resize10_obs\encoding_2022_11_30_16_resize10'];
encodingSavePrefix = [dataPaths.encodingSavePrefix '_nxv'];

load(dataPaths.imageSaveName, 'imageData','X','Y');%SLOOOOW!!!
thisROI = imageData.meanImage; %153x120
roiIdx = 1:numel(X);
clear imageData;

load(dataPaths.imageSaveName,'stimInfo')
stimSz = [stimInfo.height stimInfo.width];
clear stimInfo;

load( dataPaths.stimSaveName, 'gaborBankParamIdx');

%[Y,X,Z] = ind2sub(size(thisROI), roiIdx);

scrSz = size(thisROI);
RF_Cx = nan(numel(thisROI),1);
RF_Cy = nan(numel(thisROI),1);
RF_sigma = nan(numel(thisROI),1);
RF_mean =cell(numel(thisROI),1);% nan(scrSz(1), scrSz(2),18,32);
expVal = nan(numel(thisROI),1);
correlation = nan(numel(thisROI),1);
bestSF = nan(numel(thisROI),1);
bestOR = nan(numel(thisROI),1);
bestAmp = nan(numel(thisROI),1);
ridgeParam = nan(numel(thisROI),1);
ngIdx = [];
tic; %18h for CJ224 @officePC
for ii = 1:numel(roiIdx)
    disp(ii)
    encodingSaveName = [encodingSavePrefix '_roiIdx' num2str(roiIdx(ii)) '.mat'];
    if exist(encodingSaveName,'file')
        encodingResult = load(encodingSaveName, 'RF_insilico','trained','trainParam');
        RF_insilico = encodingResult.RF_insilico;
        trained = encodingResult.trained;
        trainParam = encodingResult.trainParam;
    else
        disp(['MISSING ' encodingSaveName]);
        ngIdx = [ngIdx roiIdx(ii)];
        continue;
    end
    
    correlation(ii) = trained.corr;
    expVal(ii) = trained.expval;
    ridgeParam(ii) = trained.ridgeParam_optimal;

    %% RF
    %trange = [0 trainParam.lagFrames(end)/dsRate];
    trange = [2 trainParam.lagFrames(end)/dsRate];

    if reAnalyze
        if ID==2
            xlim = [-10 inf];
        else
            xlim = [-inf 5];
        end
        ylim = [];
        RF_insilico = analyzeInSilicoRF(RF_insilico, -1, trange, xlim, ylim);
    end
    %showInSilicoRF(RF_insilico, analysisTwin);
            
    RF_Cx(ii) = RF_insilico.noiseRF.RF_Cx;
    RF_Cy(ii) = RF_insilico.noiseRF.RF_Cy;
    RF_sigma(ii) = RF_insilico.noiseRF.sigma;
    
    tidx = find(RF_insilico.noiseRF.RFdelay>=trange(1) & RF_insilico.noiseRF.RFdelay<=trange(2));
    RF_mean{ii} = mean(RF_insilico.noiseRF.RF(:,:,tidx),3);  
    
    
    %% ORSF ... too heavy for officePC
    try
        if reAnalyze
            RF_insilico = analyzeInSilicoORSF(RF_insilico, -1, trange, ORSFfitOption); 
        end
        bestSF(ii) = RF_insilico.ORSF.bestSF;
        bestOR(ii) = RF_insilico.ORSF.bestOR;
    catch err
        ngIdx = [ngIdx ii];
    end
    %bestAmp(ii) = amp;   
end
t = toc;


%% convert to 2D
RF_Cx2 = nan(size(thisROI));
RF_Cy2 = nan(size(thisROI));
RF_sigma2 = nan(size(thisROI));
bestSF2 = nan(size(thisROI));
bestOR2 = nan(size(thisROI));
expVal2 = nan(size(thisROI));
correlation2 = nan(size(thisROI));
ridgeParam2 = nan(size(thisROI));
RF_mean2 = nan(size(thisROI,1),size(thisROI,2),RF_insilico.noiseRF.screenPix(1),...
    RF_insilico.noiseRF.screenPix(2));
for ii = 1:numel(roiIdx)
    try
        RF_Cx2(Y(roiIdx(ii)),X(roiIdx(ii))) = RF_Cx(ii);
        RF_Cy2(Y(roiIdx(ii)),X(roiIdx(ii))) = RF_Cy(ii);
        expVal2(Y(roiIdx(ii)),X(roiIdx(ii))) = expVal(ii);
        correlation2(Y(roiIdx(ii)),X(roiIdx(ii))) = correlation(ii);
        ridgeParam2(Y(roiIdx(ii)),X(roiIdx(ii))) = ridgeParam(ii);
        RF_mean2(Y(roiIdx(ii)),X(roiIdx(ii)),:,:) = RF_mean{ii};
        bestSF2(Y(roiIdx(ii)),X(roiIdx(ii))) = bestSF(ii);
        bestOR2(Y(roiIdx(ii)),X(roiIdx(ii))) = bestOR(ii);
        RF_sigma2(Y(roiIdx(ii)),X(roiIdx(ii))) = RF_sigma(ii);
    catch err
        continue
    end
end

summary.RF_Cx = RF_Cx2;
summary.RF_Cy = RF_Cy2;
summary.RF_sigma = RF_sigma2;
summary.RF_mean = RF_mean2;
summary.ridgeParam = ridgeParam2;
summary.RF_mean = RF_mean2;
summary.bestSF = bestSF2;
summary.bestOR = bestOR2;
summary.expVar = expVal2;
summary.correlation = correlation2;
summary.thisROI = thisROI;
summary.roiIdx = roiIdx;


%%vfs
sfFac = 1;
prefMaps_xy(:,:,1)=summary.RF_Cx;
prefMaps_xy(:,:,2)=summary.RF_Cy;
summary.vfs=getVFS(prefMaps_xy, sfFac);

save([dataPaths.encodingSavePrefix '_summary'],'summary');

%% adjust Cx and Cy
switch ID
    case {1,2}
        fvY = 50;
        fvX = 40;
    case 3
        fvY = 50;
        fvX = 29;
end
summary_adj = summary;
summary_adj.RF_Cx = summary.RF_Cx - summary.RF_Cx(fvY,fvX);
summary_adj.RF_Cy = summary.RF_Cy - summary.RF_Cy(fvY,fvX);


%% summary figure
[sumFig, sumAxes]=showSummaryFig(summary_adj);
set(sumFig,'position',[0 0 1900 1000]);
set(sumAxes(2),'clim', [-8 8]);
set(sumAxes(3),'clim', [-5 5]);
screen2png([dataPaths.encodingSavePrefix '_summary_adj']);


%% show mRFs
yy = 51+(1:5);
xx = 13+(1:5:30);
stimXaxis = RF_insilico.noiseRF.xaxis;
stimYaxis = RF_insilico.noiseRF.yaxis;
[f_panel, f_location] = showRFpanels(summary, xx, yy, stimXaxis, stimYaxis);
