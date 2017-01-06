%% Run MUSIC algorithm with SpotFi method including ToF and AoA
% x                -- the signal matrix
% antenna_distance -- the distance between the antennas in the linear array
% frequency        -- the frequency of the signal being localized
% sub_freq_delta   -- the difference between subcarrier frequencies
% data_name        -- the name of the data file being operated on, used for labeling figures
% Return:
% estimated_aoas   -- the angle of arrivals that gave peaks from running MUSIC, as a vector
% estimated_tofs   -- the time of flights that gave peaks on the estimated_aoas from running music.
%                         This is a matrix with dimensions [length(estimated_aoas, ), length(tau)].
%                         The columns are zero padded at the ends to handle different peak counts 
%                           across different AoAs.
%                         I.E. if there are three AoAs then there will be three rows in 
%                           estimated_tofs
function [estimated_aoas, estimated_tofs] = aoa_tof_music(x, ...
        antenna_distance, frequency, sub_freq_delta, data_name)
    if nargin == 4
        data_name = '-';
    end
    
    eigenvectors = noise_space_eigenvectors(x);
    % Peak search
    % Angle in degrees (converts to radians in phase calculations)
    %% TODO: Tuning theta too??
    theta = -90:1:90; 
    % time in milliseconds
    %% TODO: Tuning tau....
    %tau = 0:(1.0 * 10^-9):(50 * 10^-9);
    tau = 0:(1.0 * 10^-9):(100 * 10^-9);
    Pmusic = music_spectrum(theta,tau,frequency, sub_freq_delta, antenna_distance,eigenvectors);

    % Find AoA peaks
    [estimated_aoas, estimated_tofs] = find_music_peaks(Pmusic,theta,tau);
    
    %%
    [x,y] = meshgrid(theta, tau);
    figure(1);
    mesh(x,y,Pmusic');
    xlabel('AoA');
    ylabel('ToF');
    xlim([-90 90]);
    colorbar;

    figure(2);
    mesh(x,y,Pmusic');
    view(2);
    xlabel('AoA');
    ylabel('ToF');
    xlim([-90 90]);
    colorbar;
end   

