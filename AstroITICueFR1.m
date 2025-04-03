% Main analysis script for photometry data
close all; clear all; clc;

% TDT Matlab SDK import 
possible_tdt_paths = {
    'C:\TDT\TDTMatlabSDK', 
    '/usr/local/tdt/TDTMatlabSDK',
    '~/Documents/TDT/TDTMatlabSDK', 
    '/Applications/TDT/TDTMatlabSDK',
    'C:\Program Files\TDT\TDTMatlabSDK' 
};

% Try each path until successful
tdt_sdk_found = false;
for i = 1:length(possible_tdt_paths)
    current_path = possible_tdt_paths{i};
    
    % Expand ~ to full home directory path (Mac/Linux)
    if contains(current_path, '~')
        current_path = fullfile(getenv('HOME'), current_path(2:end));
    end
    
    if exist(current_path, 'dir')
        addpath(genpath(current_path));
        fprintf('TDT SDK found at: %s\n', current_path);
        tdt_sdk_found = true;
        break;
    end
end

if ~tdt_sdk_found
    error(['TDT SDK not found! Tried:\n' strjoin(possible_tdt_paths, '\n')]);
end

if ~exist('TDTbin2mat', 'file')
    error('TDTbin2mat not found despite SDK path being added. Check SDK installation.');
end

[CDPATH, name, ext] = fileparts(cd);
DATAPATH = fullfile(CDPATH, name);

d = dir(DATAPATH);
folderList = {};

for i = 1:numel(d)
    if d(i).isdir && ~strcmp(d(i).name, '.') && ~strcmp(d(i).name, '..')
        if ~startsWith(d(i).name, '.')
            folderList = [folderList, d(i).name];
        end
    end
end

myStruct = struct();
myStruct.Name = folderList;

for j = 1:length(folderList)
    name = folderList(j);
    name = char(name);
    
    BLOCKPATH = fullfile(DATAPATH, name);
    data = TDTbin2mat(BLOCKPATH);
    
    % Define signal names
    GRABDA = 'x560B';
    GCAMP = 'x465A';
    ISOS = 'x405A';
    
    % Process time vector
    time = (1:length(data.streams.(GCAMP).data))/data.streams.(GCAMP).fs;
    t = 5;
    ind = find(time > t, 1);
    time = time(ind:end);
    data.streams.(GCAMP).data = data.streams.(GCAMP).data(ind:end);
    data.streams.(ISOS).data = data.streams.(ISOS).data(ind:end);
    data.streams.(GRABDA).data = data.streams.(GRABDA).data(ind:end);
    
    if strcmp(name, 'ABC5R-250314-170453')
        t2 = 1550;
        ind = find(time > t2, 1);
        time = time(1:ind);
        data.streams.(GCAMP).data = data.streams.(GCAMP).data(1:ind);
        data.streams.(ISOS).data = data.streams.(ISOS).data(1:ind);
        data.streams.(GRABDA).data = data.streams.(GRABDA).data(1:ind);
    end
    
    % Calculate dFF and filter signals
    fs = data.streams.(GCAMP).fs;
    [GCamp_dFF, GRABDA_dFF, SlowGCamp, SlowGRABDA, FlatGCamp, FlatGRABDA] = ...
        dFF_Calculation(data, GCAMP, GRABDA, ISOS, fs);
    
    % Align data to events
    [GalignD, DalignD, GalignG, DalignG, GalignHE, DalignHE, GalignRewHE, DalignRewHE, ...
        GalignReward, DalignReward, GalignCue, DalignCue, dlocs, dprom, dwidth, glocs, gprom, gwidth, ...
        Reward, Cue, RewHE, Aligntime, Aligntime1] = ...
        EventAlignment(data, time, GCamp_dFF, GRABDA_dFF, fs);
    
    % Generate plots
    GeneratePlots(name, time, GRABDA_dFF, GCamp_dFF, SlowGCamp, SlowGRABDA, data, ISOS, ...
        Reward, Cue, RewHE, Aligntime, GalignD, DalignD, Aligntime1, GalignCue, DalignCue, ...
        GalignReward, DalignReward, GalignHE, DalignHE, GalignRewHE, DalignRewHE);
    
    % Save data and export to Excel
    save([name, '.mat']);
    
    exportPhotometryDataToExcel(...
        time.', ...
        data.streams.(GCAMP).fs, ...
        GCamp_dFF.', ...
        GRABDA_dFF.', ...
        dlocs, ...
        dprom, ...
        dwidth, ...
        glocs, ...
        gprom, ...
        gwidth, ...
        GalignCue, ...
        DalignCue, ...
        GalignReward, ...
        DalignReward, ...
        GalignHE, ...
        DalignHE, ...
        GalignRewHE, ...
        DalignRewHE, ...
        name, ...
        DATAPATH);
        
    clearvars -except d folderList ext CDPATH DATAPATH myStruct j
end