% For help see http://www.ledalab.de/ documentation

% the ledalab .mat files need to be available as multiple duplicates
% every subfolder 01, 02, 03 etc needs to have all ledalab .mat files

% Number of different sets of initial values to be considered in optimization
optimize_level = 3;

path_with_baseline = '/Users/nope/ownCloud/work/uka/code/LAC-2018/data/Ledalab-batch-analysis/with-baseline/';
path_without_baseline = '/Users/nope/ownCloud/work/uka/code/LAC-2018/data/Ledalab-batch-analysis/no-baseline/';

% Apply low-pass Butterworth filter with given settings, e.g. [1 5] for a 1rst order low-pass filter with 5Hz cutoff
filter_parameters = [[0 0]; ...
                    [2 5] % 2nd order, cutoff 5 Hz.  % TODO 2nd order, cutoff 2 Hz
                    ];

% E.g., [1 4 .01 1] will use a response-window of 1 to 4 sec after the event, 
% an minimum amplitude threshold criterion of 0.01 muS and export the results to a Matlab file
era_settings = [[0.5 30.5 .05 2]; ...
                [0.5 30.5 .1 2]; ...
                [0.5 10.5 .05 2]; ...
                [0.5 10.5 .1 2]; ...
                [0.0 10 .05 2]; ...
                [0.0 10 .1 2]
                ];

% E.g., [.05 1] will export a list of detected SCRs 
% using a minimum amplitude criterion of 0.05 muS to a Matlab file.
scr_settings = [[.05 2]
                ];


%% with baseline
j=1;
input_path = path_with_baseline
for filter_parameter = filter_parameters'
    for era_setting = era_settings'
        for scr_setting = scr_settings'
            path = [input_path num2str(j,'%02d/')]
            create_readme(path, filter_parameter, era_setting, scr_setting)
            ledalab_batch_analysis(path, filter_parameter', optimize_level', era_setting', scr_setting')

            j=j+1;
        end
        j=j+1;
    end
    j=j+1;
end


%% without baseline
j=1;
input_path = path_without_baseline
for filter_parameter = filter_parameters'
    for era_setting = era_settings'
        for scr_setting = scr_settings'
            path = [input_path num2str(j,'%02d/')]
            create_readme(path, filter_parameter, era_setting, scr_setting)
            ledalab_batch_analysis(path, filter_parameter', optimize_level', era_setting', scr_setting')

            j=j+1;
        end
        j=j+1;
    end
    j=j+1;
end





%Ledalab('/Users/nope/ownCloud/work/uka/code/LAC-2018/data/export/test/04-3downsample/', 'open', 'mat', 'analyze', 'CDA', 'downsample', 3, 'optimize', 2, 'export_era', [1 30 0.05 2], 'overview', 1)

    
function[] = ledalab_batch_analysis(path, filter_parameter, optimize_level, era_setting, scr_setting)
    if filter_parameter == 0
        Ledalab(path ,'open','mat', ...
        'analyze','CDA' , ...
        'optimize', optimize_level, ...
        'export_era', era_setting, ...
        'export_scrlist', scr_setting, ...
        'overview', 1)
    else
        Ledalab(path ,'open','mat', ...
        'analyze','CDA', ...
        'optimize', optimize_level, ...
        'filter', filter_parameter, ...
        'export_era', era_setting, ...
        'export_scrlist', scr_setting, ...
        'overview', 1)
    end
end
% Ledalab(path ,'open','mat', 'analyze','CDA', 'optimize', optimize_level, 'export_era', era_setting, 'overview', 1)
function[] = create_readme(path, filter_parameter, era_setting, scr_setting)
    formatSpec = 'The current path is:\n\t%s\n\nFilter parameters are set to: \n\torder: %d \n\tcutoff: %2.2f\n\nera_settings: \n\tstarting at: %2.2f \n\tstopping at: %2.2f \n\tminimum amplitude: %2.4f \n\toutput-mode: %d\n\nscr_setting: \n\tminimum amplitude: %2.4f \n\toutput-mode: %d\n';
    formatSpec = [formatSpec '\n\nHelp:\n'];
    formatSpec = [formatSpec '------------\n'];
    formatSpec = [formatSpec '\n\nfilter_parameters:\n\t  Apply low-pass Butterworth filter with given settings, e.g. [1 5] for a 1rst order low-pass filter with 5Hz cutoff'];
    formatSpec = [formatSpec '\n\nera_settings:\n\t E.g., [1 4 .01 1] will use a response-window of 1 to 4 sec after the event,  an minimum amplitude threshold criterion of 0.01 muS and export the results to a Matlab file'];
    formatSpec = [formatSpec '\n\nscr_settings:\n\t E.g., [.05 1] will export a list of detected SCRs using a minimum amplitude criterion of 0.05 muS to a Matlab file.'];

    fileID = fopen(strcat(path, '_README-parameters.txt'), 'w');
    fprintf(fileID, formatSpec, path, filter_parameter, era_setting, scr_setting);
    fclose(fileID);
end