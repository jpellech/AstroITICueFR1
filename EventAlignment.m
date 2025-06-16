function [GalignD, DalignD, GalignG, DalignG, GalignHE, DalignHE, GalignRewHE, DalignRewHE, ...
          GalignReward, DalignReward, GalignCue, DalignCue, dlocs, dprom, dwidth, glocs, gprom, gwidth, ...
          Reward, Cue, RewHE, Aligntime, Aligntime1, GalignOmission, DalignOmission, GalignPostOmissionHE, DalignPostOmissionHE] = ...
          EventAlignment(data, time, GCamp_dFF, GRABDA_dFF, fs)

    % Initialize all output variables (add new ones for omission)
    GalignD = []; DalignD = []; 
    GalignG = []; DalignG = [];
    GalignHE = []; DalignHE = [];
    GalignRewHE = []; DalignRewHE = [];
    GalignReward = []; DalignReward = [];
    GalignCue = []; DalignCue = [];
    dlocs = []; dprom = []; dwidth = [];
    glocs = []; gprom = []; gwidth = [];
    Reward = []; Cue = []; RewHE = [];
    Aligntime = []; Aligntime1 = [];
    GalignOmission = []; DalignOmission = [];
    GalignPostOmissionHE = []; DalignPostOmissionHE = [];

    % Alignment parameters
    WindowinSec = 20;
    DA_thresh = 5;
    GCamp_thresh = 4;
    PreEvent = 10;
    PostEvent = 10;
    RewardPreEvent = 10;
    RewardPostEvent = 10;

    % Calculate the number of points for each alignment window
    nPointsShort = round(fs*(PreEvent+PostEvent));
    nPointsLong = round(fs*(RewardPreEvent+RewardPostEvent));
    
    % Create time vectors
    Aligntime = linspace(-PreEvent, PostEvent, nPointsShort+1);
    Aligntime1 = linspace(-RewardPreEvent, RewardPostEvent, nPointsLong+1);

    % List all possible epoch names that might contain our events
    possible_epochs = {'Tt_1', 'PrtB', 'PtB', 'Trial', 'Events'};
    event_epoc = '';
    
    % Check each possible epoch name
    for i = 1:length(possible_epochs)
        if isfield(data.epocs, possible_epochs{i}) && ...
           isfield(data.epocs.(possible_epochs{i}), 'data') && ...
           isfield(data.epocs.(possible_epochs{i}), 'onset')
            event_epoc = possible_epochs{i};
            break;
        end
    end
    
    if isempty(event_epoc)
        warning('No valid event epochs found in data. Checked for: %s', strjoin(possible_epochs, ', '));
        return;
    end
    
    fprintf('Using event epoch: %s\n', event_epoc);
    
    % Extract event codes with more robust checking
    epoc_data = data.epocs.(event_epoc);
    Reward = []; Cue = []; HE = []; Omission = [];
    
    % Check for different possible event code schemes
    if any(ismember(epoc_data.data, [4 2 8 16])) % Standard codes including omission (16)
        Reward = epoc_data.onset(epoc_data.data == 4);
        Cue = epoc_data.onset(epoc_data.data == 2);
        HE = epoc_data.onset(epoc_data.data == 8);
        Omission = epoc_data.onset(epoc_data.data == 16 | epoc_data.data == 0);
        fprintf('Found %d omission trials (codes 0 and 16)\n', length(Omission));
    else
        warning('Unrecognized event codes in epoch %s. Data codes found: %s', ...
                event_epoc, mat2str(unique(epoc_data.data)));
    end

    % Process HE events to remove duplicates
    if ~isempty(HE)
        temp = HE(1);
        for i = 2:length(HE)
            if HE(i) - HE(i-1) > 1 % Only keep if >1s apart
                temp = [temp HE(i)]; %#ok<AGROW>
            end
        end
        HE = temp';
    end

    % Filter events by time bounds (first/last 10s)
    if ~isempty(time)
        validTime = time(end)-10;
        HE(HE > validTime) = [];
        validTime = time(1)+10;
        HE(HE < validTime) = [];
    end

    % Find rewarded HE (HE that occur between rewards)
    if ~isempty(Reward) && ~isempty(HE)
        RewHEidx = [];
        for i = 1:length(Reward)-1
            temp = find(HE > Reward(i) & HE < Reward(i+1), 1);
            RewHEidx(i) = ifelse(isempty(temp), NaN, temp);
        end
        temp = find(HE > Reward(end), 1);
        RewHEidx(end+1) = ifelse(isempty(temp), NaN, temp);
        
        RewHEidx(isnan(RewHEidx)) = [];
        RewHE = HE(RewHEidx);
        HE(RewHEidx) = [];
    end
    
    % NEW: Find post-omission HE (HE that occur after omission trials)
    if ~isempty(Omission) && ~isempty(HE)
        PostOmissionHE = [];
        omission_times = Omission; % Use whatever we identified as omissions
        
        for i = 1:length(omission_times)
            % Find first HE after omission (within 10 seconds)
            subsequent_he = HE(HE > omission_times(i) & HE < omission_times(i)+10);
            if ~isempty(subsequent_he)
                PostOmissionHE = [PostOmissionHE, subsequent_he(1)]; %#ok<AGROW>
            end
        end
        
        % Create alignment matrices for omissions and post-omission HEs
        if ~isempty(omission_times)
            GalignOmission = zeros(length(omission_times), nPointsLong+1);
            DalignOmission = zeros(length(omission_times), nPointsLong+1);
            
            for i = 1:length(omission_times)
                ST = find(abs(time-omission_times(i)) == min(abs(time-omission_times(i))));
                halfWin = floor(nPointsLong/2);
                startIdx = max(1, ST-halfWin);
                endIdx = min(length(GCamp_dFF), ST+halfWin);
                
                if (endIdx-startIdx) < nPointsLong
                    if startIdx == 1
                        endIdx = startIdx + nPointsLong;
                    else
                        startIdx = endIdx - nPointsLong;
                    end
                end
                
                GalignOmission(i,:) = GCamp_dFF(startIdx:endIdx);
                DalignOmission(i,:) = GRABDA_dFF(startIdx:endIdx);
            end
        end
        
        if ~isempty(PostOmissionHE)
            GalignPostOmissionHE = zeros(length(PostOmissionHE), nPointsShort+1);
            DalignPostOmissionHE = zeros(length(PostOmissionHE), nPointsShort+1);
            
            for i = 1:length(PostOmissionHE)
                ST = find(abs(time-PostOmissionHE(i)) == min(abs(time-PostOmissionHE(i))));
                halfWin = floor(nPointsShort/2);
                startIdx = max(1, ST-halfWin);
                endIdx = min(length(GCamp_dFF), ST+halfWin);
                
                if (endIdx-startIdx) < nPointsShort
                    if startIdx == 1
                        endIdx = startIdx + nPointsShort;
                    else
                        startIdx = endIdx - nPointsShort;
                    end
                end
                
                GalignPostOmissionHE(i,:) = GCamp_dFF(startIdx:endIdx);
                DalignPostOmissionHE(i,:) = GRABDA_dFF(startIdx:endIdx);
            end
        end
    else
        fprintf('No omission trials or head entries found to analyze\n');
    end

    % DA peak alignment
    if ~isempty(GRABDA_dFF)
        [~, dlocs, dwidth, dprom] = findpeaks(GRABDA_dFF, 'MinPeakProminence', DA_thresh);
        
        halfWin = floor(nPointsShort/2); % Exact half-window
        validPeaks = (dlocs > halfWin) & (dlocs < length(GRABDA_dFF)-halfWin);
        dlocs = dlocs(validPeaks);
        dprom = dprom(validPeaks);
        dwidth = dwidth(validPeaks);
        
        if ~isempty(dlocs)
            GalignD = zeros(length(dlocs), nPointsShort+1);
            DalignD = zeros(length(dlocs), nPointsShort+1);
            
            for i = 1:length(dlocs)
                center = dlocs(i);
                startIdx = center-halfWin;
                endIdx = center+halfWin;
                
                % Force exact window size
                if (endIdx-startIdx) ~= nPointsShort
                    endIdx = startIdx + nPointsShort;
                end
                
                GalignD(i,:) = GCamp_dFF(startIdx:endIdx);
                DalignD(i,:) = GRABDA_dFF(startIdx:endIdx);
            end
        end
    end

    % GCAMP peak alignment 
    if ~isempty(GCamp_dFF)
        [~, glocs, gwidth, gprom] = findpeaks(GCamp_dFF, 'MinPeakProminence', GCamp_thresh);
        
        halfWin = floor(nPointsShort/2);
        validPeaks = (glocs > halfWin) & (glocs < length(GCamp_dFF)-halfWin);
        glocs = glocs(validPeaks);
        gprom = gprom(validPeaks);
        gwidth = gwidth(validPeaks);
        
        if ~isempty(glocs)
            GalignG = zeros(length(glocs), nPointsShort+1);
            DalignG = zeros(length(glocs), nPointsShort+1);
            
            for i = 1:length(glocs)
                center = glocs(i);
                startIdx = center-halfWin;
                endIdx = center+halfWin;
                
                if (endIdx-startIdx) ~= nPointsShort
                    endIdx = startIdx + nPointsShort;
                end
                
                GalignG(i,:) = GCamp_dFF(startIdx:endIdx);
                DalignG(i,:) = GRABDA_dFF(startIdx:endIdx);
            end
        end
    end

    % HE event alignment 
    if ~isempty(HE)
        GalignHE = zeros(length(HE), nPointsShort+1);
        DalignHE = zeros(length(HE), nPointsShort+1);
        
        for i = 1:length(HE)
            ST = find(abs(time-HE(i)) == min(abs(time-HE(i))));
            halfWin = floor(nPointsShort/2);
            startIdx = max(1, ST-halfWin);
            endIdx = min(length(GCamp_dFF), ST+halfWin);
            
            % Handle edge cases
            if (endIdx-startIdx) < nPointsShort
                if startIdx == 1
                    endIdx = startIdx + nPointsShort;
                else
                    startIdx = endIdx - nPointsShort;
                end
            end
            
            GalignHE(i,:) = GCamp_dFF(startIdx:endIdx);
            DalignHE(i,:) = GRABDA_dFF(startIdx:endIdx);
        end
    end

    % rewarded HE alignment
    if ~isempty(RewHE)
        GalignRewHE = zeros(length(RewHE), nPointsShort+1);
        DalignRewHE = zeros(length(RewHE), nPointsShort+1);
        
        for i = 1:length(RewHE)
            ST = find(abs(time-RewHE(i)) == min(abs(time-RewHE(i))));
            halfWin = floor(nPointsShort/2);
            startIdx = max(1, ST-halfWin);
            endIdx = min(length(GCamp_dFF), ST+halfWin);
            
            if (endIdx-startIdx) < nPointsShort
                if startIdx == 1
                    endIdx = startIdx + nPointsShort;
                else
                    startIdx = endIdx - nPointsShort;
                end
            end
            
            GalignRewHE(i,:) = GCamp_dFF(startIdx:endIdx);
            DalignRewHE(i,:) = GRABDA_dFF(startIdx:endIdx);
        end
    end

    % reward alignment
    if ~isempty(Reward)
        Reward(Reward < 10) = []; % Remove rewards in first 10s
        GalignReward = zeros(length(Reward), nPointsLong+1);
        DalignReward = zeros(length(Reward), nPointsLong+1);
        
        for i = 1:length(Reward)
            ST = find(abs(time-Reward(i)) == min(abs(time-Reward(i))));
            halfWin = floor(nPointsLong/2);
            startIdx = max(1, ST-halfWin);
            endIdx = min(length(GCamp_dFF), ST+halfWin);
            
            if (endIdx-startIdx) < nPointsLong
                if startIdx == 1
                    endIdx = startIdx + nPointsLong;
                else
                    startIdx = endIdx - nPointsLong;
                end
            end
            
            GalignReward(i,:) = GCamp_dFF(startIdx:endIdx);
            DalignReward(i,:) = GRABDA_dFF(startIdx:endIdx);
        end
    end

    % cue alignment
    if ~isempty(Cue)
        GalignCue = zeros(length(Cue), nPointsLong+1);
        DalignCue = zeros(length(Cue), nPointsLong+1);
        
        for i = 1:length(Cue)
            ST = find(abs(time-Cue(i)) == min(abs(time-Cue(i))));
            halfWin = floor(nPointsLong/2);
            startIdx = max(1, ST-halfWin);
            endIdx = min(length(GCamp_dFF), ST+halfWin);
            
            if (endIdx-startIdx) < nPointsLong
                if startIdx == 1
                    endIdx = startIdx + nPointsLong;
                else
                    startIdx = endIdx - nPointsLong;
                end
            end
            
            GalignCue(i,:) = GCamp_dFF(startIdx:endIdx);
            DalignCue(i,:) = GRABDA_dFF(startIdx:endIdx);
        end
    end
    
    % NEW: Omission trial alignment
    if ~isempty(Omission)
        GalignOmission = zeros(length(Omission), nPointsLong+1);
        DalignOmission = zeros(length(Omission), nPointsLong+1);
        
        for i = 1:length(Omission)
            ST = find(abs(time-Omission(i)) == min(abs(time-Omission(i))));
            halfWin = floor(nPointsLong/2);
            startIdx = max(1, ST-halfWin);
            endIdx = min(length(GCamp_dFF), ST+halfWin);
            
            if (endIdx-startIdx) < nPointsLong
                if startIdx == 1
                    endIdx = startIdx + nPointsLong;
                else
                    startIdx = endIdx - nPointsLong;
                end
            end
            
            GalignOmission(i,:) = GCamp_dFF(startIdx:endIdx);
            DalignOmission(i,:) = GRABDA_dFF(startIdx:endIdx);
        end
    end
    
    % NEW: Post-omission HE alignment
    if exist('PostOmissionHE', 'var') && ~isempty(PostOmissionHE)
        GalignPostOmissionHE = zeros(length(PostOmissionHE), nPointsShort+1);
        DalignPostOmissionHE = zeros(length(PostOmissionHE), nPointsShort+1);
        
        for i = 1:length(PostOmissionHE)
            ST = find(abs(time-PostOmissionHE(i)) == min(abs(time-PostOmissionHE(i))));
            halfWin = floor(nPointsShort/2);
            startIdx = max(1, ST-halfWin);
            endIdx = min(length(GCamp_dFF), ST+halfWin);
            
            if (endIdx-startIdx) < nPointsShort
                if startIdx == 1
                    endIdx = startIdx + nPointsShort;
                else
                    startIdx = endIdx - nPointsShort;
                end
            end
            
            GalignPostOmissionHE(i,:) = GCamp_dFF(startIdx:endIdx);
            DalignPostOmissionHE(i,:) = GRABDA_dFF(startIdx:endIdx);
        end
    end
    
    % Debug output
    fprintf('EventAlignment Complete:\n');
    fprintf('Using event epoc: %s\n', event_epoc);
    fprintf('Time vectors: %d (short), %d (long)\n', length(Aligntime), length(Aligntime1));
    fprintf('DA peaks: %d, GCamp peaks: %d\n', length(dlocs), length(glocs));
    fprintf('HE: %d, RewHE: %d, Reward: %d, Cue: %d, Omission: %d, PostOmissionHE: %d\n', ...
            size(GalignHE,1), size(GalignRewHE,1), size(GalignReward,1), ...
            size(GalignCue,1), size(GalignOmission,1), size(GalignPostOmissionHE,1));
end

% Helper function
function val = ifelse(condition, trueval, falseval)
    if condition
        val = trueval;
    else
        val = falseval;
    end
end