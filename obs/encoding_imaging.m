switch getenv('COMPUTERNAME')
    case 'MU00175834'
        %for windows PC
        addpath(genpath('C:\Users\dshi0006\git\motion_energy'));
        addpath(genpath('C:\Users\dshi0006\git\dsbox'));
        addpath(genpath('C:\Users\dshi0006\git\analysisImaging'));
        addpath('C:\Users\dshi0006\git\RFMaps');%getRFContours
        
        %dsDir = '\\storage.erc.monash.edu\shares\R-MNHS-Syncitium\Shared\Daisuke\recording\Nishimoto2011_ds';
        %rawDir = '\\storage.erc.monash.edu\shares\R-MNHS-Syncitium\Shared\Daisuke\recording\Nishimoto2011';
        rootDir = 'E:\tmp';
        saveDirBase = 'Z:\Shared\Daisuke\recording\processed';
    case 'some linux pc'
        %for linux PC
        addpath(genpath('/home/localadmin/Documents/MATLAB/motion_energy_matlab'));
        addpath(genpath('/home/localadmin/Documents/MATLAB/dsbox'));
        addpath(genpath('/home/localadmin/Documents/MATLAB/analysisImaging'));
        addpath('/home/localadmin/Documents/MATLAB/RFMaps');%getRFContours
        
        %where datastore is saved
        dsDir = '/mnt/syncitium/Daisuke/recording/Nishimoto2011_ds';
        rawDir = '/mnt/syncitium/Daisuke/recording/Nishimoto2011';
end



%% exp info
expID = 19;
nsName = 'CJ224.runPassiveMovies.033059';
YYYYMMDD = '20221004';
rescaleFac = 0.1;
%subjectID = 2;
%tgtROI = 'v1rh';


%% estimation of filter-bank coefficients
KFolds = 5; %cross validation
ridgeParam = [1 1e3 1e5 1e7]; %search the best within these values
tavg = 1; %tavg = 0 requires 32GB ram
Fs = 1; %hz after downsampling
lagFrames = 3:9;%0:6;%3:6;%0:9
useGPU = 1; %for ridgeXs local GPU is not sufficient

%% stimuli
nMovies = 24;
movDur = 300;%[s]
omitSec = 5;
trainIdx = [];
for imov = 1:nMovies-1
    trainIdx = [trainIdx (omitSec:movDur)+(imov-1)*movDur];
end
testIdx = (omitSec:movDur)+(nMovies-1)*movDur;

%gabor-wavelet filter bank to estimate
%gparamIdx = 2; %full model
    
%in-silico simulation
nRepeats = 40;
screenPix = [144 256]/4; %[y x]
%<screenPix(1)/screenPix(2) determines the #gabor filters
%the ratio should be sampled from the original movie


%% path to the saved imaging/stimulus data
expName = num2str(expID);
OIName = ['exp' num2str(expName)];
expDate = sprintf('%s\\%s\\%s',YYYYMMDD(1:4),YYYYMMDD(5:6), YYYYMMDD(7:8));
DirBase = fullfile(rootDir,expDate);
imagingDir_full = fullfile(DirBase, OIName);
imageSaveName = fullfile(saveDirBase,expDate,...
    ['imageData_' regexprep(expDate, '\','_') '_' expName '_resize' num2str(rescaleFac*100) '.mat']);
timeTableSaveName = [imageSaveName(1:end-4) '.csv'];
stimSaveName = fullfile(saveDirBase,expDate,...
    ['stimData_' regexprep(expDate, '\','_') '_' expName '.mat']);
encodingSaveName = fullfile(saveDirBase,expDate,...
    ['encoding_' regexprep(expDate, '\','_') '_' expName '.mat']);

%% load neural data
ds = tabularTextDatastore(timeTableSaveName);
% ds = tabularTextDatastore(fullfile(dsDir,['subject' num2str(subjectID) '.csv'])); %load only specified exp 
% load(fullfile(rawDir, ['VoxelResponses_subject' num2str(subjectID) '.mat']), ...
%     'roi','rv');


%% pre-select ROI
% % thisROI = permute(roi.(tgtROI), [1 3 2]);
% thisROI = roi.(tgtROI);
% roiIdx_tmp = find(thisROI);
% %scatter3(X,Y,Z,'k.');xlabel('x');ylabel('y');
% %x:M-L, y:height, z: A-P
% %hold on
% 
% mrv = std(rv);
% rvIdx=find(~isnan(mrv));%&mrv>0.08);
% noNanIdx = find(~isnan(mrv(roiIdx_tmp)));%voxel without NAN values
% %scatter3(X(okIdx),Y(okIdx),Z(okIdx),'c.');

load(imageSaveName, 'imageData');
thisROI = imageData.meanImage;
clear imageData;

roiIdx = 1640:1670;%1658;%roiIdx_tmp(noNanIdx);
[Y,X,Z] = ind2sub(size(thisROI), roiIdx);
nNeurons = length(roiIdx);


%% load output of gabor-wavelet bank
% load( fullfile(dsDir,['gaborFilter' num2str(gparamIdx) '.mat']), ...
%     'S_fin');
load( stimSaveName, 'TimeVec_stim_cat', 'S_fin');

S_fin_train = single(S_fin(trainIdx,:));
S_fin_test = single(S_fin(testIdx,:));
nFilters = size(S_fin,2);

%% estimate the energy-model parameters w cross validation
lagRange = [min(lagFrames)/Fs max(lagFrames)/Fs];%lag range provided as rr

f(1:nNeurons) = parallel.FevalFuture;
disp('Started running trainAneuron');
for iNeuron = 1:nNeurons
    f(iNeuron) = parfeval(@trainAneuron, 1, ds, S_fin, roiIdx(iNeuron), trainIdx,  ...
        ridgeParam, KFolds, lagRange, tavg, useGPU);
end
%test:
% trained=trainAneuron(ds, S_fin, roiIdx(iNeuron), trainIdx,  ...
%         ridgeParam, KFolds, lagRange, tavg, useGPU);
updateWaitbar = @(~) disp([num2str(sum({f.State} == "finished")) '/' num2str(length(f))]);%
updateWaitbarFutures = afterEach(f,updateWaitbar,0);

% fetches all outputs of the Future object F after first waiting for each 
% element of F to reach the state 'finished'
result = fetchOutputs(f);

ridgeParam_optimal = zeros(nNeurons,1);
r0e = zeros(1,nNeurons);
mse = zeros(1,nNeurons);
if tavg
    rre = zeros(1, nFilters, nNeurons);
else
    rre = zeros(length(lagFrames), nFilters, nNeurons);
end 
for iNeuron = 1:length(result)
    rre(:,:,iNeuron) = result(iNeuron).rre;
    r0e(iNeuron) = result(iNeuron).r0e;
    mse(iNeuron) = result(iNeuron).mse;
    ridgeParam_optimal(iNeuron) = result(iNeuron).ridgeParam_optimal;
end

save(encodingSaveName,'rre','r0e',...
    'mse','lagFrames','tavg')

%% in-silico simulation to obtain RF
tic
gparamIdx = 2;
RF_is = getInSilicoRF(gparamIdx, r0e, rre, lagFrames, ...
    tavg, screenPix, Fs, nRepeats);
t2=toc
%~1000s for 
%rr:6555x504
%screenPix:20


%% fit RF position and size
mRF = squeeze(mean(RF_is,3));
tic
RF_Cx = zeros(nNeurons,1);
RF_Cy = zeros(nNeurons,1);
RF_ok = zeros(nNeurons,1);
RF_tmp = cell(1);
parfor ii = 1:nNeurons
    disp([num2str(ii) '/' num2str(nNeurons)]);
    RF_tmp = mat2cell(double(mRF(:,:,ii)), screenPix(1), screenPix(2));
    [RF_contour, Cx_tmp, Cy_tmp, ok_tmp] = getRFContours(RF_tmp);
    % < Index in position 3 exceeds array bounds. @ ii=10, jj=1
    %computation time depends on screenPix_is
    RF_Cx(ii,:) = cell2mat(Cx_tmp);
    RF_Cy(ii,:) = cell2mat(Cy_tmp);
    RF_ok(ii,:) = cell2mat(ok_tmp);
end
t3=toc
%looks like RF_Cx and RF_Cy is swapped??
a(1)=subplot(121);scatter3(X, Y, Z, 3,RF_Cx); title('RF_Cx');mcolorbar(a(1),.5);hold on;
a(2)=subplot(122);scatter3(X, Y, Z, 3,RF_Cy); title('RF_Cy');mcolorbar(a(2),.5);hold on;
Link = linkprop(a,{'CameraUpVector', 'CameraPosition', 'CameraTarget', 'XLim', 'YLim', 'ZLim'});
setappdata(gcf, 'StoreTheLink', Link);

thisIdx = 37;
a(1)=subplot(121);scatter3(X(thisIdx), Y(thisIdx), Z(thisIdx), 8, 'r'); title('RF_Cx');mcolorbar(a(1),.5);
a(2)=subplot(122);scatter3(X(thisIdx), Y(thisIdx), Z(thisIdx), 8, 'r'); title('RF_Cy');mcolorbar(a(2),.5);


% tri = delaunay(X,Y);
% plot(X,Y,'.')
% [r,c] = size(tri);
% nRF_Cx = normalize(RF_Cx,'range');
% nRF_Cx(isnan(nRF_Cx)) = 0;
% h = trisurf(tri, X, Y, Z, 'facecolor',nRF_Cx);
% axis vis3d

% tri=delaunay(X,Y);
% trisurf(tri,X,Y,Z);
% shp = alphaShape(X,Y,Z,3);
% plot(shp);
save(['encoding_mri_subject' num2str(subjectID) '.mat'],'RF_Cx','RF_Cy','RF_ok','RF_is','screenPix',...
    'nRepeats','X','Y','Z','tgtROI','thisROI','-append');

