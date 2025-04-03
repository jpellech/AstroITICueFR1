function [GCamp_dFF, GRABDA_dFF, SlowGCamp, SlowGRABDA, FlatGCamp, FlatGRABDA] = ...
    dFF_Calculation(data, GCAMP, GRABDA, ISOS, fs)

    % Calculate dFF for GCaMP
    bls = polyfit(data.streams.(ISOS).data, data.streams.(GCAMP).data, 1);
    Y_fit_all = bls(1) .* data.streams.(ISOS).data + bls(2);
    Y_dF_all = data.streams.(GCAMP).data - Y_fit_all;
    GCamp_dFF = 100*(Y_dF_all)./Y_fit_all;
    
    % Calculate dFF for GRABDA
    bls = polyfit(data.streams.(ISOS).data, data.streams.(GRABDA).data, 1);
    Y_fit_all = bls(1) .* data.streams.(ISOS).data + bls(2);
    Y_dF_all = data.streams.(GRABDA).data - Y_fit_all;
    GRABDA_dFF = 100*(Y_dF_all)./Y_fit_all;
    
    % Remove slow changes
    SlowGCamp = smooth(GCamp_dFF, 10000)';
    SlowGRABDA = smooth(GRABDA_dFF, 10000)';
    FlatGCamp = GCamp_dFF - SlowGCamp;
    FlatGRABDA = GRABDA_dFF - SlowGRABDA;
    
    % Lowpass ilter signals
    cutoffFrequency = 2;
    order = 4;
    [b, a] = butter(order, cutoffFrequency / (fs / 2), 'low');
    
    GRABDA_dFF = double(GRABDA_dFF);
    GRABDA_dFF = filtfilt(b, a, GRABDA_dFF);
    
    GCamp_dFF = double(GCamp_dFF);
    GCamp_dFF = filtfilt(b, a, GCamp_dFF);
    
    % Debug output
    fprintf('dFF Calculation Debug:\n');
    fprintf('GCamp_dFF size: %dx%d\n', size(GCamp_dFF,1), size(GCamp_dFF,2));
    fprintf('GRABDA_dFF size: %dx%d\n', size(GRABDA_dFF,1), size(GRABDA_dFF,2));
end