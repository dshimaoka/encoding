if ~ispc
    addpath(genpath('~/git'));
    addDirPrefs;
end


ID = 2;
useGPU = 1;
rescaleFac = 0.50;
dsRate = 1;
reAnalyze = 0;
ORSFfitOption = 1; %3:peakSF,fitOR
roiSuffix = '_Fovea';%'_v1v2_s_01hz_gparam11';
stimSuffix = '_right';
regressSuffix = '_nxv';

pixPermm = 31.25*rescaleFac; %cf note_magnificationFactor.m

%% path
expInfo = getExpInfoNatMov(ID);
dataPaths = getDataPaths(expInfo,rescaleFac, roiSuffix, stimSuffix);
encodingSavePrefix = [dataPaths.encodingSavePrefix regressSuffix];

%load(dataPaths.imageSaveName, 'imageData','X','Y');%SLOOOOW!!!
load(dataPaths.roiSaveName, 'X','Y','theseIdx','meanImage');
thisROI = meanImage; %153x120
roiIdx = 1:numel(X);
%clear imageData;

load(dataPaths.stimSaveName,'stimInfo')
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
        switch ID
            case {2,4}
                xlim = [-10 inf];
            case {1,3}
                xlim = [-inf 5];
            case {6}
                xlim = [-10 15];
            case {7}
                xlim = [-10 inf];
        end
        ylim = [];
        RF_insilico = analyzeInSilicoRF(RF_insilico, -1, trange, xlim, ylim);
    end
    %showInSilicoRF(RF_insilico, trange);
            
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
        %ngIdx = [ngIdx ii];
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

mask = nan(size(thisROI));
for ii = 1:numel(roiIdx)
    mask(Y(roiIdx(ii)),X(roiIdx(ii))) = 1;
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
summary.mask = mask;


%%vfs
sfFac = 1;
prefMaps_xy = [];
prefMaps_xy(:,:,1)=summary.RF_Cx;
prefMaps_xy(:,:,2)=summary.RF_Cy;
summary.vfs=getVFS(prefMaps_xy, sfFac);

save([encodingSavePrefix '_summary'],'summary');

summary_part = [];
for ii = 1:length(roiIdx)
    summary_part.RF_Cx_s(ii) = summary.RF_Cx(Y(roiIdx(ii)),X(roiIdx(ii)));
    summary_part.RF_Cy_s(ii) = summary.RF_Cy(Y(roiIdx(ii)),X(roiIdx(ii)));
    summary_part.RF_sigma_s(ii) = summary.RF_sigma(Y(roiIdx(ii)),X(roiIdx(ii)));
    summary_part.bestOR_s(ii) = summary.bestOR(Y(roiIdx(ii)),X(roiIdx(ii)));
    summary_part.bestSF_s(ii) = summary.bestSF(Y(roiIdx(ii)),X(roiIdx(ii)));
    summary_part.expVar_s(ii) = summary.expVar(Y(roiIdx(ii)),X(roiIdx(ii)));
    summary_part.correlation_s(ii) = summary.correlation(Y(roiIdx(ii)),X(roiIdx(ii)));
end
save([encodingSavePrefix '_summary_part'],'summary_part');

for kk = 1:3
    switch kk
        case 1
            load('\\storage.erc.monash.edu.au\shares\MNHS-dshi0006\Massive\processed\2022\11\30\resize10\encoding_2022_11_30_16_resize10_nxv_summary_part.mat','summary_part');
        case 2
            load('\\storage.erc.monash.edu.au\shares\MNHS-dshi0006\Massive\processed\2022\11\30\resize10\encoding_2022_11_30_16_resize10_Fovea_right_nxv_gpu_summary_part.mat','summary_part');
        case 3
            load('\\storage.erc.monash.edu.au\shares\MNHS-dshi0006\Massive\processed\2022\11\30\resize10\encoding_2022_11_30_16_resize10_Fovea_right_nxv_cpu_summary_part.mat','summary_part');
    end
    subplot(2,4,1);
    plot(summary_part.RF_Cx_s); hold on;title('Cx');
    subplot(2,4,2);
    plot(summary_part.RF_Cy_s); hold on;title('Cy');
    subplot(2,4,3);
    plot(summary_part.RF_sigma_s); hold on;title('sigma');
    subplot(2,4,4);
    plot(summary_part.bestOR_s); hold on;title('OR');
    subplot(2,4,5);
    plot(summary_part.bestSF_s); hold on;title('SF')
    subplot(2,4,6);
    plot(summary_part.expVar_s); hold on;title('expvar');
    subplot(2,4,7);
    plot(summary_part.correlation_s); hold on;title('correlation');
    clear summary_part
end
legend('2023 march - GPU 144x256pix','GPU restricted visual field 56x56pix','CPU restricted visual field 56x56pix');
xlabel('pixel number');


% % 
% % %% summary figure
% % %summary_adj.mask = summary.mask .* (summary_adj.correlation>corr_th);
% % [sumFig, sumAxes]=showSummaryFig(summary);
% % set(sumFig,'position',[0 0 1900 1400]);
% % set(sumAxes(2),'xlim',[min(X) max(X)]);
% % set(sumAxes(2),'ylim',[min(Y) max(Y)]);
% % % set(sumFig,'position',[0 0 1900 1000]);
% % % set(sumAxes(2),'clim', [-8 8]);
% % % set(sumAxes(3),'clim', [-10 10]);
% % savePaperFigure(sumFig,[encodingSavePrefix '_summary']);
% % 
% % 
% % %% show mRFs
% % brain_y = 26;%20+(1:5:20);%unique(Y);%
% % brain_x = 13:19;%13+(1:6:20);;%unique(X);%
% % stimXaxis = RF_insilico.noiseRF.xaxis; %- summary.RF_Cx(fvY,fvX);
% % stimYaxis = -(RF_insilico.noiseRF.yaxis);% - summary.RF_Cy(fvY,fvX));
% % [f_panel, f_location] = showRFpanels(summary, brain_x, brain_y, stimXaxis, stimYaxis);
% % set(f_panel,'position',[0 0 1900 1400]);
% % set(f_location,'position',[0 0 1900 1400]);
% % savePaperFigure(f_panel,[encodingSavePrefix '_mRFs']);
% % savePaperFigure(f_location,[encodingSavePrefix '_mRFlocs'], 'w');
% % 

