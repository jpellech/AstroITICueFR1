function GeneratePlots(name, time, GRABDA_dFF, GCamp_dFF, SlowGCamp, SlowGRABDA, data, ISOS, ...
    Reward, Cue, RewHE, Aligntime, GalignD, DalignD, Aligntime1, GalignCue, DalignCue, ...
    GalignReward, DalignReward, GalignHE, DalignHE, GalignRewHE, DalignRewHE)

    % Define colors
    red = [0.8500, 0.3250, 0.0980];
    green = [0.4660, 0.6740, 0.1880];
    cyan = [0.3010, 0.7450, 0.9330];
    
    %% 1. Main Time Series Plot
    figure;
    hold on;
    plot(time, GRABDA_dFF-GRABDA_dFF(1), 'color', red, 'LineWidth', 2);
    plot(time, GCamp_dFF-GCamp_dFF(1), 'color', green, 'LineWidth', 2);
    plot(time, SlowGCamp, 'g', 'LineWidth', 2);
    plot(time, SlowGRABDA, 'r', 'LineWidth', 2);
    plot(time, data.streams.(ISOS).data-data.streams.(ISOS).data(1), 'color', cyan, 'LineWidth', 1);
    
    % Add event markers
    if ~isempty(Reward)
        xline(Reward, 'k');
    end
    if ~isempty(Cue)
        xline(Cue, 'r');
    end
    if ~isempty(RewHE)
        xline(RewHE, 'b');
    end
    
    title([name ' - Signals'], 'fontsize', 16);
    xlabel('Seconds', 'fontsize', 14);
    ylabel('\DeltaF/F (%)', 'fontsize', 14);
    legend({'GRABDA', 'GCaMP', 'Slow GCaMP', 'Slow GRABDA', 'Isosbestic'});
    set(gcf, 'Position', get(0, 'ScreenSize'));
    saveas(gcf, [name '.jpeg'], 'jpeg');
    close;

    %% 2. DA-Aligned Plot
    if ~isempty(GalignD) && ~isempty(DalignD) && ~isempty(Aligntime)
        % Verify sizes match
        if size(GalignD,2) ~= length(Aligntime) || size(DalignD,2) ~= length(Aligntime)
            fprintf('Size mismatch in DA alignment:\n');
            fprintf('GalignD cols: %d, DalignD cols: %d, Aligntime: %d\n',...
                    size(GalignD,2), size(DalignD,2), length(Aligntime));
            
            % Force matching sizes
            minSize = min([size(GalignD,2), size(DalignD,2), length(Aligntime)]);
            Aligntime = Aligntime(1:minSize);
            GalignD = GalignD(:,1:minSize);
            DalignD = DalignD(:,1:minSize);
        end
        
        figure;
        hold on;
        
        % Calculate means and SEM
        meanG = mean(GalignD, 1);
        semG = std(GalignD, [], 1)/sqrt(size(GalignD,1));
        meanD = mean(DalignD, 1);
        semD = std(DalignD, [], 1)/sqrt(size(DalignD,1));
        
        % Plot with verification
        if length(Aligntime) == length(meanG)
            plot(Aligntime, meanG, 'g', 'LineWidth', 2);
            plot(Aligntime, meanG-semG, 'g:', 'LineWidth', 1);
            plot(Aligntime, meanG+semG, 'g:', 'LineWidth', 1);
        else
            warning('Size mismatch in GCaMP plot');
        end
        
        if length(Aligntime) == length(meanD)
            plot(Aligntime, meanD, 'r', 'LineWidth', 2);
            plot(Aligntime, meanD-semD, 'r:', 'LineWidth', 1);
            plot(Aligntime, meanD+semD, 'r:', 'LineWidth', 1);
        else
            warning('Size mismatch in GRABDA plot');
        end
        
        xline(0, 'k--');
        xlabel('Time from DA Peak (s)');
        ylabel('\DeltaF/F (%)');
        title('DA and GCaMP Aligned to DA Peaks');
        legend({'GCaMP', '', 'GRABDA', ''});
        set(gcf, 'Position', get(0, 'ScreenSize'));
        saveas(gcf, [name '_DAaligned.jpeg'], 'jpeg');
        close;
    else
        fprintf('Skipping DA-aligned plot - insufficient data\n');
    end

    %% 3. Cue + Reward Plot
    plotCueReward = ~isempty(GalignCue) || ~isempty(GalignReward);
    if plotCueReward && ~isempty(Aligntime1)
        figure('Position', [100, 100, 1200, 800]);
        
        % Cue plots
        if ~isempty(GalignCue)
            % Force size matching
            minSize = min([size(GalignCue,2), size(DalignCue,2), length(Aligntime1)]);
            Aligntime1_adj = Aligntime1(1:minSize);
            GalignCue_adj = GalignCue(:,1:minSize);
            DalignCue_adj = DalignCue(:,1:minSize);
            
            fprintf('Cue Alignment: Time points %d, Data cols %d\n',...
                    length(Aligntime1_adj), size(GalignCue_adj,2));
            
            % Mean plot
            subplot(3,2,1);
            hold on;
            meanG = mean(GalignCue_adj, 1);
            semG = std(GalignCue_adj, [], 1)/sqrt(size(GalignCue_adj,1));
            
            if length(Aligntime1_adj) == length(meanG)
                plot(Aligntime1_adj, meanG, 'g', 'LineWidth', 2);
                plot(Aligntime1_adj, meanG-semG, 'g:', 'LineWidth', 1);
                plot(Aligntime1_adj, meanG+semG, 'g:', 'LineWidth', 1);
            end
            
            meanD = mean(DalignCue_adj, 1);
            semD = std(DalignCue_adj, [], 1)/sqrt(size(DalignCue_adj,1));
            
            if length(Aligntime1_adj) == length(meanD)
                plot(Aligntime1_adj, meanD, 'r', 'LineWidth', 2);
                plot(Aligntime1_adj, meanD-semD, 'r:', 'LineWidth', 1);
                plot(Aligntime1_adj, meanD+semD, 'r:', 'LineWidth', 1);
            end
            
            xline(0, 'k--');
            title('Cue Response');
            ylabel('\DeltaF/F (%)');
            legend({'GCaMP', '', 'GRABDA', ''});
            
            % Heatmaps
            subplot(3,2,3);
            imagesc(Aligntime1_adj, 1:size(GalignCue_adj,1), GalignCue_adj);
            set(gca, 'YDir', 'normal');
            title('GCaMP at Cue');
            xlabel('Time (s)');
            ylabel('Trial #');
            colorbar;
            
            subplot(3,2,5);
            imagesc(Aligntime1_adj, 1:size(DalignCue_adj,1), DalignCue_adj);
            set(gca, 'YDir', 'normal');
            title('GRABDA at Cue');
            xlabel('Time (s)');
            ylabel('Trial #');
            colorbar;
        end
        
        % Reward plots (same structure as Cue plots)
        if ~isempty(GalignReward)
            minSize = min([size(GalignReward,2), size(DalignReward,2), length(Aligntime1)]);
            Aligntime1_adj = Aligntime1(1:minSize);
            GalignReward_adj = GalignReward(:,1:minSize);
            DalignReward_adj = DalignReward(:,1:minSize);
            
            fprintf('Reward Alignment: Time points %d, Data cols %d\n',...
                    length(Aligntime1_adj), size(GalignReward_adj,2));
            
            subplot(3,2,2);
            hold on;
            meanG = mean(GalignReward_adj, 1);
            semG = std(GalignReward_adj, [], 1)/sqrt(size(GalignReward_adj,1));
            
            if length(Aligntime1_adj) == length(meanG)
                plot(Aligntime1_adj, meanG, 'g', 'LineWidth', 2);
                plot(Aligntime1_adj, meanG-semG, 'g:', 'LineWidth', 1);
                plot(Aligntime1_adj, meanG+semG, 'g:', 'LineWidth', 1);
            end
            
            meanD = mean(DalignReward_adj, 1);
            semD = std(DalignReward_adj, [], 1)/sqrt(size(DalignReward_adj,1));
            
            if length(Aligntime1_adj) == length(meanD)
                plot(Aligntime1_adj, meanD, 'r', 'LineWidth', 2);
                plot(Aligntime1_adj, meanD-semD, 'r:', 'LineWidth', 1);
                plot(Aligntime1_adj, meanD+semD, 'r:', 'LineWidth', 1);
            end
            
            xline(0, 'k--');
            title('Reward Response');
            ylabel('\DeltaF/F (%)');
            legend({'GCaMP', '', 'GRABDA', ''});
            
            subplot(3,2,4);
            imagesc(Aligntime1_adj, 1:size(GalignReward_adj,1), GalignReward_adj);
            set(gca, 'YDir', 'normal');
            title('GCaMP at Reward');
            xlabel('Time (s)');
            ylabel('Trial #');
            colorbar;
            
            subplot(3,2,6);
            imagesc(Aligntime1_adj, 1:size(DalignReward_adj,1), DalignReward_adj);
            set(gca, 'YDir', 'normal');
            title('GRABDA at Reward');
            xlabel('Time (s)');
            ylabel('Trial #');
            colorbar;
        end
        
        saveas(gcf, [name '_CueReward.jpeg'], 'jpeg');
        close;
    else
        fprintf('Skipping Cue+Reward plot - insufficient data\n');
    end

    %% 4. HE Response Plot
    plotHE = ~isempty(GalignHE) || ~isempty(GalignRewHE);
    if plotHE && ~isempty(Aligntime)
        figure('Position', [100, 100, 1000, 800]);
        
        % All HE
        if ~isempty(GalignHE)
            minSize = min([size(GalignHE,2), size(DalignHE,2), length(Aligntime)]);
            Aligntime_adj = Aligntime(1:minSize);
            GalignHE_adj = GalignHE(:,1:minSize);
            DalignHE_adj = DalignHE(:,1:minSize);
            
            fprintf('HE Alignment: Time points %d, Data cols %d\n',...
                    length(Aligntime_adj), size(GalignHE_adj,2));
            
            subplot(2,2,1);
            hold on;
            meanG = mean(GalignHE_adj, 1);
            semG = std(GalignHE_adj, [], 1)/sqrt(size(GalignHE_adj,1));
            
            if length(Aligntime_adj) == length(meanG)
                plot(Aligntime_adj, meanG, 'g', 'LineWidth', 2);
                plot(Aligntime_adj, meanG-semG, 'g:', 'LineWidth', 1);
                plot(Aligntime_adj, meanG+semG, 'g:', 'LineWidth', 1);
            end
            
            meanD = mean(DalignHE_adj, 1);
            semD = std(DalignHE_adj, [], 1)/sqrt(size(DalignHE_adj,1));
            
            if length(Aligntime_adj) == length(meanD)
                plot(Aligntime_adj, meanD, 'r', 'LineWidth', 2);
                plot(Aligntime_adj, meanD-semD, 'r:', 'LineWidth', 1);
                plot(Aligntime_adj, meanD+semD, 'r:', 'LineWidth', 1);
            end
            
            xline(0, 'k--');
            title('All HE Responses');
            ylabel('\DeltaF/F (%)');
            legend({'GCaMP', '', 'GRABDA', ''});
        end
        
        % Rewarded HE
        if ~isempty(GalignRewHE)
            minSize = min([size(GalignRewHE,2), size(DalignRewHE,2), length(Aligntime)]);
            Aligntime_adj = Aligntime(1:minSize);
            GalignRewHE_adj = GalignRewHE(:,1:minSize);
            DalignRewHE_adj = DalignRewHE(:,1:minSize);
            
            fprintf('RewHE Alignment: Time points %d, Data cols %d\n',...
                    length(Aligntime_adj), size(GalignRewHE_adj,2));
            
            subplot(2,2,2);
            hold on;
            meanG = mean(GalignRewHE_adj, 1);
            semG = std(GalignRewHE_adj, [], 1)/sqrt(size(GalignRewHE_adj,1));
            
            if length(Aligntime_adj) == length(meanG)
                plot(Aligntime_adj, meanG, 'g', 'LineWidth', 2);
                plot(Aligntime_adj, meanG-semG, 'g:', 'LineWidth', 1);
                plot(Aligntime_adj, meanG+semG, 'g:', 'LineWidth', 1);
            end
            
            meanD = mean(DalignRewHE_adj, 1);
            semD = std(DalignRewHE_adj, [], 1)/sqrt(size(DalignRewHE_adj,1));
            
            if length(Aligntime_adj) == length(meanD)
                plot(Aligntime_adj, meanD, 'r', 'LineWidth', 2);
                plot(Aligntime_adj, meanD-semD, 'r:', 'LineWidth', 1);
                plot(Aligntime_adj, meanD+semD, 'r:', 'LineWidth', 1);
            end
            
            xline(0, 'k--');
            title('Rewarded HE Responses');
            ylabel('\DeltaF/F (%)');
            legend({'GCaMP', '', 'GRABDA', ''});
            
            % Heatmaps
            subplot(2,2,3);
            imagesc(Aligntime_adj, 1:size(GalignRewHE_adj,1), GalignRewHE_adj);
            set(gca, 'YDir', 'normal');
            title('GCaMP at RewHE');
            xlabel('Time (s)');
            ylabel('Trial #');
            colorbar;
            
            subplot(2,2,4);
            imagesc(Aligntime_adj, 1:size(DalignRewHE_adj,1), DalignRewHE_adj);
            set(gca, 'YDir', 'normal');
            title('GRABDA at RewHE');
            xlabel('Time (s)');
            ylabel('Trial #');
            colorbar;
        end
        
        saveas(gcf, [name '_HEresponses.jpeg'], 'jpeg');
        close;
    else
        fprintf('Skipping HE plot - insufficient data\n');
    end
end