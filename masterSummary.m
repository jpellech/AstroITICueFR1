function MasterSummary(outputPath, varargin)
%   Creates a consolidated summary of all photometry data
%   masterSummary(outputPath, 'parameter', value) accepts:
%       'includeRaw'    - true/false whether to include raw traces (default: false)
%       'metrics'       - cell array of metrics to include (default: all)
%       'filePattern'   - pattern to match analysis files (default: '*.mat')

% Default params
p = inputParser;
addParameter(p, 'includeRaw', false, @islogical);
addParameter(p, 'metrics', {'RewHE_DA', 'RewHE_GCaMP', 'Cue_DA', 'Cue_GCaMP'}, @iscell);
addParameter(p, 'filePattern', '*.mat', @ischar);
parse(p, varargin{:});

% Find all analysis files in the output directory
fileList = dir(fullfile(outputPath, p.Results.filePattern));
if isempty(fileList)
    error('No analysis files found matching pattern: %s', p.Results.filePattern);
end

% Init
masterData = struct();
summaryStats = struct();

% Processing
for i = 1:length(fileList)
    filePath = fullfile(outputPath, fileList(i).name);
    data = load(filePath);
    
    % Get mouse name (remove '_Analysis' and timestamp)
    [~, fileName] = fileparts(fileList(i).name);
    mouseName = regexprep(fileName, '_Analysis_.*$', '');
    
    % Basic info
    masterData(i).mouseName = mouseName;
    masterData(i).file = fileList(i).name;
    
    % Store aligned event data and  corresponding time vectors
    for j = 1:length(p.Results.metrics)
            metric = p.Results.metrics{j};
            try
                switch metric
                    case 'RewHE_DA'
                        masterData(i).RewHE_DA = data.DalignRewHE(:);
                        masterData(i).RewHE_DA_time = data.Aligntime1(1:length(data.DalignRewHE))';
                    case 'RewHE_GCaMP'
                        masterData(i).RewHE_GCaMP = data.GalignRewHE(:);
                        masterData(i).RewHE_GCaMP_time = data.Aligntime1(1:length(data.GalignRewHE))';
                    case 'Cue_DA'
                        % Safe access to cue-aligned data
                        if isfield(data, 'DalignCue') && isfield(data, 'Aligntime')
                            validLength = min(length(data.DalignCue), length(data.Aligntime));
                            masterData(i).Cue_DA = data.DalignCue(1:validLength)';
                            masterData(i).Cue_DA_time = data.Aligntime(1:validLength)';
                        else
                            error('Missing required fields');
                        end
                    case 'Cue_GCaMP'
                        % Safe access to cue-aligned data
                        if isfield(data, 'GalignCue') && isfield(data, 'Aligntime')
                            validLength = min(length(data.GalignCue), length(data.Aligntime));
                            masterData(i).Cue_GCaMP = data.GalignCue(1:validLength)';
                            masterData(i).Cue_GCaMP_time = data.Aligntime(1:validLength)';
                        else
                            error('Missing required fields');
                        end
                    % [Other metrics remain the same]
                end
            catch ME
                warning('Metric %s not found for mouse %s: %s', metric, mouseName, ME.message);
                masterData(i).(metric) = NaN;
                masterData(i).([metric '_time']) = NaN;
            end
        
    end
    
    % Calculate summary statistics
    summaryStats(i).mouseName = mouseName;
    for j = 1:length(p.Results.metrics)
        metric = p.Results.metrics{j};
        if isfield(masterData(i), metric) && ~all(isnan(masterData(i).(metric)))
            vals = masterData(i).(metric);
            timeVec = masterData(i).([metric '_time']);
            
            % Ensure vals is a vector
            if ~isvector(vals)
                vals = vals(:);
            end
            
            summaryStats(i).([metric '_mean']) = mean(vals, 'omitnan');
            summaryStats(i).([metric '_max']) = max(vals, [], 'omitnan');
            
            % Safe AUC calculation with proper time vector if available
            try
                if ~all(isnan(timeVec)) && length(timeVec) == length(vals)
                    summaryStats(i).([metric '_auc']) = trapz(timeVec, vals);
                else
                    summaryStats(i).([metric '_auc']) = trapz(vals);
                end
            catch
                summaryStats(i).([metric '_auc']) = NaN;
            end
        else
            summaryStats(i).([metric '_mean']) = NaN;
            summaryStats(i).([metric '_max']) = NaN;
            summaryStats(i).([metric '_auc']) = NaN;
        end
    end
end

% Create Excel file
masterFile = fullfile(outputPath, 'MasterSummary.xlsx');
if exist(masterFile, 'file')
    delete(masterFile);
end

% Write aligned event data (each metric gets its own sheet)
for j = 1:length(p.Results.metrics)
    metric = p.Results.metrics{j};
    timeMetric = [metric '_time'];
    
    lengths = arrayfun(@(x) length(x.(metric)), masterData, 'UniformOutput', true);
    maxLength = max(lengths);
    
    % Prepare data matrix
    dataMat = NaN(maxLength, length(masterData));
    timeMat = NaN(maxLength, 1);
    mouseNames = {};
    hasValidTime = false;
    
    % Find first mouse with valid time vector for this metric
    for i = 1:length(masterData)
        if isfield(masterData(i), timeMetric) && ~all(isnan(masterData(i).(timeMetric)))
            timeVec = masterData(i).(timeMetric);
            if length(timeVec) >= maxLength
                timeMat(1:maxLength) = timeVec(1:maxLength);
                hasValidTime = true;
                break;
            end
        end
    end
    
    % Populate data matrix
    for i = 1:length(masterData)
        if isfield(masterData(i), metric) && ~all(isnan(masterData(i).(metric)))
            vals = masterData(i).(metric);
            dataMat(1:length(vals), i) = vals;
        end
        mouseNames{i} = masterData(i).mouseName;
    end
    
    % Create table
    metricTable = array2table(dataMat, 'VariableNames', mouseNames);
    
    % Add time column if available
    if hasValidTime
        metricTable = addvars(metricTable, timeMat, 'Before', 1, 'NewVariableNames', {'Time'});
    end
    
    writetable(metricTable, masterFile, 'Sheet', metric);
end

% Summary statistics
statsTable = struct2table(summaryStats);
writetable(statsTable, masterFile, 'Sheet', 'SummaryStats');

% Metadata
metadata = table(...
    {datestr(now)}, {p.Results.metrics}, length(masterData), ...
    'VariableNames', {'CreationDate', 'MetricsIncluded', 'NumMice'});
writetable(metadata, masterFile, 'Sheet', 'Metadata');

fprintf('Successfully created master summary at: %s\n', masterFile);
end