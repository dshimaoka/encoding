if ~ispc
    addpath(genpath('~/git'));
    addDirPrefs;
end


ID = 1;
useGPU = 1;
rescaleFac = 0.10;
dsRate = 1;


%% path
expInfo = getExpInfoNatMov(ID);
dataPaths = getDataPaths(expInfo,rescaleFac);
%TODO: save data locally
encodingSavePrefix = dataPaths.encodingSavePrefix;

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
bestSF = nan(numel(thisROI),1);
bestOR = nan(numel(thisROI),1);
bestAmp = nan(numel(thisROI),1);
ridgeParam = nan(numel(thisROI),1);
ngidx = [];
tic; %18h for CJ224 @officePC
for ii = 1261;%1648;%1:numel(roiIdx)
    disp(ii)
    encodingSaveName = [encodingSavePrefix '_roiIdx' num2str(roiIdx(ii)) '.mat'];
    if exist(encodingSaveName,'file')
        encodingResult = load(encodingSaveName, 'RF_insilico','trained','trainParam');
        RF_insilico = encodingResult.RF_insilico;
        trained = encodingResult.trained;
        trainParam = encodingResult.trainParam;
    else
        disp(['MISSING ' encodingSaveName]);
        ngidx = [ngidx roiIdx(ii)];
        continue;
    end
    
    expVal(ii) = trained.expval;
    ridgeParam(ii) = trained.ridgeParam_optimal;

    %% RF
    analysisTwin = [0 trainParam.lagFrames(end)/dsRate];
    %RF_insilico = analyzeInSilicoRF(RF_insilico, -1, analysisTwin);

    RF_Cx(ii) = RF_insilico.noiseRF.RF_Cx;
    RF_Cy(ii) = RF_insilico.noiseRF.RF_Cy;
    RF_sigma(ii) = RF_insilico.noiseRF.sigma;
    
    trange = [0 trainParam.lagFrames(end)/dsRate];
    tidx = find(RF_insilico.noiseRF.RFdelay>=trange(1) & RF_insilico.noiseRF.RFdelay<=trange(2));
    RF_mean{ii} = mean(RF_insilico.noiseRF.RF(:,:,tidx),3);  
    
    
    %% ORSF ... too heavy for officePC
    RF_insilico.ORSF.screenPix = [144 256];%/2;
    RF_insilico.ORSF.nRepeats = 15;
    nORs=10;
    oriList = pi/180*linspace(0,180,nORs+1)'; %[rad]
    RF_insilico.ORSF.dwell = 0.5*numel(trainParam.lagFrames)*RF_insilico.ORSF.Fs_visStim;
    RF_insilico.ORSF.oriList = oriList(1:end-1);
    SFrange_stim = getSFrange_stim(RF_insilico.ORSF.screenPix, stimSz);
    RF_insilico.ORSF.sfList = logspace(log10(SFrange_stim(1)), log10(SFrange_stim(2)), 6); %[cycles/deg]
    RF_insilico = getInSilicoORSF(gaborBankParamIdx, trained, trainParam, ...
        RF_insilico, stimSz, 0);
    RF_insilico = analyzeInSilicoORSF(RF_insilico, -1,trange,3);
    bestSF(ii) = RF_insilico.ORSF.bestSF;
    bestOR(ii) = RF_insilico.ORSF.bestOR;
    try
        showInSilicoORSF(RF_insilico, trange);
        screen2png([encodingSaveName(1:end-4) '_ORSF']);
        close;
    catch
        disp(['NOT SAVED ' encodingSaveName(1:end-4) '_ORSF']);
        continue;
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
ridgeParam2 = nan(size(thisROI));
RF_mean2 = nan(size(thisROI,1),size(thisROI,2),RF_insilico.noiseRF.screenPix(1),RF_insilico.noiseRF.screenPix(2));
for ii = 1:numel(roiIdx)
    RF_Cx2(Y(roiIdx(ii)),X(roiIdx(ii))) = RF_Cx(ii);
    RF_Cy2(Y(roiIdx(ii)),X(roiIdx(ii))) = RF_Cy(ii);
    RF_sigma2(Y(roiIdx(ii)),X(roiIdx(ii))) = RF_sigma(ii);
    expVal2(Y(roiIdx(ii)),X(roiIdx(ii))) = expVal(ii);
    ridgeParam2(Y(roiIdx(ii)),X(roiIdx(ii))) = ridgeParam(ii);
    RF_mean2(Y(roiIdx(ii)),X(roiIdx(ii)),:,:) = RF_mean{ii}; 
    bestSF2(Y(roiIdx(ii)),X(roiIdx(ii))) = bestSF(ii);
    bestOR2(Y(roiIdx(ii)),X(roiIdx(ii))) = bestOR(ii);
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
summary.thisROI = thisROI;
summary.roiIdx = roiIdx;

save([dataPaths.encodingSavePrefix '_summary'],'summary');

%% re-estimate RF center after subtracting out grand avg
gavg = squeeze(nanmean(nanmean(summary.RF_mean,1),2));
xaxis = RF_insilico.noiseRF.xaxis;
yaxis = RF_insilico.noiseRF.yaxis;
%xlim = [ min(xaxis) 5];

maxRFsize = 10; %diamter in [deg]
winIdxLen = floor(maxRFsize/mean(diff(xaxis))/2);
RF_Cx3 = nan(size(thisROI));
RF_Cy3 = nan(size(thisROI));
RF_sigma3 = nan(size(thisROI));
tic;
for ii = 1:numel(roiIdx)
    try
    mRFori = squeeze(summary.RF_mean(Y(roiIdx(ii)),X(roiIdx(ii)),:,:));
    %     k = gavg(:)\mRFori(:);
    %     mRF = mRFori - k*gavg;
    
    RF_smooth = smooth2DGauss(mRFori);% - mean(mRF(:)));
    
    RF_smooth = (-1) * RF_smooth;
    RF_smooth(RF_smooth<0) = 0;
    
    %initial fitting using all pixels
    p0 = fitGauss2(xaxis,yaxis,RF_smooth);%need smoothing before this
   
    %second fitting w limted pixels
    [~,xcent] = min(abs(p0(1)-xaxis));
    [~,ycent] = min(abs(p0(2)-yaxis));
    winXidx = max(xcent-winIdxLen,1):min(xcent+winIdxLen,numel(xaxis));
    winYidx = max(ycent-winIdxLen,1):min(ycent+winIdxLen,numel(yaxis));
    
    p = fitGauss2(xaxis(winXidx),yaxis(winYidx),RF_smooth(winYidx,winXidx));%need smoothing before this
    
    RF_Cx3(Y(roiIdx(ii)),X(roiIdx(ii))) = p(1);
    RF_Cy3(Y(roiIdx(ii)),X(roiIdx(ii))) = p(2);
    RF_sigma3(Y(roiIdx(ii)),X(roiIdx(ii))) = (p(3)+p(4))/2;
    catch err
        continue;
    end
end
t=toc


%% summary figure
subplot(241);
imagesc(summary.thisROI);
axis equal tight
colormap(gca,'gray');

subplot(242);
imagesc(summary.RF_Cx);
caxis(prctile(summary.RF_Cx(:),[1 99]));
title('Cx [deg]');
axis equal tight
mcolorbar;

subplot(243);
imagesc(summary.RF_Cy)
caxis(prctile(summary.RF_Cy(:),[1 99]));
title('Cy [deg]');
axis equal tight
mcolorbar;

subplot(244);
imagesc(summary.RF_sigma)
title('sigma [deg]');
axis equal tight
mcolorbar;

subplot(245);
imagesc(summary.expVar);
title('explained variance [%]');
axis equal tight
colormap(gca,'gray');
mcolorbar;

subplot(246);
imagesc(log(summary.ridgeParam));
title('log(ridge param)');
axis equal tight
colormap(gca,'gray');
mcolorbar;

subplot(247);
imagesc(log(summary.bestSF));
%sfList = logspace(-1.1, 0.3, 5);
%caxis(log(prctile(sfList,[0 100])));
caxis([-4 -1]);
title('log(spatial frequency) [cpd]');
axis equal tight
mcolorbar;

subplot(248);
imagesc(mod(summary.bestOR,180));
colormap(gca, 'hsv');
caxis([0 180]);
title('orientation [deg]');
axis equal tight
mcolorbar;

screen2png([dataPaths.encodingSavePrefix '_summary']);

%% visual field sign
prefMaps_xy(:,:,1)=summary.RF_Cx;
prefMaps_xy(:,:,2)=summary.RF_Cy;
vfs=getVFS(prefMaps_xy);

%% show mRFs

xx = (21:30);
yy = (31:40);

figure;

subplot_tight(numel(yy)+1, 2, 1)
imagesc(summary.RF_Cx);hold on;
rectangle('position', [min(xx) min(yy) numel(xx) numel(yy)]);
caxis(prctile(summary.RF_Cx(:),[1 99]));
title('Cx [deg]');
axis equal tight
mcolorbar;

subplot_tight(numel(yy)+1, 2, 2)
imagesc(summary.RF_Cy);hold on;
rectangle('position', [min(xx) min(yy) numel(xx) numel(yy)]);
caxis(prctile(summary.RF_Cy(:),[1 99]));
title('Cy [deg]');
axis equal tight
mcolorbar;


all = summary.RF_mean(yy, xx,:,:);
xaxis = RF_insilico.noiseRF.xaxis;
yaxis = RF_insilico.noiseRF.yaxis;
for ix = 1:numel(xx)
    for iy = 1:numel(yy)
        subplot_tight(numel(yy)+1, numel(xx), ix + numel(xx)*iy, 0.02);
        imagesc(xaxis, yaxis, squeeze(summary.RF_mean(yy(iy), xx(ix),:,:))-gavg);
       
        hold on
        plot(summary.RF_Cx(yy(iy), xx(ix)),summary.RF_Cy(yy(iy), xx(ix)), 'ro');
       
        if ix>1 || iy > 1
            set(gca,'xtick',[],'ytick',[]);
        end
        if ix==1
            ylabel(yy(iy));
        end
        if iy==numel(yy)
            xlabel(xx(ix));
        end
        %title(['x: ' num2str(xx(ix)) ', y: ' num2str(yy(iy))])
        %caxis(prctile(all(:),[1 99])); %better not to impose same color range
    end
end

% rectangle('position', [min(xx) min(yy) numel(xx) numel(yy)]);
