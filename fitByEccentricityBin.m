function [avg_bin, coef, npix_bin, mebins, ste_bin] = fitByEccentricityBin(ebins, areaStats, statName)
% [stat_bin, coef, npix_bin, mebins] = fitByEccentricityBin(ebins, areaStats, statName)
% stat_bin: bin x area
% returns average and standard error across pixels within a bin
%created from fitByEccentricityBin(ebins, areaStats, statName)
mebins = ebins(1:end-1)+.5*mean(diff(ebins));
nAreas = numel(areaStats.eccentricity);
avg_bin = nan(numel(ebins)-1,nAreas);
ste_bin = nan(numel(ebins)-1,nAreas);

coef = nan(2, nAreas);
for iarea = 1:nAreas
    binIdx = discretize(areaStats.eccentricity{iarea}, ebins);
    for ibin = 1:numel(ebins)-1
        theseIdx = find(binIdx == ibin);
        avg_bin(ibin,iarea) = median(areaStats.(statName){iarea}(theseIdx));
        ste_bin(ibin, iarea) = ste_median(areaStats.(statName){iarea}(theseIdx));
        npix_bin(ibin,iarea) = numel(theseIdx);
    end
    try
        coef(:,iarea) = robustfit(mebins, avg_bin(:,iarea));
    catch
    end
end
