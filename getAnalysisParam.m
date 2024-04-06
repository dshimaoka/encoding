function [aparam] = getAnalysisParam(ID, stimInfo)
%aparam = getAnalysisParam(ID)
% returns:
% aparam.stimSuffix 
% aparam.regressSuffix 
% aparam.corrth 
% aparam.showXrange 
% aparam.showYrange
% aparam.flipLR;
% aparam.brainPix(1).brain_y
% aparam.brainPix(1).brain_x
% aparam.brainPix(2).brain_y
% aparam.brainPix(2).brain_x
%
% created from alignVFS.m

if nargin < 2
    stimInfo = [];
end

switch ID
    case 1
        aparam.stimSuffix = '_square15';
        aparam.regressSuffix = '_nxv';
        aparam.corrth = 0.26;
        aparam.showXrange = [-7 0]; aparam.showYrange = [-3.8 3.8];
        aparam.flipLR = false;
        aparam.brainPix(1).brain_y = 30:52;
        aparam.brainPix(1).brain_x = 16;
        aparam.brainPix(2).brain_y = 31;
        aparam.brainPix(2).brain_x = 6:18;
        if nargin == 2
            aparam.xlim = prctile(stimInfo.stimXdeg,[0 100]);
            aparam.ylim = prctile(stimInfo.stimYdeg,[0 100]);
        end
        aparam.stimXrange = 24:156; %201:256; %1:left
        aparam.stimYrange = 5:139; %72-28+1:72+28;  %1:top
        %         aparam.stimXrange = 13:156;
        %         aparam.stimYrange = 1:144;
    case 2
        aparam.stimSuffix = '_part';
        aparam.regressSuffix = '_nxv';
        aparam.corrth = 0.24;
        aparam.showXrange = [-10 1]; aparam.showYrange = [-7.5 7.5];
        aparam.flipLR = false;
        aparam.brainPix(1).brain_y = 22:43;
        aparam.brainPix(1).brain_x = 21;
        aparam.brainPix(2).brain_y = 25;
        aparam.brainPix(2).brain_x = 9:23;
        if nargin == 2
            aparam.xlim = prctile(stimInfo.stimXdeg,[0 100]);
            aparam.ylim = prctile(stimInfo.stimYdeg,[0 100]);
        end
        aparam.stimXrange = 161:238;
        aparam.stimYrange = 29:108;

    case 3
        aparam.stimSuffix = '_part';
        aparam.regressSuffix = '_nxv';
        aparam.corrth=0.29;
        aparam.showXrange = [-7 0]; aparam.showYrange = [-3.8 3.8];
        aparam.flipLR = false;
        aparam.brainPix(1).brain_y = 27:48;
        aparam.brainPix(1).brain_x = 22;
        aparam.brainPix(2).brain_y = 29;%28;
        aparam.brainPix(2).brain_x = 7:24;
        aparam.xlim = [-5 1]-3;
        aparam.ylim = [-4 6];
        aparam.stimXrange = 24:156; %201:256; %1:left
        aparam.stimYrange = 5:139; %72-28+1:72+28;  %1:top

    case 8
        aparam.stimSuffix = '_square30';
        aparam.regressSuffix = '_nxv';
        aparam.corrth=0.3;
        aparam.showXrange = [-10 1]; aparam.showYrange = [-7.5 7.5];
        aparam.flipLR = false;
        aparam.brainPix(1).brain_y = 22:45;
        aparam.brainPix(1).brain_x = 18;
        aparam.brainPix(2).brain_y = 25;
        aparam.brainPix(2).brain_x = 7:19;%21;
        aparam.xlim = [-6 2];
        aparam.ylim = [-13 9.14];
        aparam.stimXrange = 293:1080;
        aparam.stimYrange = 293:1080;

  case 9
        aparam.stimSuffix = '_square30_2';
        aparam.regressSuffix = '_nxv';
        aparam.corrth=0.33;
        aparam.showXrange = [-10 1]; aparam.showYrange = [-7.5 7.5];
        aparam.flipLR = true;
           aparam.brainPix(1).brain_y = 20:43;
        aparam.brainPix(1).brain_x = 24;
        aparam.brainPix(2).brain_y = 21;
        aparam.brainPix(2).brain_x = 23:39;
        aparam.xlim = [-10 2];
        aparam.ylim = [-15 9.14];
        aparam.stimXrange = 816:1616;
        aparam.stimYrange = 280:1080;
        %aparam.stimXrange = [850:(850+756)];
        %aparam.stimYrange = [297:1053];
end
