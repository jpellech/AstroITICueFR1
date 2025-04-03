#### AstroITICueFR1.m ####
    1. Place the script in a directory containing your TDT data folder
    2. Ensure the TDT MATLAB SDK is installed at C:\TDT\TDTMatlabSDK
    3. Run the script in Matlab

    # What the script does
    This script processes photometry fiber photometry data:
        - DA is Dopamine
        - AP is action potential
        - GCAMP (x465A): Calcium indicator (GCaMP) (is this the red or green?)
        - GRABDA (x560B): Dopamine sensor (GRABDA) (is this the red or green?)
        - ISOS (x405A): Isosbestic control channel (blue?)

    ### Processing steps
    1. Loads TDT data from each folder
    2. Performs dF/F normalization using isosbestic control
    3. Filters the signals (lowpass?)
    4. Detects behavioral events (cues, rewards, head entries)
    5. Alligns signals to different events: dopamine peaks, calcium peaks, behavioral events
    6. Generates multiple plots showing
        - Raw signal traces
        - Event-aligned averages
        - Heatmap of individual trials
    7. Saves figures as JPEGS and processed data as MAT files

    # Key variables
    - GCAMP, GRABDA, ISOS: Channel names for the different signals
    - data: Structure containing all the TDT data
    - GCamp_dFF, GRABDA_dFF: Normalized signals
    - Reward, Cue, HE: Timestamps of behavioral events
    - Galign*, Dalign*: Matrices of aligned signals for different events

    # Outputs
    For each data folder, the script saves
    1. JPEG images of the analyses of the raw signal traces, peak detection plots, event-aligned averages, heatmaps
    2. MAT files containing processed data
    3. A Excel sheet of time series data, peak detection results, GCaMP peaks, any event-aligned averages.

#### Helper functions ####
    # dFF_Calculation.m 
        prepares photometry data for analysis:
        - Calculates ΔF/F normalized signals using isosbestic control
        - removes slow drifts
        - applies lowpass filtering

    # EventAlignment.m 
        Aligns photometry signals to behavioral events (cues, rewards, head entries) and neural peaks
        - creates time-locked matrices for analysis and visualization

    # GeneratePlots.m 
        Generates raw traces, event-aligned averages, heatmaps plots for all experimental conditions and neural signals:
            1. Main Time Series Plot
             - Raw ΔF/F traces for GCaMP (green), GRABDA (red), and isosbestic control (cyan) with event markers (rewards, cues, head entries) overlaid on the timeline.
            2. DA-Aligned Plot
             - GCaMP and dopamine (GRABDA) signals time-locked to detected DA peaks, showing mean ± SEM responses centered at peak time (0s).
            3. Cue + Reward Plot
             - Composite figure with mean/SEM traces (top) and heatmaps (bottom) for cue/reward-aligned GCaMP and GRABDA responses across trials.
            4. HE Response Plot
             - Head entry (HE) and rewarded HE-aligned activity, comparing mean ΔF/F responses (top) and trial-by-trial heatmaps (bottom) for both signals.

        All plots include ΔF/F (%) on the y-axis and time (seconds) on the x-axis. Event markers (vertical lines) indicate behavioral timestamps (cues = red, rewards = black, rewarded HEs = blue).

    Heatmaps visualize trial-to-trial variability in z-scored or raw ΔF/F.
    # exportPhotometryDataToExcel.m Script 
        Exports fiber photometry data to Excel:
        - time series data
        - peak detection results
        - GCaMP peaks
        - any event-aligned averages
        Note that this script dynamically downsamples data to fit Excel sheets. It's best to use the outputted .mat file for detailed analysis.