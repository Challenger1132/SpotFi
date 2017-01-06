%Write by Joey
%aoa_packet_data:每个数据包的aoa，即从每个数据包的music频谱得到的波峰对应的aoa
%tof_packet_data:每个数据包的tof，即从每个数据包的music频谱得到的波峰对应的tof
%output_top_aoaos:前5个最有可能是直达路径的AOA
function [aoa_packet_data,tof_packet_data,output_top_aoas] = run_spotfi(filepath)
    antenna_distance = 0.06;
    frequency = 5.825 * 10^9;
    sub_freq_delta = (20 * 10^6) /30;
    
    csi_trace = readfile(filepath);
    num_packets = floor(length(csi_trace)/1);
    sampled_csi_trace = csi_sampling(csi_trace, num_packets, 1, length(csi_trace));
    [aoa_packet_data,tof_packet_data,output_top_aoas] = spotfi(sampled_csi_trace, frequency, sub_freq_delta, antenna_distance);
end