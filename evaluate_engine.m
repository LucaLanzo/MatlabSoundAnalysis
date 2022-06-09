clc
close all
clear
format long
set(0,'DefaultFigureWindowStyle','docked')


% 1 for verbose output
debug = 0;

% a for abnormal engines, n for normal engines
prefix = 'n';

% choose file number 0..9
fileNumber = 0;
    

% get path to audio file
fileName = ['wav/' prefix '_0000000' num2str(fileNumber) '.wav'];

% load audio
[data, rate] = audioread(fileName);


% evaluate engine
engineWorking = evaluateGoodOrBadEngine(data, rate, debug);
if (engineWorking == 1)
    disp("The engine is working")
else
    disp("The engine is faulty")
end





function engineWorking = evaluateGoodOrBadEngine(data, rate, debug)
    % get first channel
    data = data(:, 1);
    
    % find distances and peak locations
    if (debug == 0) 
        
        [distances, peakLocations] = findDistancesAndPeakLocations(data);
        peakAmps = findPeakAmplitude(data, peakLocations);
        engineWorking = engineIsWorking(peakAmps, distances, debug);
    
    else
        
        [distances, peakLocations, numPeaks] = findDistancesAndPeakLocations(data);
        peakAmps = findPeakAmplitude(data, peakLocations);

        fprintf("\nDistances: \n")
        disp(distances)

        fprintf("\nPeak Locations: \n")
        disp(peakLocations)
        
        fprintf("\nNumber of peaks found: %i\n", numPeaks)

        fprintf("\nPeak Amps found: \n")
        disp(peakAmps)

        engineWorking = engineIsWorking(peakAmps, distances, debug);

        plotOscillogram(data, rate)
    end
end


function engineWorking = engineIsWorking(peakAmps, distances, debug)
    engineWorking = 1;
    
    if (debug == 0)
        if (mean(peakAmps) < 0.1)
            % if mean of found clicks is under < 0.1 engine is faulty
            engineWorking = 0;
        end
    
        if (numel(find(distances >= 18000)) > 0 || numel(find(distances <= 17000)) > 0)
            engineWorking = 0;
        end

    else 
        fprintf("\nMean of peakAmps:")
        disp(mean(peakAmps))
        if (mean(peakAmps) < 0.1)
            disp("Mean peak UNDER 0.1.")
            engineWorking = 0;
        else
            disp("Mean peak OVER 0.1.")
        end

        if (numel(find(distances >= 18000)) > 0 || numel(find(distances <= 17000)) > 0)
            disp("Distances between peaks not equal.")
            engineWorking = 0;
        else
            disp("Distances between peaks equal.")
        end 
    
    end
   
end


function peakAmps = findPeakAmplitude(data, peakLocations)
    peakAmps = [];
    for j = 1 : size(peakLocations)
        peak = max(data(peakLocations(j, 1):peakLocations(j, 2)));
        peakAmps = [ peakAmps ; peak ];
    end 
end


function [distances, peakLocations, numPeaks] = findDistancesAndPeakLocations(data)
    % find the indices where the data is above the threshold of 0.1 amps
    indexPeaks = find(data > 0.1);
    
    firstIndex = 0;
    peakStart = 0;
    peakEnd = 0;
    numPeaks = 0;
    distances = [];
    peakLocations = [];

    % if no peaks have been found, return from the function
    if (numel(indexPeaks) == 0)
        fprintf("No clicks over 0.1 Amplitude found!\nChecking for clicks over 0.05 ...\n");
        indexPeaks = find(data > 0.05);
    end 

    % now iterate through the indices to find the number of peaks
    % and distance between peaks
    for j = 1 : numel(indexPeaks)
        currentIndex = indexPeaks(j);
        
        % we skip over peaks which are located close to each other because
        % they represent the same "click" noise
        % Only if the distance is greater than 100, the next "click" has 
        % been reached
        
        if ((currentIndex - firstIndex) > 100)
         
            if (firstIndex ~= 0)
                % Save peak start and end locations
                peakStart = firstIndex;
                peakEnd = indexPeaks(j-1);
                peakLocations = [ peakLocations; [peakStart, peakEnd] ];

                % the full memory of the distance array is allocated each peak
                % but there are only <10 peaks, so it is fine
                distances = [ distances; currentIndex-firstIndex ];
            end

            firstIndex = currentIndex;
            numPeaks = numPeaks + 1;
        end

        
    end

    % add the last peak too
    peakLocations = [ peakLocations; [firstIndex, indexPeaks(end)]];
end


function plotOscillogram(data, rate)

    N = length(data);                       	% signal length
    to = (0 : N-1) / rate;                      % time vector


    figure(1)
    plot(to, data, 'r')
    xlim([0 max(to)])
    ylim([-1.1*max(abs(data)) 1.1*max(abs(data))])
    grid on
    set(gca, 'FontName', 'Times New Roman', 'FontSize', 14)
    xlabel('Time s')
    ylabel('Amplitude V')
    title('Oscillogram of the signal')
end