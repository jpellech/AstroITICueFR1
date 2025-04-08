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

%% 1. Export peak information instead of full time series
% GCaMP peaks
if ~isempty(glocs)
    GPeaks = table(glocs(:), gprom(:), gwidth(:), ...
        'VariableNames', {'PeakTime_sec', 'Prominence', 'Width'});
else
    GPeaks = table([], [], [], 'VariableNames', {'PeakTime_sec', 'Prominence', 'Width'});
end
writetable(GPeaks, excelFile, 'Sheet', 'GCaMP_Peaks');

% DA peaks
if ~isempty(dlocs)
    DPeaks = table(dlocs(:), dprom(:), dwidth(:), ...
        'VariableNames', {'PeakTime_sec', 'Prominence', 'Width'});
else
    DPeaks = table([], [], [], 'VariableNames', {'PeakTime_sec', 'Prominence', 'Width'});
end
writetable(DPeaks, excelFile, 'Sheet', 'DA_Peaks');

%% 2. Export aligned event data
% Reward Head Entry aligned data
if ~isempty(GalignRewHE)
    RewHE_GCaMP = table(GalignRewHE(:), 'VariableNames', {'GCaMP_dFF'});
    RewHE_DA = table(DalignRewHE(:), 'VariableNames', {'DA_dFF'});
    writetable(RewHE_GCaMP, excelFile, 'Sheet', 'RewHE_GCaMP');
    writetable(RewHE_DA, excelFile, 'Sheet', 'RewHE_DA');
end

% Similarly for other events (Cue, Reward, etc.) - add as needed

%% 3. Metadata
metadata = table(...
    {datasetName}, fs, length(time), datetime('now'), ...
    'VariableNames', {'Dataset','SamplingRate','OriginalPoints','ExportTime'});
writetable(metadata, excelFile, 'Sheet', 'Metadata');

end