%wrapper_encoding.m
%this script loads processed data by makeDataBase.m, 
%fit one pixel with ridge regression
%evaluate the fit result with in-silico simulation

expInfo.subject = 'CJ224';
expInfo.date = '20221004';
expInfo.nsName = 'CJ224.runPassiveMovies.033059';
expInfo.expID = 19;

rescaleFac = 0.25;
roiIdx = 7618;%1658;%roiIdx_tmp(noNanIdx);


%% path
dataPaths = getDataPaths(expInfo,rescaleFac);

load( dataPaths.stimSaveName, 'dsRate'); %NEI FIX THIS


%% estimation of filter-bank coefficients
trainParam.KFolds = 5; %cross validation
trainParam.ridgeParam = [1 1e3 1e5 1e7]; %search the best within these values
trainParam.tavg = 1; %tavg = 0 requires 32GB ram. if 0, use avg within Param.lagFrames to estimate coefficients
trainParam.Fs = dsRate; %hz after downsampling 
trainParam.lagFrames = round(3/dsRate):round(9/dsRate);%0:6;%3:6;%0:9 %frame delays to train a neuron
%trainParam.lagRange = [min(trainParam.lagFrames)/trainParam.Fs max(trainParam.lagFrames)/trainParam.Fs];%lag range provided as rr
trainParam.useGPU = 1; %for ridgeXs local GPU is not sufficient


%% stimuli
load(dataPaths.imageSaveName,'cic')
stimInfo = getStimInfo(cic);

nMovies = cic.nrTrials; 
movDur = stimInfo.duration;%[s] 
omitSec = 5; %omit initial XX sec for training
trainIdx = [];
for imov = 1:nMovies-1
    trainIdx = [trainIdx (omitSec*dsRate:movDur)+(imov-1)*movDur];
end
testIdx = (omitSec*dsRate:movDur)+(nMovies-1)*movDur; %not really useful for testing - may have some abnormality at the start of stimulation


%% in-silico simulation
RF_insilico = struct;
RF_insilico.nRepeats = 40;
RF_insilico.screenPix = stimInfo.screenPix/4; %[y x]
%<screenPix(1)/screenPix(2) determines the #gabor filters


%% draw slurm ID for parallel computation
pen = getPen;

%% load neural data
%TODO: copy timetable data to local
ds = tabularTextDatastore(dataPaths.timeTableSaveName);

load(dataPaths.imageSaveName, 'imageData');
thisROI = imageData.meanImage;
clear imageData;

%from sdCoupling:
%sz = [numel(xind) numel(yind)];
%total jobs: prod(sz)
%[xsub, ysub] = ind2sub(sz, pen);

%[Y,X,Z] = ind2sub(size(thisROI), 1:numel(thisROI));
%find((X==50)&(Y==121))

[Y,X,Z] = ind2sub(size(thisROI), roiIdx(pen));
%nNeurons = length(roiIdx);

%% load gabor bank prediction data
%TODO load data tolocal
load( dataPaths.stimSaveName, 'TimeVec_stim_cat', 'S_fin','gaborBankParamIdx');

% S_fin_train = single(S_fin(trainIdx,:));
% S_fin_test = single(S_fin(testIdx,:));
% nFilters = size(S_fin,2);

%% estimate the energy-model parameters w cross validation
tic;
trained = trainAneuron(ds, S_fin, roiIdx(pen), trainIdx,  ...
        trainParam.ridgeParam, trainParam.KFolds, [trainParam.lagFarmes(1) trainParam.lagFarmes(end)],...%trainParam.lagRange, ...
        trainParam.tavg, trainParam.useGPU);
t1=toc %6s!



%TODO: save data locally
encodingSaveName = [dataPaths.encodingSavePrefix '_roiIdx' num2str(roiIdx(pen)) '.mat'];
save(encodingSaveName,'trained','trainParam');%'rre','r0e','mse','lagFrames','tavg')

%% in-silico simulation to obtain RF
tic
[RF_is, lagTimes_is] = getInSilicoRF(gaborBankParamIdx, trained.r0e, ...
    trained.rre, trainParam.lagFrames, trainParam.tavg, RF_insilico.screenPix,...
    trainParam.Fs, RF_insilico.nRepeats);
t2=toc
%~1000s for 
%rr:6555x504
%screenPix:20

xpix = 1:RF_insilico.screenPix(2);
xaxis = stimInfo.width*(xpix - mean(xpix))./numel(xpix);
ypix = 1:RF_insilico.screenPix(1);
yaxis = stimInfo.height*(ypix - mean(ypix))./numel(ypix);

%% fit RF position and size
tic;
mRF = squeeze(mean(RF_is,3));
%RF_tmp = mat2cell(double(mRF), RF_insilico.screenPix(1), RF_insilico.screenPix(2));

%USELESS:
%[RF_contour, Cx_tmp, Cy_tmp, ok_tmp] = getRFContours(RF_tmp);
% < Index in position 3 exceeds array bounds. @ ii=10, jj=1
%computation time depends on screenPix_is
% RF_Cx = cell2mat(Cx_tmp);
% RF_Cy = cell2mat(Cy_tmp);
% RF_ok = cell2mat(ok_tmp);

RF_smooth = smooth2DGauss(mRF - mean(mRF(:)));
RF_smooth(RF_smooth<0) = 0;
p = fitGauss2(xaxis,yaxis,RF_smooth);%need smoothing before this
RF_Cx = p(1);
RF_Cy = p(2);
RF_ok = 1;
t3=toc


crange = prctile(RF_is(:),[1 99]);
figure('position',[0 0 1900 1000]);
tiledlayout('flow');
for ii= 1:size(RF_is,3)
    cax=newplot;
    imagesc(xaxis, yaxis, RF_is(:,:,ii));
    axis equal tight;
    caxis(crange);
    if ii==1
        title(['model delay ' num2str(lagTimes_is(ii))]);
    else
        title(lagTimes_is(ii));
    end
    nexttile;
end
imagesc(xaxis, yaxis, mRF);axis equal tight;
title('mean across delays');
caxis(crange);
mcolorbar(gca,.5);

if RF_ok
    hold on;
    plot(RF_Cx, RF_Cy, 'ro');
end
screen2png(encodingSaveName(1:end-4));
close;

RF_insilico.RF = RF_is;
RF_insilico.RF_Cx = RF_Cx;
RF_insilico.RF_Cy = RF_Cy;
RF_insilico.RF_ok = RF_ok;

% %looks like RF_Cx and RF_Cy is swapped??
save(encodingSaveName,'RF_insilico','X','Y','Z','-append');

%TODO: upload result to server
