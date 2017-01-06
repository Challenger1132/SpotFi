function plot_Pmusic(filepath)
    antenna_distance = 0.06;
    frequency = 5.825 * 10^9;
    sub_freq_delta = (20 * 10^6) /30;
    
    csi_trace = readfile(filepath);
    chose_one = floor(length(csi_trace)/2);
    csi_entry = csi_trace{chose_one};
    csi = get_scaled_csi(csi_entry);
    csi = csi(1, :, :);
    csi = squeeze(csi);
    %没有sanitize tof的部分
    smoothed_sanitized_csi = smooth_csi(csi);
    eigenvectors = noise_space_eigenvectors(smoothed_sanitized_csi);
    theta = -90:1:90; 
    tau = 0:(100.0 * 10^-9):(3000 * 10^-9);
    Pmusic = music_spectrum(theta,tau,frequency, sub_freq_delta, antenna_distance,eigenvectors);
    
   
    [x,y] = meshgrid(theta, tau);
    subplot(2,1,1);
    mesh(x,y,Pmusic');
    xlabel('AoA');
    ylabel('ToF');
    xlim([-90 90]);
    colorbar;
    hold on;
    subplot(2,1,2);
    mesh(x,y,Pmusic');
    view(2);
    xlabel('AoA');
    ylabel('ToF');
    xlim([-90 90]);
    colorbar;
    hold on;
end