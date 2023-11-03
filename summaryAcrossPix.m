if ~ispc
    addpath(genpath('~/git'));
    addDirPrefs;
end


ID = 2;
useGPU = 1;
rescaleFac = 0.10;
dsRate = 1;
remakeSummary = 0;
reAnalyze = 1;
ORSFfitOption = 1; %3:peakSF,fitOR
roiSuffix = '';
stimSuffix = '_part';%'_square20';
regressSuffix = '_nxv';

%pixPermm = 31.25*rescaleFac;

%% path
expInfo = getExpInfoNatMov(ID);
dataPaths = getDataPaths(expInfo,rescaleFac, roiSuffix, stimSuffix);
%TODO: save data locally5
%TMP
encodingSavePrefix = [dataPaths.encodingSavePrefix regressSuffix];

%load(dataPaths.imageSaveName, 'imageData','X','Y');%SLOOOOW!!!
load(dataPaths.roiSaveName, 'X','Y','theseIdx','meanImage');
thisROI = meanImage; %153x120
roiIdx = 1:numel(X);
%clear imageData;

load(dataPaths.stimSaveName,'stimInfo')
stimSz = [stimInfo.height stimInfo.width];
if ID==3
    xlim = [-5 1]-3;
    ylim = [-4 6];
elseif ID==8 || ID==9
    xlim = [-7 2];%[-8 2];
    ylim = [-15 9.14];
else
    xlim = prctile(stimInfo.stimXdeg,[0 100]);
    ylim = prctile(stimInfo.stimYdeg,[0 100]);
end
%         switch ID
%             case {2,4}
%                 xlim = [-10 inf];
%             case {1,3}
%                 xlim = [-inf 5];
%             case {6}
%                 xlim = [-10 15];
%             case {7}
%                 xlim = [-10 inf];
%         end
%         ylim = [];

clear stimInfo;

load( dataPaths.stimSaveName, 'gaborBankParamIdx');

%[Y,X,Z] = ind2sub(size(thisROI), roiIdx);

if remakeSummary
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
            try
                encodingResult = load(encodingSaveName, 'RF_insilico','trained','trainParam');
                RF_insilico = encodingResult.RF_insilico;
                trained = encodingResult.trained;
                trainParam = encodingResult.trainParam;
            catch err
                disp(['MISSING ' encodingSaveName]);
                ngIdx = [ngIdx roiIdx(ii)];
                continue;
            end
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
            if ID==8
                RF_insilico.noiseRF.maxRFsize=7;%5;%3.5;
            end
            RF_insilico = analyzeInSilicoRF(RF_insilico, -1, trange, xlim, ylim);
            %showInSilicoRF(RF_insilico, trange);
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
    
else
    load([encodingSavePrefix '_summary'],'summary');
    encodingSaveName = [encodingSavePrefix '_roiIdx' num2str(roiIdx(1)) '.mat'];
    load(encodingSaveName, 'RF_insilico');
end

%% adjust Cx and Cy, interpolate NANs
[fvY,fvX] = getFoveaPix(ID, rescaleFac);
summary_adj = summary;
summary_adj.RF_Cx = interpNanImages(summary.RF_Cx - summary.RF_Cx(fvY,fvX));
summary_adj.RF_Cy = interpNanImages((summary.RF_Cy - summary.RF_Cy(fvY,fvX)));
summary_adj.RF_sigma = interpNanImages(summary_adj.RF_sigma);
summary_adj.RF_mean = (summary.RF_mean);
summary_adj.bestSF = interpNanImages(summary_adj.bestSF);
summary_adj.bestOR = interpNanImages(summary_adj.bestOR);
summary_adj.correlation = interpNanImages(summary_adj.correlation);
summary_adj.expVar = interpNanImages(summary_adj.expVar);

stimXaxis_ori = RF_insilico.noiseRF.xaxis;
stimYaxis_ori = RF_insilico.noiseRF.yaxis;

save([encodingSavePrefix '_summary'],'summary_adj','stimXaxis_ori','stimYaxis_ori',...
    'fvX','fvY','-append');


%% summary figure
[sumFig, sumAxes]=showSummaryFig(summary);
set(sumFig,'position',[0 0 1900 1400]);
set(sumAxes(2),'xlim',[min(X) max(X)]);
set(sumAxes(2),'ylim',[min(Y) max(Y)]);
% set(sumFig,'position',[0 0 1900 1000]);
% set(sumAxes(2),'clim', [-8 8]);
% set(sumAxes(3),'clim', [-10 10]);
savePaperFigure(sumFig,[encodingSavePrefix '_summary']);

%summary_adj.mask = summary.mask .* (summary_adj.correlation>corr_th);
[sumFig, sumAxes]=showSummaryFig(summary_adj);
set(sumFig,'position',[0 0 1900 1400]);
set(sumAxes(2),'xlim',[min(X) max(X)]);
set(sumAxes(2),'ylim',[min(Y) max(Y)]);
% set(sumFig,'position',[0 0 1900 1000]);
set(sumAxes(2),'clim', [-7 1]);
set(sumAxes(3),'clim', [-7 7]);
savePaperFigure(sumFig,[encodingSavePrefix '_summary_adj']);


%% show mRFs on maps of preferred position
brain_y = [25 30 35];
brain_x = [10 25 40];
showXrange = [-10 1];
showYrange = [-7.5 7.5];
stimXaxis = stimXaxis_ori - summary.RF_Cx(fvY,fvX);
stimYaxis = -(stimYaxis_ori - summary.RF_Cy(fvY,fvX));
[f_panel, f_location] = showRFpanels(summary_adj, brain_x, brain_y, ...
    stimXaxis, stimYaxis, showXrange, showYrange, rescaleFac);
savePaperFigure(f_panel,[encodingSavePrefix '_mRFs']);
savePaperFigure(f_location,[encodingSavePrefix '_mRFlocs_pwg'], 'w');



%% pixel position on Brain
% load('\\ad.monash.edu\home\User006\dshi0006\Documents\MATLAB\2023ImagingPaper\ephys2Image_CJ231_pen1.mat');
% subplot(121);imagesc(baseImage)
% hold on
% plot(10*brain_x(2),10*brain_y(2),'rs');
% axis equal tight off
% colormap(gray);
% subplot(122);imagesc(inputImage_registered)
% axis equal tight off
% colormap(gray);
% savePaperFigure(gcf, ['brainImage_ephys2Image_CJ231_pen1']);

