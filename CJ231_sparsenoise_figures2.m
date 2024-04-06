%testing openEphys NetworkImagingConfig to drive the imager

%confirmed photodiode times, visual stimulus times and camera acquisition

if ispc
    addpath('\\storage.erc.monash.edu\shares\R-MNHS-Syncitium\Shared\Daisuke\sandbox');
    if exist('C:\Users\dshi0006\git','dir')
        addpath(genpath('C:\Users\dshi0006\git'));
    else
        addpath(genpath('C:\git'));    %dsbox,oi-tools,analysis-tools,analysisImaging, npy-matlab,neurostim, marmolab-stimuli
    end
else
    %addpath('/mnt/syncitium/Daisuke/sandbox/mdbase_test');%loadNS
    addpath(genpath('/home/daisuke/Documents/git'));%git repositories
    rmpath(genpath('/home/tjaw/Documents/git'));%git repositories
    rmpath(genpath('/home/tjaw/Documents/git/analyse'));
end

%% analyssis parameters
channels = 1:384;%[5 20 88 109 160 201 299];%1:21:384;%77ch-3.3h <> 156s/ch
channels_strf = channels; %must be subset of channels

rect = [];%[-10 5 0 -10];% [-12 12 12 -12];%[0 6 6 0];%left top right bottom
window = [0.04 0.13]%0.16];
superIdx = 1:numel(channels);%1:8;%[6:8:48];%[5 15 25 35 45];%[3 5 8 14 21 31 39];
sigma = 0.35; %spatial filtering


%% parameters for each exp


if ispc
    switch getenv('COMPUTERNAME')
        case 'MU00190873'
            nsOriServer = 'V:\';%'\\storage.erc.monash.edu\shares\R-MNHS-Syncitium\Shared\MarmosetData';
            rootDir = 'E:\tmp';
            oeOriServer = 'X:\data'; %direct ethernet connection
        case 'MU00175834'
            nsOriServer = '\\storage.erc.monash.edu.au\shares\MNHS-dshi0006\MarmosetData';%'\\storage.erc.monash.edu\shares\R-MNHS-Syncitium\Shared\MarmosetData';
            oeOriServer = nsOriServer;
            rootDir = 'E:\tmp';%'\\ad.monash.edu\home\User006\dshi0006\Documents\MATLAB\2023ImagingPaper\neuropix_tmp\';%
            saveDirBase = 'Z:\Shared\Daisuke\recording';
    end
else
    %rootDir = '/home/rig3/Documents/neuropix_tmp';%'
    %rootDir = '/home/tjaw/Documents/neuropix_tmp';
    rootDir = '/home/daisuke/Documents/neuropix_tmp';
    nsOriServer = '/mnt/syncitium/MarmosetData';
    oeOriServer = nsOriServer;
    saveDirBase = '/mnt/syncitium/Daisuke/recording';
end

tic;


for iexp = [1] %[2:5 7:9]%6%2:9
    tic
    switch iexp
     
            
        case 1 %pen1 size1
            nsName = 'CJ231.noisegrid.095454';
            YYYYMMDD = '20221130';
            x0 = 0;%-4.23; %from CJ229.noisegrid.044458
            y0 = 0;%1.71; %from CJ229.noisegrid.044458
            xrange = [-34.5 34.5];%[-15 1]; %before centering by x0
            yrange = [-19.5 19.5]; %before centering by y0
            
        case 2 %pen 1 size 0.5
            %replace nsfile location to E:\tmp\2022\11\01\
            nsName = 'CJ231.noisegrid.111011';
            YYYYMMDD = '20221130';
            x0 = 0;%-4.23; %from CJ229.noisegrid.044458
            y0 = 0;%1.71; %from CJ229.noisegrid.044458
            xrange = [-34.5 34.5];%[-15 1]; %before centering by x0
            yrange = [-19.5 19.5]; %before centering by y0
    end
    
    %% rename OEphys filenames (NS data is kept intact)
    if ispc
        expDate = sprintf('%s\\%s\\%s',YYYYMMDD(1:4),YYYYMMDD(5:6), YYYYMMDD(7:8));
    else
        expDate = sprintf('%s/\%s/\%s',YYYYMMDD(1:4),YYYYMMDD(5:6), YYYYMMDD(7:8));
    end
    oeOriDir = fullfile(oeOriServer, expDate);
    %fixoephys(oeOriDir,'verbose',true);%skip already renamed folders
    
    %% copy ns data to local - otherwise analysis.noisegrid will stuck
    fullOEName = retrieveFullOEName(oeOriDir, nsName);
    nsFile = copyServer2Local(nsOriServer, rootDir, fullOEName,[],0,1); %neurostim & oephys file
    
    
    %% at this moment, assume all data is uploaded to syncitium at the correct location
    DirBase = fullfile(rootDir,expDate);
    mkdir(DirBase);
    cd(DirBase);
    
    mdbname = fullfile(saveDirBase,expDate,[nsName '.mdm']); %save result to server
    mkdir(fullfile(saveDirBase,expDate));
    %mdbname = fullfile(DirBase, [nsName '.mdm']);
    
    if exist(mdbname,'file')
        load(mdbname, '-mat');
        %mdb.file = fullfile(oeOriDir, nsFile);
    else
        mdb = marmodata.mdbase({nsFile},'loadArgs',{'loadEye',false, ...
            'spikes', true,'fs',3e4,'lfp',false 'channels', channels, ...
            'useCAR', false, 'source','ghetto', 'onThresh',9,'polarity','both',...
            'reload', false, 'overwrite',1, 'cfg', 'acute.neuropix'});
        save(mdbname,'mdb');
    end
    
    %% load channel info (tentative solution. will be stored within mdb)
    cfg = marmodata.cfgs.acute.neuropix(fullfile(oeOriDir,fullOEName));
    
    %% load NS file
    load(nsFile);
    width = get(c.noise.prms.width,'trial',1);
    size_w = get(c.noise.prms.size_w,'trial',1);
    patchsize = width(2)/size_w(2);
    
    %% load mdbase for noisegrid
    disp('building noisegrid mdbase');
    tic;
    mdb2 = mapping.analysis.noisegrid(mdb); %class 'mapping.analysis.noisegrid'
    %now functions defined in mapping.analysis.noisegridPassive is accesibble
    %eg. mdb2.frameRate
    t= toc
    disp('done');
    
    %some basic information is missing
    mdb2.unit = 1;
    
    %mdb2.channel = channels;
    
    [a,b]=sort(cfg.probeInfo.ycoords(channels));
    mdb2.channel = channels(b); %sorted by depth
    
    xcoords = cfg.probeInfo.xcoords(mdb2.channel);
    ycoords = cfg.probeInfo.ycoords(mdb2.channel);
    
    
    %number of spikes per channel
    nTotSpikes = squeeze(sum(cellfun(@numel,mdb2.spikes.spk(1,:,:))));
    nTotSpikes = nTotSpikes(mdb2.channel);
    
    %% compute ground avg of spikes across channels
    %     allSpk = cell(1,100);
    %     for itr = 1:100;
    %         allSpk_c = [];
    %         for ii = 1:384
    %             allSpk_c = cat(1,allSpk_c, mdb2.spikes.spk{1,itr,ii});
    %         end
    %         allSpk{1,itr} = unique(allSpk_c);
    %     end
    
    %% compute ST RF to the ground avg spikes
    %mdb2.spikes.spk = allSpk; %NG
    
    
    %% compute time window
    
    
    %% spatial RF
    rfResultName = [nsName '_rf.mat'];
    if ~exist(rfResultName, 'file')
        
        window0 = [-0.09 0];
        [x2D, y2D, r0] = mdb2.getSingleSquareResponse('channels',mdb2.channel,'window', ...
            window0, 'rect',rect);
        
        [x2D, y2D, r] = mdb2.getSingleSquareResponse('channels',mdb2.channel,'window', ...
            window, 'rect',rect);
        nchannels = size(r,2);
        r2D0 = reshape(r0, [numel(unique(y2D)) numel(unique(x2D)) nchannels]);
        r2D = reshape(r, [numel(unique(y2D)) numel(unique(x2D)) nchannels]);
        
        %[h,x2D,y2D,r2D] = mdb2.plotSingleSquareResponse('channels',mdb2.channel,'window', ...
        %             window, 'rect',rect);
        %set(gcf,'position',[0 0 1920 1080])
        %screen2png([nsName '_sRF.png']);
        close all
        save(rfResultName, 'x2D','y2D','r2D','r2D0');
    else
        load(rfResultName, 'x2D','y2D','r2D');
    end
    
    
    %% spatial filtering
    r2Df = imgaussfilt(r2D, sigma/patchsize,'padding','circular');
    nr2D = normTensor(r2Df,[0 100]);%[1 99]%maybe ng
    
    
    %% superimposing spatial RFs
    x1D = unique(x2D);
    y1D = fliplr(unique(y2D));
    
    %% taking the offset relative to the forvea
    x1D = x1D - x0;
    y1D = y1D - y0;
    xrange = xrange - x0;
    yrange = yrange - y0;
    
    
    %% obtain RF positions w 2D gaussian fitting
    %< not great for size=1 stim
    % input initial guess?
    
    
    %     [fitresult, zfit, fiterr, zerr, resnorm, rr] = ...
    %         cellfun(@(x)fmgaussfit(x1D,y1D,x), num2cell(nr2D,[1 2]),...
    %         'UniformOutput',false); %need to supply normalized data otherwise not robust
    %ng r2Df
    %fitresult: [amp, angle, sxy, sy, xo, yo, zo]
    %when nr2D & r2Df are used:
    %fiterr: nan
    %zerr: nan
    %rr: nan
    
    disp('estimating RF peaks');
    tic
    % simpler version: do not fit angle, assume sigma_x = sigma_y
    [fitresult, resnorm] = ...
        cellfun(@(x)fmgaussfit_s(x1D,y1D,x,xrange,yrange), num2cell(nr2D,[1 2]),...
        'UniformOutput',false);
    %fitresult: [amp, s, xo, yo, zo]
    %resnorm: sum {(FUN(X,XDATA)-YDATA).^2}
    t=toc
    disp('done');
    
    testfun = @(x)(cell2mat(x(:)));
    fitresult = testfun(fitresult);
    resnorm = testfun(resnorm);
    
    nresnorm = resnorm / numel(x1D) / numel(y1D);
    RFx = fitresult(:,3);
    RFy = fitresult(:,4);
    
    %         figure('position',[0 0 1900 1000]);
    %         tiledlayout('flow');
    %         for ii = 1:size(theseImages,3)
    %             axeshandle(ii) = nexttile;%subplot(nRows, nCols, tt);
    %
    %             imagesc(x1D,y1D,theseImages(:,:,ii));
    %             hold on
    %             plot(RFx(ii),RFy(ii),'ro');
    %             tname = sprintf('%d amp:%.2f base:%.2f \n resnorm:%.2f', ...
    %                 ii, fitresult(ii,1), fitresult(ii,5), resnorm(ii));
    %
    %             axis ij
    %             title(tname);
    %         end
    %         screen2png(['fitResults_' imType]);
    
    
    %% exclude channels
    %criterion1: firing rates
    th_sp = 1000;
    NGIdx_sp = find(nTotSpikes < th_sp);
    
    %criterion2: resnorm
    th_resnorm = 0.013;%prctile(resnorm,95);
    NGIdx_resnorm = find(nresnorm > th_resnorm);
    %criterion2: rr ... NG
    %Idx_rr = find(isnan(rr));
    
    % criterion3: peak-base ratio
    th_pk = 0.7;
    NGIdx_pk = find(abs(fitresult(:,1)./fitresult(:,5)) < th_pk);
    
    % criterion4: amp against the noise level??
    
    NG_all = unique([NGIdx_resnorm; NGIdx_sp; NGIdx_pk]);
    Idx_all = setdiff(1:max(mdb2.channel), NG_all);
    
    
%     %% sanity check
%     nChPerPanel = 40;
%     a = 1:nChPerPanel:384;
%     for jj = 1:numel(a)
%         figure('position',[0 0 1900 1000]);
%         tiledlayout('flow');
%         for ii = a(jj):min(a(jj)+nChPerPanel, 384)%Idx_all(1:30)
%             axeshandle(ii) = nexttile;%subplot(nRows, nCols, tt);
%             
%             imagesc(x1D,y1D,nr2D(:,:,ii));
%             hold on
%             plot(RFx(ii),RFy(ii),'ro');
%             tname = sprintf('%d amp/base:%.2f \n resnorm:%.4f', ...
%                 ycoords(ii), fitresult(ii,1)/fitresult(ii,5), nresnorm(ii));
%             title(tname);
%             axis xy
%         end
%         saveas(gcf,[nsName '_allRFs_' num2str(jj) '_all.fig']);
%         close
%     end
    
     %% all neurons
     nChPerPanel = 20;
    Idx = 1:max(mdb2.channel);
    a = 1:nChPerPanel:numel(Idx);
    for jj = 1:numel(a)
        figure('position',[0 0 1900 1000]);
        tiledlayout('flow');
        if jj < numel(a)
            theseIdx = Idx(a(jj):min(a(jj+1)-1, numel(Idx)));
        else
            theseIdx = Idx(a(jj):numel(Idx));
        end
        for ii = 1:numel(theseIdx) %a(jj):min(a(jj)+nChPerPanel, 384)%Idx_all(1:30)
            %axeshandle(ii) = nexttile;%
            subplot(2,10,ii);
            
            kk = theseIdx(ii);
            imagesc(x1D,y1D,r2D(:,:,kk));
            axis equal tight;
            xlim(xrange);ylim(yrange);
            hold on
            plot(RFx(kk),RFy(kk),'ro');
            hline(0,gca,'-');vline(0,gca,'--');
            tname = sprintf('%d a/b:%.2f \n resnorm:%.4f', ...
                ycoords(kk), fitresult(kk,1)/fitresult(kk,5), nresnorm(kk));
            title(tname);
            axis xy
            %mcolorbar(gca,.5);
            colormap(flipud(gray));
        end
        saveas(gcf,[nsName '_allRFs_' num2str(jj) '_all.fig']);
        close
    end
    
   %% selected neurons with decent RF. figure for poster
    nChPerPanel = 20;
    a = 1:nChPerPanel:numel(Idx_all);
    for jj = 1:numel(a)
        figure('position',[0 0 1900 1000]);
        tiledlayout('flow');
        if jj < numel(a)
            theseIdx = Idx_all(a(jj):min(a(jj+1)-1, numel(Idx_all)));
        else
            theseIdx = Idx_all(a(jj):numel(Idx_all));
        end
        for ii = 1:numel(theseIdx) %a(jj):min(a(jj)+nChPerPanel, 384)%Idx_all(1:30)
            %axeshandle(ii) = nexttile;%
            subplot(2,10,ii);
            
            kk = theseIdx(ii);
            imagesc(x1D,y1D,r2D(:,:,kk));
            axis equal tight;
            xlim(xrange);ylim(yrange);
            hold on
            plot(RFx(kk),RFy(kk),'ro');
            hline(0,gca,'-');vline(0,gca,'--');
            tname = sprintf('%d a/b:%.2f \n resnorm:%.4f', ...
                ycoords(kk), fitresult(kk,1)/fitresult(kk,5), nresnorm(kk));
            title(tname);
            axis xy
            %mcolorbar(gca,.5);
            colormap(flipud(gray));
        end
        saveas(gcf,[nsName '_allRFs_' num2str(jj) '_select.fig']);
        close
    end
    
    %% RF position of all neruons
    figure('position',[0 0 1000 1000]);
    %Idx_all = 1:numel(channels);
    allChidx = 1:size(nr2D,3);
    subplot(411);
    %plot(ycoords,RFx,'-o');
    plot(ycoords(Idx_all),RFx(Idx_all),'color',[.5 .5 .5]);
    hold on
    scatter(ycoords(Idx_all),RFx(Idx_all),[],allChidx(Idx_all),'filled');
    ylim(xrange);
    xlim(prctile(ycoords(Idx_all),[0 100]));
    hline(0,gca,'-');
    ylabel('pref X [deg]');xlabel('distance from tip ch [um]');
    title([ nsName '_visField']);
    
    subplot(412);
    %plot(ycoords,RFy,'-o');
    plot(ycoords(Idx_all),RFy(Idx_all),'color',[.5 .5 .5]);
    hold on;
    scatter(ycoords(Idx_all),RFy(Idx_all),[],allChidx(Idx_all),'filled');
    ylim(yrange);
    xlim(prctile(ycoords(Idx_all),[0 100]));
    hline(0,gca,'--');
    ylabel('pref Y [deg]');xlabel('distance from tip ch [um]');
    
    subplot(4,1,[3 4]);
    plot(RFx(Idx_all), RFy(Idx_all),'color',[.5 .5 .5]);
    hold on
    scatter(RFx(Idx_all),RFy(Idx_all),[],allChidx(Idx_all),'filled');
    xlim(xrange); ylim(yrange);
    hline(0,gca,'--');vline(0,gca,'-');
    axis equal square padded;
    xlabel('pref X [deg]');ylabel('pref Y [deg]');
    

    saveas(gcf,[nsName '_visField2.fig'])
    close all
    
    
    
    %% raster plot
    figure('position',[0 0 1000 1000]);
    taxis = linspace(0, 20, 20*1e2)';
    %trace = zeros(numel(taxis),384);
    itr = 1;
    for ii = 1:384
        %plot(mdb.spikes.spk{1,itr,ii}, cfg.probeInfo.ycoords(mdb.spikes.chanIds(ii)),'.');hold on;
        xdata = [mdb.spikes.spk{1,itr,ii}];
        ydata = repmat( cfg.probeInfo.ycoords(mdb.spikes.chanIds(ii)), size(xdata));
        cdata = ydata;
        scatter(xdata,ydata,[],cdata,'.');hold on;
        
        %trace(:,ii) = event2Trace(taxis, xdata);
    end
    ylabel('channel depth [um]');
    xlabel('time [s]');
    axis tight padded;
    saveas(gcf,[nsName '_raster.fig'])
    close all
    
    save(rfResultName,'r2Df','nr2D','th_sp','nTotSpikes','th_resnorm','nresnorm',...
        'th_pk','fitresult','cfg','Idx_all','mdb2','xcoords','ycoords',...
        'x1D','x2D','y1D','y2D','-append');
end

% %     %vline(0);hline(0);
% %
% %     cp = jet(numel(superIdx));
% %     ax=[];
% %     for ii = 1:numel(superIdx)
% %         ax=subplot(2,numel(superIdx),ii);
% %         imSuper(ax, nr2D(:,:,superIdx(ii)), cp(ii,:), 1);
% %         title(mdb2.channel(superIdx(ii)));
% %         ax.YDir = 'normal';
% %         ax.XTick = [1 size(nr2D,2)];
% %         ax.XTickLabel = x1D(ax.XTick);
% %         ax.YTick = [1 size(nr2D,1)];
% %         ax.YTickLabel = y1D(ax.YTick);
% %         axis image ij
% %     end
% %     ax2=subplot(2,1,2);
% %     imSupers(ax2,nr2D(:,:,superIdx), cp, .5); %superposition of original images makes earlier images dark and invisible
% %     %imSupers(nr2D(:,:,idx)>.5, cp, .5); %only show pixels above threshold
% %     ax2.YDir = 'normal';
% %     ax2.XTick = [1 size(nr2D,2)];
% %     ax2.XTickLabel = x1D(ax2.XTick);
% %     ax2.YTick = [1 size(nr2D,1)];
% %     ax2.YTickLabel = y1D(ax2.YTick);
% %     axis image ij
% %
% %     screen2png([nsName '_super.png']);
% %
% %
% %     %% spatio-termporal RF
% %     % % Error in mapping.analysis.noisegrid/getSingleSquareResponse3D (line 664)
% %     % %                 spk_cat = spk_cat + catTimes; %spike time from the 1st trial onset
% %
% % tic
% %     [x2D,y2D,r2D,t] = mdb2.getSingleSquareResponse3D('channels',channels_strf,'window', ...
% %         window, 'rect',rect); %NG as of 27/10/22
% %     t2=toc;%244s/46ch
% %     r3D = reshape(r2D, [numel(unique(y2D)) numel(unique(x2D)) numel(channels_strf) numel(t)]);
% %     clim = prctile(r3D(:),[1 99.9]);
% %     for ich = 1:numel(channels_strf)
% %         for it = 1:numel(t)
% %             ax(ich,it) = subplot(numel(channels_strf),numel(t),it+(ich-1)*numel(t));
% %             imagesc(x2D,y2D,r3D(:,:,ich,it));axis equal tight
% %             title(sprintf('%.1f [ms]',1e3*t(it)));
% %
% %             axis image ij
% %             ax(ich,it).YDir = 'normal';
% %
% %             if it==1
% %                 ylabel(['ch: ' num2str(channels_strf(ich))]);
% %             end
% %             %caxis(clim);
% %         end
% %         linkcaxes(ax(ich,:));
% %         mcolorbar;
% %     end
% %     screen2png([nsName '_stRF.png']);
% %
% %     %Arrays have incompatible sizes for this operation.
% %     % Error in mapping.analysis.noisegrid/getSingleSquareResponse3D (line 653)
% %     %                 spk_cat = spk_cat + catTimes; %spike time from the 1st trial onset

