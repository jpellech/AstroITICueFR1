function exportPhotometryDataToExcel(time, fs, GCamp_dFF, GRABDA_dFF, ...
    dlocs, dprom, dwidth, glocs, gprom, gwidth, ...
    GalignCue, DalignCue, GalignReward, DalignReward, ...
    GalignHE, DalignHE, GalignRewHE, DalignRewHE, ...
    datasetName, outputPath)

% Create filename with timestamp
excelFile = fullfile(outputPath, [datasetName '_Analysis_' datestr(now,'yyyymmdd_HHMM') '.xlsx']);

% Delete existing file if it exists
if exist(excelFile, 'file')
    delete(excelFile);
end

%% 1. Export raw time series data (split across sheets if needed)
max_points = 1048575; % Excel row limit per sheet (2^20 - 1 for header)
total_points = length(time);

if total_points > max_points
    num_sheets = ceil(total_points / max_points);
    warning('Data exceeds Excel row limit. Splitting raw data into %d sheets', num_sheets);
    
    for sheet_num = 1:num_sheets
        start_idx = (sheet_num-1)*max_points + 1;
        end_idx = min(sheet_num*max_points, total_points);
        
        time_export = time(start_idx:end_idx);
        GCamp_export = GCamp_dFF(start_idx:end_idx);
        GRABDA_export = GRABDA_dFF(start_idx:end_idx);
        
        timeData = table(time_export(:), GCamp_export(:), GRABDA_export(:), ...
            'VariableNames', {'Time_sec', 'GCaMP_dFF', 'GRABDA_dFF'});
        
        sheet_name = sprintf('RawSignals_%d', sheet_num);
        writetable(timeData, excelFile, 'Sheet', sheet_name, 'WriteMode', 'overwritesheet');
    end
else
    timeData = table(time(:), GCamp_dFF(:), GRABDA_dFF(:), ...
        'VariableNames', {'Time_sec', 'GCaMP_dFF', 'GRABDA_dFF'});
    writetable(timeData, excelFile, 'Sheet', 'RawSignals');
end

%% 4. Metadata
if total_points > max_points
    num_sheets = ceil(total_points / max_points);
    splitting_info = sprintf('Split into %d sheets', num_sheets);
else
    splitting_info = 'Single sheet';
end

metadata = table(...
    {datasetName}, fs, length(time), datetime('now'), {splitting_info}, ...
    'VariableNames', {'Dataset','SamplingRate','OriginalPoints','ExportTime','DataSplitting'});
writetable(metadata, excelFile, 'Sheet', 'Metadata');

fprintf('Successfully exported data to: %s\n', excelFile);
end