% ==> Name your working directory where analyzed *_era-files are located:
wdir = '/Users/paris/Downloads/test/era/';     
files = dir([wdir, '*.mat']);   %List all files that resulted from event-related analysis (ERA) in Ledalab

output_file = [wdir,'ledalab_results', datestr(now, 'yyyymmdd_HHMMSS'),'.csv'];
% open output file
f = fopen(output_file, 'w');
fprintf(f, 'id,    pattern,    bodysite,   CDA.nSCR,   CDA.Latency.[s],    CDA.AmpSum.[muS],   CDA.SCR.[muS],  CDA.ISCR.[muSxs],   CDA.PhasicMax.[muS],    CDA.Tonic.[muS],    TTP.nSCR,   TTP.Latency.[s],    TTP.AmpSum.[muS],   Global.Mean.[muS],  Global.MaxDeflection.[muS]\n');

 %% Read data for each file
for iFile = 1:length(files)

    filename_list{iFile} = files(iFile).name(1:end-8); %Get file name (without _era extension)
    era = load([wdir,files(iFile).name]);   %Load single file

    iEvent = 1; % I care about only one event

    %break the file name into 3 parts
    % split the filename parts
    baseFileName = strsplit(filename_list{iFile},'_');

    id =baseFileName(1,1);
    pattern =baseFileName(1,2);
    bodysite = baseFileName(1,3);
    if strcmp(bodysite, 'LowerBack')
        bodysite = 'Lowerback';
    end

    fprintf(f,'%s,\t%s,\t%s,\t%d,\t%.8f,\t%.9f,\t%.8f,\t%.8f,\t%.8f,\t%.8f,\t%d,\t%.8f,\t%.8f,\t%.8f,\t%.8f\n',...
                 char(id),  ...
                 char(pattern),  ...
                 char(bodysite),  ...
                 era.results.CDA.nSCR(iEvent), ...
                 era.results.CDA.Latency(iEvent), ...
                 era.results.CDA.AmpSum(iEvent),...
                 era.results.CDA.SCR(iEvent), ...
                 era.results.CDA.ISCR(iEvent),...
                 era.results.CDA.PhasicMax(iEvent),...
                 era.results.CDA.Tonic(iEvent), ...
                 era.results.TTP.nSCR(iEvent),...
                 era.results.TTP.Latency(iEvent),...
                 era.results.TTP.AmpSum(iEvent),...
                 era.results.Global.Mean(iEvent),...
                 era.results.Global.MaxDeflection(iEvent) );

end

fclose('all');