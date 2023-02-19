ServerDir = '\\zserver3.ioo.ucl.ac.uk\Data\Stacks';
saveDir = '\\zombie\Users\daisuke\Documents\MATLAB\stackset\Data';
% expid = 87;
% Exps = readExpsDatabase('ExpsDatabase_tg.m', expid);
Exps.animal= 'M150605_SD';
Exps.iseries= 1;
Exps.iexp= 2;
Exps.ResizeFac= 0.5000;

FileString = '_ratio';
Magnification = 1.6; %objective magnification factor 
binning = 4; %binning factor 
Exps.Cam = tools.Imager('PCO', [], FileString, Magnification, binning);

dataSuffix = '';
StackName = 'nanMean_hp';

LoCutFreq = 0.5;%[Hz] lo-cut frequency for stackset
dnSamp = 25; %[Hz] %down sampling rate

p = ProtocolLoadDS(Exps);

stimList = 1:p.nstim-1;

MyStackDir = tools.getDirectory( saveDir, p, Exps.ResizeFac, ...
    1, 1, Exps.Cam, dataSuffix);


%% prepare stimulus
saveStimInfo_stimCorrectedKalatsky2(Exps,stimList);


%% prepare imaging data
saveStack_stimCorrectedKalatsky2


%% compile stimulus and imaging data
[S, R, t, phi, theta, nRows, nCols] = ...
    CompileData(ServerDir, dnSamp, Exps, dataSuffix, StackName);
close all;

CompileDataName = sprintf('%s_%d_%d_PRF_CompileData', Exps.animal, Exps.iexp, Exps.iseries);
save(fullfile(MyStackDir, CompileDataName), 'S', 'R', 't', 'phi', 'theta', 'nRows', 'nCols');



%% pRF estimation here
tic
[RFx, RFy, RFsig, r, xVoxRange, yVoxRange] = ...
    fitPRFs(S, R, t, phi, theta, nRows, nCols);
t=toc
ResultName = sprintf('%s_%d_%d_PRF_Result', Exps.animal, Exps.iexp, Exps.iseries);
save(fullfile(MyStackDir, ResultName), 'RFx', 'RFy', 'RFsig', 'r', 'xVoxRange', 'yVoxRange');

%% visualization - tentative
% scrsz = get(0, 'screensize');
% 
% figure('position', scrsz);
% subplot(2,2,1)
% imagesc(xVoxRange,yVoxRange,RFx*180/pi);
% caxis([0 130]);
% axis equal tight
% mcolorbar
% title(['Expid:' num2str(expid) '; x [deg]'])
% 
% subplot(2,2,2)
% imagesc(xVoxRange,yVoxRange,RFy*180/pi);
% caxis([-30 45]);
% axis equal tight
% mcolorbar
% title('y [deg]')
% 
% subplot(2,2,3)
% imagesc(xVoxRange,yVoxRange,RFsig);
% caxis(prctile(RFsig(:),[5 95]));
% axis equal tight
% mcolorbar
% title('sig')
% 
% subplot(2,2,4)
% imagesc(xVoxRange,yVoxRange,r);
% axis equal tight
% mcolorbar
% title('r')
% 
% screen2png(fullfile(MyStackDir, [Exps.animal '_' num2str(Exps.iseries) '_' num2str(Exps.iexp) '_Retinotopy_pRF']));
% close
PlotResults(RFx,RFy,RFsig,r,xVoxRange,yVoxRange,nCols,nRows,R, 0.2)


funfare(3)
tname = sprintf('Expid:%d %s: pRF estimation:done', ...
    expid, Exps.Cam.FileString);
message = sprintf('%s_ratio_%d_%d \nprocessed on %s',Exps.animal, ...
    Exps.iseries, Exps.iexp, hostname);
sendmail2me(tname, message);