expID = 1;

switch expID
    case 1
        %CJ224
        load('\\storage.erc.monash.edu.au\shares\MNHS-dshi0006\Massive\processed\2022\10\04\resize10\encoding_2022_10_04_19_resize10_nxv_summary.mat');
        load('\\storage.erc.monash.edu.au\shares\MNHS-dshi0006\Massive\processed\2022\10\04\resize10\imageData_2022_10_04_19_resize10.mat','stimInfo')
        %screenDist = 0;
        %Cx: -10 ~+3, %Cy: -5 ~ +5
        %> stimInfo.width = 14; stimInfo.height = 14;
        %> max(srgange_mdl) = 2.3143
        stimXdeg = [-11 3];
        stimYdeg = [-7 7];
        
    case 2
        %CJ231
        load('\\storage.erc.monash.edu.au\shares\MNHS-dshi0006\Massive\processed\2022\11\30\resize10\encoding_2022_11_30_16_resize10_nxv_summary.mat');
        load('\\storage.erc.monash.edu.au\shares\MNHS-dshi0006\Massive\processed\2022\11\30\resize10\imageData_2022_11_30_16_resize10.mat','stimInfo')
        %screenDist = 2;
        
        %Cx: 9 ~ 30 %Cy: -12 ~ +10
        %> stimInfo.width = 22; stimInfo.height = 22;
        %> max(srgange_mdl) = 1.4730
        stimXdeg = [9 30];
        stimYdeg = [-12 10];
        %
        %CJ234
        %load('\\storage.erc.monash.edu.au\shares\MNHS-dshi0006\Massive\processed\2023\03\29\resize10\encoding_2023_03_29_12_resize10_nxv_summary.mat')
        %Cx: -10 ~ 10 %Cy: -5 ~ +15
        %
        %CJ235
        % load('\\storage.erc.monash.edu.au\shares\MNHS-dshi0006\Massive\processed\2023\04\05\resize10\encoding_2023_04_05_22_resize10_nxv_summary.mat')
        %Cx: -10 ~ +15, Cy: -15 ~ +10
        
    case 3
        %CJ229
        load('\\storage.erc.monash.edu.au\shares\MNHS-dshi0006\Massive\processed\2022\11\01\resize10\encoding_2022_11_01_21_resize10_nxv_summary.mat');
        load('\\storage.erc.monash.edu.au\shares\MNHS-dshi0006\Massive\processed\2022\11\01\resize10\imageData_2022_11_01_21_resize10.mat','stimInfo')
        %screenDist = 0;
        %Cx: -8~+0, %Cy: -4~+4
        stimXdeg = [-11 3];
        stimYdeg = [-7 7];
end

okpix=~isnan(summary.RF_Cx);
subplot(221);imagesc(summary.RF_Cx);colorbar;caxis(stimXdeg);
subplot(222);histogram(summary.RF_Cx(okpix),1000);xlim(stimXdeg);
subplot(223);imagesc(summary.RF_Cy);colorbar;caxis(stimYdeg);
subplot(224);histogram(summary.RF_Cy(okpix),1000);xlim(stimYdeg);


%% stimInfo 
% stimInfo.screenPix = [144 256]; %FIXED
% 
% switch screenDist
%     case 0
%         %CJ224, CJ229
%         stimInfo.width = 27;
%         stimInfo.height = 15;
%     case 1
%         %CJ229(ONLY EPHYS)
%         stimInfo.width = 45;
%         stimInfo.height = 25;
%     case 2
%         %CJ231 and onwards
%         stimInfo.width = 70;
%         stimInfo.height = 40;
% end

stimInfo_new.width = diff(stimXdeg);
stimInfo_new.height = diff(stimYdeg);

%stimInfo_new.screenPix(2) = round(stimInfo_new.width/stimInfo.width * stimInfo.screenPix(2));
%stimInfo_new.screenPix(1) = round(stimInfo_new.height/stimInfo.height * stimInfo.screenPix(1));
[stimXpix, stimYpix] = stimDeg2Pix(stimInfo, stimXdeg, stimYdeg);
stimXpix = round(stimXpix);
stimYpix = round(stimYpix);
stimInfo_new.screenPix(2) = diff(stimXpix);
stimInfo_new.screenPix(1) = diff(stimYpix);

%[stimXdeg, stimYdeg] = stimPix2Deg(stimInfo_new, [1 stimInfo_new.screenPix(2)], [1 stimInfo_new.screenPix(1)]);
screenDeg = [diff(stimXdeg) diff(stimYdeg) ];

gparamIdx = 2;
sfrange_stim = getSFrange_stim(stimInfo_new.screenPix, screenDeg) % DONT depend on screen ROI
sfrange_mdl = getSFrange_mdl(stimInfo_new.screenPix, screenDeg, gparamIdx) %DO depent on screen ROI

