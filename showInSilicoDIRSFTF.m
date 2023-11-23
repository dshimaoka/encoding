function f = showInSilicoDIRSFTF(RF_insilico, trange)
%f = showInSilicoDIRSFTF(RF_insilico, trange)
% created from showInSilicoRF

if nargin < 2
    trange = [-inf inf];
end

dirList = 180/pi*RF_insilico.DIRSFTF.dirList;
sfList = RF_insilico.DIRSFTF.sfList;
resp = RF_insilico.DIRSFTF.resp;
respDelay = RF_insilico.DIRSFTF.respDelay;

tidx = find(respDelay>=trange(1) & respDelay<=trange(2));
mresp = squeeze(mean(resp(:,:,:,tidx),4)); %sf x dir x tf

f = figure('position',[0 0 1900 1000]);

subplot(131);
imagesc(1:numel(sfList),dirList, squeeze(mean(mresp,3))');
ylabel('direction [rad]');
xlabel('SF (cycles/deg)');
set(gca,'xtick',1:numel(sfList),'xticklabel',sfList);
%title('mean across delays');
%caxis([-crange crange]);
colorbar;

subplot(132);
imagesc(1:numel(sfList),1:numel(tfList), squeeze(mean(mresp,2))');
ylabel('TF (Hz)');
xlabel('SF (cycles/deg)');
set(gca,'xtick',1:numel(sfList),'xticklabel',sfList);
set(gca,'ytick',1:numel(tfList),'yticklabel',tfList);
colorbar;

subplot(133);
imagesc(dirList,1:numel(tfList), squeeze(mean(mresp,1))');
ylabel('TF (Hz)');
xlabel('direction [rad]');
set(gca,'ytick',1:numel(tfList),'yticklabel',tfList);
colorbar;
