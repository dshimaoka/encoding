function [stat_bin, coef, mebins] = fitByEccentricityBin(ebins, areaStats, statName)
%[mebins, coef] = fitByEccentricityBin(ebins, areaStats, statName)
mebins = ebins(1:end-1)+.5*mean(diff(ebins));
nAreas = numel(areaStats.eccentricity);
stat_bin = nan(numel(ebins)-1,nAreas);
coef = nan(2, nAreas);
for iarea = 1:nAreas
    binIdx = discretize(areaStats.eccentricity{iarea}, ebins);
    for ibin = 1:numel(ebins)-1
        theseIdx = find(binIdx == ibin);
        stat_bin(ibin,iarea) = median(areaStats.(statName){iarea}(theseIdx));
    end
    try
        coef(:,iarea) = robustfit(mebins, stat_bin(:,iarea));
    catch
    end
end
