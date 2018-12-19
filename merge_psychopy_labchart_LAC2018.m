clear all;

prompt = 'Create merged CSV and Ledalab .mat? (0 or 1) ';
process = input(prompt);

number_of_subjects=[1 2 3 4 5 6];


% set filenames
for j = number_of_subjects
    %try
        diary on;
        
        fprintf('______________________________________________');
        fprintf('\n\n\nCurrent subject: no. %02d.\n', j);

        filename_csv =  ['../data/PsychoPy/' num2str(j,'%02d') '_LAC_2018_Dec.csv'];
        filename_mat = ['../data/Labchart-MAT/' num2str(j,'%02d') '.mat'];
        filename_table = ['../data/export/merged-csv/' num2str(j,'%02d') '_100Hz-merged.csv'];
        filename_leda = ['../data/export/ledalab-mat/' num2str(j,'%02d') '_100HZ-LEDALAB.mat'];
        filename_log = ['../data/export/log/' num2str(j,'%02d') '_intensity_log.txt'];
        filename_vbs = ['../data/export/labchart-macro/' num2str(j,'%02d') '_labchart-macro.vbs'];
            
        
        
        table_unsorted = read_psychopy(filename_csv);
        
        
        %import .mat
        display('Opening .mat file...')
        load('-mat', filename_mat);

        %import timestamp and condition as column vector
        clock_lab = datetime(blocktimes(1),'ConvertFrom','datenum'); % if multiple blocks exist chose the time frome the first one
        clock_lab.TimeZone = 'Europe/Berlin';
        fprintf('Time from LabChart: %s\n',datestr(clock_lab,'HH:MM:SS'))

        % convert to posixtime, timezone is set before (therefore one hour
        % adjustment)
        posixtime_clock_lab = posixtime(clock_lab);
        fprintf('Converted time from Labchart to posixtime: %16.f\n', posixtime_clock_lab)

        

        % sort table by stimuli_unixtime
        table_sorted = sortrows(table_unsorted, 'stimuli_unixtime');
        
        
        %% REMOVE unnecessary rows
        
        
        toDelete = isnan(table_sorted.stimuli_unixtime);
        table_sorted(toDelete,:) = [];
        
        
        %% Check size of table
        
        size_table_sorted = size(table_sorted);
        if size_table_sorted(1) == 61
            disp("Sorted and filtered table has, as expected, 61 rows") 
            
        else
            disp("Sorted and filtered table has NOT 61 rows. It size is: ") 
            size(table_sorted)
            ME = MException('table_sorted has more or less than 61 rows.')
            throw(ME)
            
        end
        
        
        %% set odor of the baseline event in the beginning
        table_sorted.odor(1) = "baseline_empty";
        
        
        %% Convert times
        % get the clock from the stimuli time
        clock_psychopy = datetime(table_sorted.stimuli_time(2),'Format','HH:mm:ss.SSSSSS');       
        fprintf('Time from Psychopy (Baseline Start): %s\n',clock_psychopy)
        
        % get a datetime from the posixtime
        time_psychopy = datetime(table_sorted.stimuli_unixtime(2),'ConvertFrom','posixtime','TimeZone','Europe/Berlin');

        % this is the posixtime. remember its UTC
        fprintf('Posixtime from Psychopy: %16.f\n', (table_sorted.stimuli_unixtime(2)))

        
        time_deltas = zeros(1,height(table_sorted));
        for i = 1:height(table_sorted)
            posixtime_psychopy = table_sorted.stimuli_unixtime(i);
            
            time_deltas(i) = posixtime_psychopy - posixtime_clock_lab;
        end
        
        
        if time_deltas(2) > 60*10
            fprintf('Time difference between first event and Labchart start is more than 10 minutes. It is %f minutes.\n', (time_deltas(1)/60))
            ME = MException('Time difference too big.')
            throw(ME)
        else
            fprintf('Time difference is less than 10 minutes. It is %f minutes.\n', (time_deltas(1)/60));
        end
        
        

        labchart_comments_macro(table_sorted, time_deltas, filename_vbs)
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        time_deltas;
            
        %display('Time from Psychopy:')
        %table_sorted.Timestamp;
        %display('Therefore this is the offset (time in seconds between starting labchart and the event):')
        %time_difference;
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        if process == 1 
        
            channel1 = data(datastart(1):dataend(1)); % respiration
            channel2 = data(datastart(2):dataend(2)); % respiration smoothed
            channel3 = data(datastart(3):dataend(3)); % skin conductance
            channel4 = data(datastart(4):dataend(4)); % pulse raw
            channel5 = data(datastart(5):dataend(5)); % pulse processed BPM


            % Calculate mean of 10 rows, then the next 10 rows, etc. 
            %also transform the vector
            channel1 = mean(reshape(channel1,10,[]))'; 
            channel2 = mean(reshape(channel2,10,[]))';
            channel3 = mean(reshape(channel3,10,[]))';
            channel4 = mean(reshape(channel4,10,[]))';
            channel5 = mean(reshape(channel5,10,[]))';



            clear odor;
            events = zeros(1,(dataend(1)/10));
            %odors{1,(dataend(1)/10)} = [];
            odors = zeros(1,(dataend(1)/10));

            %odor = blanks(dataend(1));

            %% Create Event Arrays

            % loop over event table
            for i=1:height(table_sorted)
                current_time = round(time_deltas(i)*100);
                current_event = table_sorted.odor(i);

                events(current_time) = 1;
                odors(current_time) = current_event;
            end

            events = events(:);
            odors = odors(:);
            
            %% Write Data to Table
            
            %T = table(channel1, channel2, channel3, events, odors);
            T = table(channel3, events, odors);
            % write table
            writetable(T,filename_table,'Delimiter',';')

    
            %% Create ledalab struct
            
            ledalab = struct;
            ledalab.conductance = channel3';
            %ledalab.conductance = ledalab.conductance + abs(min(ledalab.conductance));
            ledalab.conductance = ledalab.conductance * 10^6; % they want the data in micro 10^-6
            ledalab.time = [0.01:0.01:(dataend(1)/1000)]; % were doing this with 100 Hz
            ledalab.timeoff = 0;
            ledalab.event = struct;

            for i=1:height(table_sorted)
                current_event = table_sorted.odor(i);
                ledalab.event(i).time = time_deltas(i);
                ledalab.event(i).nid = i;
                ledalab.event(i).name = char(current_event);
                ledalab.event(i).userdata = [];
            end

            data = ledalab;

            save(filename_leda,'data');
        end
        
%     catch exception
%          display('CAUGHT EXCEPTION');
%          fprintf('Problem merging: no. %02d\n', j);
%          fprintf('Exception: %s\n', exception.message);
%          display('Continuing with the next subject.');
%          %clearvars -except choice;
%          continue;
    
    display('Finished subject, clearing...')
    
    diary(filename_log);
    diary off;

    
    clearvars -except choice process;
    %end
    
    % end
end

display('Finished all, clearing...')



function[table_unsorted] = read_psychopy(filename_csv)
    
    %% Initialize variables.
    delimiter = ',';
    startRow = 2;

    %% Format string for each line of text:

    formatSpec = '%s%f%s%s%s%s%f%f%f%f%s%s%s%s%s%s%f%s%s%s%s%s%s%s%s%s%s%s%f%s%f%s%s%f%f%f%f%f%f%f%f%f%f%s%s%s%s%s%s%f%s%s%s%s%[^\n\r]';

    %% Open the text file.
    display('Opening CSV file...')
    fileID = fopen(filename_csv,'r');

    %% Read columns of data according to format string.  
    dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, ...
    'TextType', 'string', 'HeaderLines' ,startRow-1, 'ReturnOnError', false, ...
    'EndOfLine', '\r\n');


    %% Close the text file.
    fclose(fileID);

    %% Create output variable
    table_unsorted = table(dataArray{1:end-1}, 'VariableNames', {'odor', ...
        'channel','baseline_trialthisRepN','baseline_trialthisTrialN', ...
        'baseline_trialthisN','baseline_trialthisIndex','trialsthisRepN', ...
        'trialsthisTrialN','trialsthisN','trialsthisIndex','key_welcomekeys', ...
        'key_welcomert','key_instructionskeys','key_instructionsrt', ...
        'key_baseline_instructionkeys','key_baseline_instructionrt', ...
        'stimuli_unixtime','baseline_time','baseline_clock','key_baselinekeys', ...
        'key_beginningkeys','key_beginningrt','example_ratingresponse', ...
        'example_ratingrt','key_startingkeys','key_startingrt','inhale_unixtime', ...
        'inhale_time','inhale_clock','key_respirationkeys','key_respirationrt', ...
        'key_resp_overwritekeys','stimuli_time','stimuli_clock', ...
        'intensity_ratingresponse','intensity_ratingrt','pleasantness_ratingresponse', ...
        'pleasantness_ratingrt','familarity_ratingresponse','familarity_ratingrt', ...
        'arousel_ratingresponse','arousel_ratingrt','trial_duration', ...
        'key_interstimuluskeys','rating_name_of_odorresponse','rating_name_of_odorrt', ...
        'key_endkeys','key_endrt','participant','session','date','expName', ...
        'psychopyVersion','frameRate'});

    %% Clear temporary variables
    clearvars filename delimiter startRow formatSpec fileID dataArray ans;

    %% Remove unecessary columns

    table_unsorted = removevars(table_unsorted,{'channel','baseline_trialthisRepN','baseline_trialthisTrialN','baseline_trialthisN','baseline_trialthisIndex','trialsthisRepN','trialsthisTrialN','trialsthisIndex','key_welcomekeys','key_welcomert','key_instructionskeys','key_instructionsrt','key_baseline_instructionkeys','key_baseline_instructionrt','key_baselinekeys','key_beginningkeys','key_beginningrt','example_ratingresponse','example_ratingrt','key_startingkeys','key_startingrt','key_respirationkeys','key_respirationrt','key_resp_overwritekeys','intensity_ratingresponse','intensity_ratingrt','pleasantness_ratingresponse','pleasantness_ratingrt','familarity_ratingresponse','familarity_ratingrt','arousel_ratingresponse','arousel_ratingrt','key_interstimuluskeys','rating_name_of_odorresponse','rating_name_of_odorrt','key_endkeys','key_endrt','participant','session','date','expName','psychopyVersion','frameRate'});

end

function labchart_comments_macro(table_sorted, time_deltas, filename_vbs)
%%%%% CREATE DATA FOR LABCHART COMMENTS %%%%%%

    file_vbs = fopen(filename_vbs,'w');
    fprintf(file_vbs, 'times = Array(');
    for i=1:(height(table_sorted)-1)
        fprintf(file_vbs, '%i, ', round(1000*time_deltas(i)));
    end
    fprintf(file_vbs, '%i)\n\n\n', round(1000*time_deltas(height(table_sorted))));

    fprintf(file_vbs, 'events = Array(');
    for i=1:(height(table_sorted)-1)
        fprintf(file_vbs, '"%s", ', char(table_sorted.odor(i)));
    end
    fprintf(file_vbs, '"%s")\n\n', char(table_sorted.odor(height(table_sorted))));

    fprintf(file_vbs, 'number_of_tries = %i', height(table_sorted));
end