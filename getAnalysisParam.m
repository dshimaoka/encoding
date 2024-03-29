function [aparam] = getAnalysisParam(ID)
%created from alignVFS.m

switch ID
    case 1
        aparam.stimSuffix = '_square15';
        aparam.regressSuffix = '_nxv';
        aparam.corrth = 0.26;
        aparam.showXrange = [-7 0]; aparam.showYrange = [-3.8 3.8];
        aparam.flipLR = false;
        aparam.brainPix(1).brain_y = 30:52;%32:44;
        aparam.brainPix(1).brain_x = 16;
        aparam.brainPix(2).brain_y = 31;
        aparam.brainPix(2).brain_x = 6:18;
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
end
