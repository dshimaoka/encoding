function expInfo = getExpInfoNatMov(ID)
% expInfo = getExpInfoNatMov(ID)
% returns:
% expInfo.subject
% expInfo.date
% expInfo.nsName
% expInfo.expID

switch ID
    case 1
        expInfo.subject = 'CJ224';
        expInfo.date = '20221004';
        expInfo.nsName = 'CJ224.runPassiveMovies.033059';
        expInfo.expID = 19;
    case 2
        expInfo.nsName = 'CJ231.runPassiveMovies.010848';
        expInfo.expID = 16;
        expInfo.subject = 'CJ231';
        expInfo.date = '20221130';
    case 3
        expInfo.nsName = 'CJ229.runPassiveMovies.024114';
        expInfo.expID = 21;
        expInfo.subject = 'CJ229';
        expInfo.date = '20221101';
    case 8
         expInfo.nsName = 'CJ246.runPassivemovies.052834';
        expInfo.expID = 20;
        expInfo.subject = 'CJ246';
        expInfo.date = '20230919';
    case 9
         expInfo.nsName = 'CJ246.runPassivemovies.035319';
        expInfo.expID = 30;
        expInfo.subject = 'CJ246';
        expInfo.date = '20230920';

end
