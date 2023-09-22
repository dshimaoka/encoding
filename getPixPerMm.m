function pixPermm = getPixPerMm(rescaleFac)
%pixPermm = getPixPerMm(rescaleFac)
%cf note_magnificationFactor.m

%pixPermm = 31.25*rescaleFac;

camPix = 1004;
FoVmm = 24; %mm, cf. measuring Olympus SDFPLAPO 0.5XPF
pixPermm = camPix/FoVmm*rescaleFac; %24/8/2023