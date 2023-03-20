%wrapper_encoding.m
%this script loads processed data by makeDataBase.m,
%fit one pixel with ridge regression
%evaluate the fit result with in-silico simulation

if ~ispc
    addpath(genpath('~/git'));
    if exist('/home/dshi0006/.matlab/R2019b/matlabprefs.mat','file')
        delete('/home/dshi0006/.matlab/R2019b/matlabprefs.mat');
        edit('/home/dshi0006/.matlab/R2019b/matlabprefs.mat');
        fclose('all');
    end
    addDirPrefs;
end


ID = 2;
doTrain = 1; %train a gabor bank filter or use it for insilico simulation
doRF = 1;
doORSF = 1;

omitSec = 5; %omit initial XX sec for training
rescaleFac = 0.10;%0.25;

expInfo = getExpInfoNatMov(ID);

%% draw slurm ID for parallel computation specifying ROI position    
pen = getPen; 
narrays = 1000;
ngIdx = [ 5
          59
         339
         380
         387
         429
         447
         476
         484
         870
         871
         872
         873
         874
         875
         876
         877
         878
         879
         880
         881
         882
         883
         884
         885
         886
         887
         888
         889
         890
         891
         892
         893
         894
         895
         896
         897
         898
         899
         900
         901
         902
         903
         904
         905
         906
         907
         908
         909
         910
         911
         912
         913
         914
         915
         916
         917
         918
         919
         920
         921
         922
         923
         924
         925
         926
         927
         928
         929
         930
         931
         932
         933
         934
         935
         936
         937
         938
         939
         940
         941
         942
         943
         944
         945
         946
         947
         948
         949
         950
         951
         952
         953
         954
         955
         956
         957
         958
         959
         960
         961
         962
         963
         964
         965
         966
         967
         968
         969
         970
         971
         972
         973
         974
         975
         976
         977
         978
         979
         980
         981
         982
         983
         984
         985
         986
         987
         988
         989
         990
         991
         992
         993
         994
         995
         996
         997
         998
         999
        1000
        1005
        1059
        1339
        1380
        1387
        1429
        1447
        1476
        1484
        1870
        1871
        1872
        1873
        1874
        1875
        1876
        1877
        1878
        1879
        1880
        1881
        1882
        1883
        1884
        1885
        1886
        1887
        1888
        1889
        1890
        1891
        1892
        1893
        1894
        1895
        1896
        1897
        1898
        1899
        1900
        1901
        1902
        1903
        1904
        1905
        1906
        1907
        1908
        1909
        1910
        1911
        1912
        1913
        1914
        1915
        1916
        1917
        1918
        1919
        1920
        1921
        1922
        1923
        1924
        1925
        1926
        1927
        1928
        1929
        1930
        1931
        1932
        1933
        1934
        1935
        1936
        1937
        1938
        1939
        1940
        1941
        1942
        1943
        1944
        1945
        1946
        1947
        1948
        1949
        1950
        1951
        1952
        1953
        1954
        1955
        1956
        1957
        1958
        1959
        1960
        1961
        1962
        1963
        1964
        1965
        1966
        1967
        1968
        1969
        1970
        1971
        1972
        1973
        1974
        1975
        1976
        1977
        1978
        1979
        1980
        1981
        1982
        1983
        1984
        1985
        1986
        1987
        1988
        1989
        1990
        1991
        1992
        1993
        1994
        1995
        1996
        1997
        1998
        1999
        2000
        2005
        2059];

%% path
dataPaths = getDataPaths(expInfo,rescaleFac);
dataPaths.encodingSavePrefix = [dataPaths.encodingSavePrefix '_nxv'];

load( dataPaths.stimSaveName, 'TimeVec_stim_cat', 'dsRate','S_fin',...
    'gaborBankParamIdx');

%% estimation of filter-bank coefficients
trainParam.KFolds = 5; %cross validation
trainParam.ridgeParam = 1e6;%logspace(5,7,3); %[1 1e3 1e5 1e7]; %search the best within these values
trainParam.tavg = 0; %tavg = 0 requires 32GB ram. if 0, use avg within Param.lagFrames to estimate coefficients
trainParam.Fs = dsRate; %hz after downsampling
trainParam.lagFrames = 2:3;%round(0/dsRate):round(5/dsRate);%frame delays to train a neuron
trainParam.useGPU = 1; %for ridgeXs local GPU is not sufficient


%% stimuli
load(dataPaths.imageSaveName,'stimInfo')
stimSz = [stimInfo.height stimInfo.width];


%% load neural data
%TODO: copy timetable data to local
disp('Loading tabular text datastore');
ds = tabularTextDatastore(dataPaths.timeTableSaveName);

nTotPix = numel(ds.VariableNames)-1;
if ~isempty(ngIdx)
    maxJID=1;
else
    maxJID = numel(pen:narrays:nTotPix);
end
for JID = 1:maxJID
    if ~isempty(ngIdx)
        roiIdx = ngIdx(pen);
    else
        roiIdx = pen + (JID-1)*narrays;
    end
    
    %TODO: save data locally
    encodingSaveName = [dataPaths.encodingSavePrefix '_roiIdx' num2str(roiIdx) '.mat'];
    
    %% in-silico RF estimation
    RF_insilico = struct;
    RF_insilico.noiseRF.nRepeats = 80; %4
    RF_insilico.noiseRF.dwell = 15; %frames
    RF_insilico.noiseRF.screenPix = stimInfo.screenPix/8;%4 %[y x]
    RF_insilico.noiseRF.maxRFsize = 10; %deg in radius
    %<screenPix(1)/screenPix(2) determines the #gabor filters
    
    
    %% in-silico ORSF estimation
    RF_insilico.ORSF.screenPix = stimInfo.screenPix; %[y x]
    nORs = 10;
    oriList = pi/180*linspace(0,180,nORs+1)'; %[rad]
    RF_insilico.ORSF.oriList = oriList(1:end-1);
    SFrange_stim = getSFrange_stim(RF_insilico.ORSF.screenPix, stimSz);
    RF_insilico.ORSF.sfList = logspace(log10(SFrange_stim(1)), log10(SFrange_stim(2)), 6); %[cycles/deg];
    RF_insilico.ORSF.nRepeats = 15;
    RF_insilico.ORSF.dwell = 45; %#stimulus frames
    
    
    if doTrain
        %% load gabor bank prediction data
        %TODO load data tolocal
        RF_insilico.Fs_visStim = gaborBankParamIdx.predsRate;
        
        %% estimate the energy-model parameters w cross validation
        nMovies = numel(stimInfo.stimLabels);
        movDur = stimInfo.duration;%[s]
        trainIdx = [];
        for imov = 1:nMovies
            trainIdx = [trainIdx (omitSec*dsRate+1:movDur*dsRate)+(imov-1)*movDur*dsRate];
        end
        
        
        %% fitting!
        tic;
        lagRangeS = [trainParam.lagFrames(1) trainParam.lagFrames(end)]/trainParam.Fs;
        trained = trainAneuron(ds, S_fin, roiIdx, trainIdx, trainParam.ridgeParam,  ...
            trainParam.KFolds, lagRangeS, ...
            trainParam.tavg, trainParam.useGPU);
        t1=toc %6s!
        screen2png([encodingSaveName(1:end-4) '_corr']);
        close;
        
        %clear S_fin
        save(encodingSaveName,'trained','trainParam');
    else
        load(encodingSaveName,'trained','trainParam');
    end
    
    
    %% in-silico simulation to obtain RF
    if doRF
        RF_insilico = getInSilicoRF(gaborBankParamIdx, trained, trainParam, ...
            RF_insilico, stimSz);
        
        analysisTwin = [0 trainParam.lagFrames(end)/dsRate];
        RF_insilico = analyzeInSilicoRF(RF_insilico, -1, analysisTwin);
        showInSilicoRF(RF_insilico, analysisTwin);
        screen2png([encodingSaveName(1:end-4) '_RF']);
        close;        
        save(encodingSaveName,'RF_insilico','-append');
    end
    
    %% in-silico simulation to obtain ORSF
    if doORSF
        RF_insilico = getInSilicoORSF(gaborBankParamIdx, trained, trainParam, ...
            RF_insilico, stimSz, 3);
        showInSilicoORSF(RF_insilico);
        
        trange = [2 trainParam.lagFrames(end)/dsRate];

        RF_insilico = analyzeInSilicoORSF(RF_insilico, -1, trange, 3);
        screen2png([encodingSaveName(1:end-4) '_ORSF']);
        close;        
        save(encodingSaveName,'RF_insilico','-append');
    end

end
