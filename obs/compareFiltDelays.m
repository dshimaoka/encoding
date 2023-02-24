expInfo.subject = 'CJ224';
expInfo.date = '20221004';
expInfo.nsName = 'CJ224.runPassiveMovies.033059';
expInfo.expID = 19;

omitSec = 5; %omit initial XX sec for training
rescaleFac = 0.25;

dataPaths = getDataPaths(expInfo,rescaleFac);
%TODO: save data locally

allrre = [];
for pen=2:9
    delay = [0 pen];
    encodingSaveName = [dataPaths.encodingSavePrefix '_roiIdx' num2str(1) ...
        '_lagFrames' num2str(delay) '_dsRate1.mat'];
load(encodingSaveName);

allrre = [allrre; trained.rre];
ax(pen)=subplot(8,1,pen-1);
imagesc(1:3013, delay(1):delay(2), trained.rre);
end

for pen=2:9
    delay = [0 pen];
    encodingSaveName = [dataPaths.encodingSavePrefix '_roiIdx' num2str(1) ...
        '_lagFrames' num2str(delay) '_dsRate1.mat'];
load(encodingSaveName);

ax(pen)=subplot(8,1,pen-1);
imagesc(1:3013, delay(1):delay(2), trained.rre);

caxis([-max(abs(allrre(:))) max(abs(allrre(:)))]);
end
linkaxes(ax(:));
ylabel('delay[s]');
xlabel('filter ID');

mcolorbar;
