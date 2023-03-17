ID=2;
gparamIdx = 2;
screenPix = [144 256];%/4; %Y-X %gaborparams is identical irrespective of the denominator
rescaleFac = 0.10;
thisIdx = 1034;%1229;

expInfo = getExpInfoNatMov(ID);
dataPaths = getDataPaths(expInfo,rescaleFac);
encodingSavePrefix = [dataPaths.encodingSavePrefix];

encodingSaveName = [encodingSavePrefix '_roiIdx' num2str(thisIdx) '.mat'];
encodingResult = load(encodingSaveName,'trained','trainParam');

load(dataPaths.imageSaveName,'stimInfo')
stimSz = [stimInfo.height stimInfo.width];

[gaborparams_real, gaborparams, S] = getFilterParams(gparamIdx, screenPix, stimSz);
[sumCoefs,allIdx] = sort(sum(abs(encodingResult.trained.rre)), 'descend');
showFiltIdx = allIdx(1:20);
showFiltParams(gaborparams, S, showFiltIdx);

figure;
histogram(sumCoefs);
xlabel('filter coefficient');
ylabel('#filters');

figure;
paramNames = {'pos_x' 'pos_y' 'direction' 's_freq' 't_freq' 's_size' 't_size' 'phasevalue'};
for ii = 1:4
    ax(ii)=subplot(4,1,ii);
    histogram(gaborparams_real(ii,allIdx(1:100)),10);
    ylabel(paramNames{ii});
    grid on;
    axis tight padded
end