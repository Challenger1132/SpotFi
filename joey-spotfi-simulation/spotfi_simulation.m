%使用N次的采样量,把它们的MUSIC谱相加，然后找峰值
%theta：角度
%N：采样量
function aoa = spotfi_simulation(theta,N)
    frequency = 2400 * 10^6;%中心频率
    sub_freq_delta = (20 * 10^6)/30;%相邻两个子载波之间的频率差
    antenna_distance = 0.06;%相邻天线距离
    
    theta_range = -90:1:90; 
    tau_range = 0:(1.0 * 10^-9):(100 * 10^-9);
    Pmusic = zeros(length(theta_range), length(tau_range));
    
    %循环生成N个信号，求所有信号的谱的和
    for jj = 1:N
        data = data_productor(theta);%生成信号
        smoothed_sanitized_csi = smooth_csi(data);%平滑
        eigenvectors = noise_space_eigenvectors(smoothed_sanitized_csi);%求噪声子空间
        Pmusic = Pmusic + music_spectrum(theta_range,tau_range,frequency, sub_freq_delta, antenna_distance,eigenvectors);%求AoA谱，循环叠加N个谱
    end
    
    [aoa, tof] = find_music_peaks(Pmusic,theta_range,tau_range);%找峰值
    
    %%
    [x,y] = meshgrid(theta_range, tau_range);
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
    
    
%     [aoa, tof] = aoa_tof_music(...
%                 smoothed_sanitized_csi, antenna_distance, frequency, sub_freq_delta, '-');
    
%     data = data_productor(theta);
%     smoothed_sanitized_csi = smooth_csi(data);
%     [aoa, tof] = aoa_tof_music(...
%                 smoothed_sanitized_csi, antenna_distance, frequency, sub_freq_delta, '-');
    
%     data1 = data_productor(30);
%     data2 = data + data1;
%     smoothed_sanitized_csi = smooth_csi(data2);
%     [aoa, tof] = aoa_tof_music(...
%                 smoothed_sanitized_csi, antenna_distance, frequency, sub_freq_delta, '-');
    
end