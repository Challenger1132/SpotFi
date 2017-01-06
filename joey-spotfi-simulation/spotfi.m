%% Runs the SpotFi test over the passed in data files which each contain CSI data for many packets
% csi_trace        -- the csi_trace for several packets
% frequency        -- the base frequency of the signal
% sub_freq_delta   -- the difference between adjacent subcarriers
% antenna_distance -- the distance between each antenna in the array, measured in meters
% data_name        -- a label for the data which is included in certain outputs

%Write by Joey
%aoa_packet_data:每个数据包的aoa，即从每个数据包的music频谱得到的波峰对应的aoa
%tof_packet_data:每个数据包的tof，即从每个数据包的music频谱得到的波峰对应的tof
%output_top_aoaos:前5个最有可能是直达路径的AOA
function [aoa_packet_data,tof_packet_data,output_top_aoas] = spotfi(csi_trace, frequency, sub_freq_delta, antenna_distance, data_name)
    if nargin < 5
        data_name = ' - ';
    end
    
    num_packets = length(csi_trace);
    % Loop over packets, estimate AoA and ToF from the CSI data for each packet
    aoa_packet_data = cell(num_packets, 1);
    tof_packet_data = cell(num_packets, 1);
    packet_one_phase_matrix = 0;

    % Do computations for packet one so the packet loop can be parallelized
    % Get CSI for current packet
    csi_entry = csi_trace{1};
    csi = get_scaled_csi(csi_entry);
    % Only consider measurements for transmitting on one antenna
    csi = csi(1, :, :);
    % Remove the single element dimension
    csi = squeeze(csi);

    % Sanitize ToFs with Algorithm 1
    packet_one_phase_matrix = unwrap(angle(csi), pi, 2);
    sanitized_csi = spotfi_algorithm_1(csi, sub_freq_delta);
    % Acquire smoothed CSI matrix
    smoothed_sanitized_csi = smooth_csi(sanitized_csi);
    % Run SpotFi's AoA-ToF MUSIC algorithm on the smoothed and sanitized CSI matrix
    [aoa_packet_data{1}, tof_packet_data{1}] = aoa_tof_music(...
            smoothed_sanitized_csi, antenna_distance, frequency, sub_freq_delta, data_name);
    fprintf('1\n');

    %% TODO: REMEMBER THIS IS A PARFOR LOOP, AND YOU CHANGED THE ABOVE CODE AND THE BEGIN INDEX
    parfor (packet_index = 2:num_packets, 4)
        % Get CSI for current packet
        csi_entry = csi_trace{packet_index};
        csi = get_scaled_csi(csi_entry);
        % Only consider measurements for transmitting on one antenna
        csi = csi(1, :, :);
        % Remove the single element dimension
        csi = squeeze(csi);

        % Sanitize ToFs with Algorithm 1
        sanitized_csi = spotfi_algorithm_1(csi, sub_freq_delta, packet_one_phase_matrix);

        % Acquire smoothed CSI matrix
        smoothed_sanitized_csi = smooth_csi(sanitized_csi);
        % Run SpotFi's AoA-ToF MUSIC algorithm on the smoothed and sanitized CSI matrix
        [aoa_packet_data{packet_index}, tof_packet_data{packet_index}] = aoa_tof_music(...
                smoothed_sanitized_csi, antenna_distance, frequency, sub_freq_delta, data_name);
        fprintf('%d\n',packet_index);
    end

    % Find the number of elements that will be in the full_measurement_matrix
    % The value must be computed since each AoA may have a different number of ToF peaks
    full_measurement_matrix_size = 0;
    % Packet Loop
    fprintf('packet loop\n');
    for packet_index = 1:num_packets
        tof_matrix = tof_packet_data{packet_index};
        aoa_matrix = aoa_packet_data{packet_index};
        % AoA Loop
        for j = 1:size(aoa_matrix, 1)
            % ToF Loop
            for k = 1:size(tof_matrix(j, :), 2)
                % Break once padding is hit
                if tof_matrix(j, k) < 0
                    break
                end
                full_measurement_matrix_size = full_measurement_matrix_size + 1;
            end
        end
    end

    % Construct the full measurement matrix
    full_measurement_matrix = zeros(full_measurement_matrix_size, 2);
    full_measurement_matrix_index = 1;
    % Packet Loop
    for packet_index = 1:num_packets
        tof_matrix = tof_packet_data{packet_index};
        aoa_matrix = aoa_packet_data{packet_index};
        % AoA Loop
        for j = 1:size(aoa_matrix, 1)
            % ToF Loop
            for k = 1:size(tof_matrix(j, :), 2)
                % Break once padding is hit
                if tof_matrix(j, k) < 0
                    break
                end
                full_measurement_matrix(full_measurement_matrix_index, 1) = aoa_matrix(j, 1);
                full_measurement_matrix(full_measurement_matrix_index, 2) = tof_matrix(j, k);
                full_measurement_matrix_index = full_measurement_matrix_index + 1;
            end
        end
    end

    % Normalize AoA & ToF
    fprintf('Normalize AoA &ToF\n');
    aoa_max = max(abs(full_measurement_matrix(:, 1)));
    tof_max = max(abs(full_measurement_matrix(:, 2)));
    full_measurement_matrix(:, 1) = full_measurement_matrix(:, 1) / aoa_max;
    full_measurement_matrix(:, 2) = full_measurement_matrix(:, 2) / tof_max;

    % Cluster AoA and ToF for each packet
    % Worked Pretty Well
    fprintf('Clustering\n');
    [cluster_indices,clusters] = aoa_tof_cluster(full_measurement_matrix);

    % Delete outliers from each cluster
    fprintf('delete outliers\n');
    for ii = 1:size(clusters, 1)
        % Delete clusters that are < 5% of the size of the number of packets
        if size(clusters{ii}, 1) < (0.05 * num_packets)
            clusters{ii} = [];
            cluster_indices{ii} = [];
            continue;
        end
        alpha = 0.05;
        [~, outlier_indices, ~] = deleteoutliers(clusters{ii}(:, 1), alpha);
        cluster_indices{ii}(outlier_indices(:), :) = [];
        clusters{ii}(outlier_indices(:), :) = [];

        alpha = 0.05;
        [~, outlier_indices, ~] = deleteoutliers(clusters{ii}(:, 2), alpha);
        cluster_indices{ii}(outlier_indices(:), :) = [];
        clusters{ii}(outlier_indices(:), :) = [];
    end

    %% TODO: Tune parameters
    %% TODO: Tuning parameters using SVM results
    % Good base: 5, 10000, 75000, 0 (in order)
    % Likelihood parameters
    fprintf('likelihood\n');
    weight_num_cluster_points = 0.0001 * 10^-3;
    weight_aoa_variance = -0.7498 * 10^-3;
    weight_tof_variance = 0.0441 * 10^-3;
    weight_tof_mean = -0.0474 * 10^-3;
    constant_offset = -1;
    %{
    weight_num_cluster_points = 5;
    weight_aoa_variance = 50000; % prev = 10000; prev = 100000;
    weight_tof_variance = 100000;
    weight_tof_mean = 1000; % prev = 50; % prev = 10;
    %}
    %constant_offset = 300;
    % Compute likelihoods
    likelihood = zeros(length(clusters), 1);
    cluster_aoa = zeros(length(clusters), 1);
    max_likelihood_index = -1;
    top_likelihood_indices = [-1; -1; -1; -1; -1;];
    for ii = 1:length(clusters)
        % Ignore clusters of size 1
        if size(clusters{ii}, 1) == 0
            continue
        end
        % Initialize variables
        num_cluster_points = size(clusters{ii}, 1);
        aoa_mean = 0;
        tof_mean = 0;
        aoa_variance = 0;
        tof_variance = 0;
        % Compute Means
        for jj = 1:num_cluster_points
            aoa_mean = aoa_mean + clusters{ii}(jj, 1);
            tof_mean = tof_mean + clusters{ii}(jj, 2);
        end
        aoa_mean = aoa_mean / num_cluster_points;
        tof_mean = tof_mean / num_cluster_points;
        % Compute Variances
        for jj = 1:num_cluster_points
            aoa_variance = aoa_variance + (clusters{ii}(jj, 1) - aoa_mean)^2;
            tof_variance = tof_variance + (clusters{ii}(jj, 2) - tof_mean)^2;
        end
        aoa_variance = aoa_variance / (num_cluster_points - 1);
        tof_variance = tof_variance / (num_cluster_points - 1);
        % Compute Likelihood
        %% TODO: Trying result from SVM
        %{
        exp_body = weight_num_cluster_points * num_cluster_points ...
                - weight_aoa_variance * aoa_variance ...
                - weight_tof_variance * tof_variance ...
                - weight_tof_mean * tof_mean ...
                - constant_offset;
        %}
        exp_body = weight_num_cluster_points * num_cluster_points ...
                + weight_aoa_variance * aoa_variance ...
                + weight_tof_variance * tof_variance ...
                + weight_tof_mean * tof_mean ...
                + constant_offset;
        likelihood(ii, 1) = exp_body;%exp(exp_body);
        % Compute Cluster Average AoA
        for jj = 1:size(clusters{ii}, 1)
            cluster_aoa(ii, 1) = cluster_aoa(ii, 1) + aoa_max * clusters{ii}(jj, 1);
        end
        cluster_aoa(ii, 1) = cluster_aoa(ii, 1) / size(clusters{ii}, 1);
        % Check for maximum likelihood
        if max_likelihood_index == -1 ...
                || likelihood(ii, 1) > likelihood(max_likelihood_index, 1)
            max_likelihood_index = ii;
        end
        % Record the top maximum likelihoods
        for jj = 1:size(top_likelihood_indices, 1)
            % Replace empty slot
            if top_likelihood_indices(jj, 1) == -1
                top_likelihood_indices(jj, 1) = ii;
                break;
            % Add somewhere in the list
            elseif likelihood(ii, 1) > likelihood(top_likelihood_indices(jj, 1), 1)
                % Shift indices down
                for kk = size(top_likelihood_indices, 1):-1:(jj + 1)
                    top_likelihood_indices(kk, 1) = top_likelihood_indices(kk - 1, 1);
                end
                top_likelihood_indices(jj, 1) = ii;
                break;
            % Add an extra item to the list because the likelihoods are all equal...
            elseif likelihood(ii, 1) == likelihood(top_likelihood_indices(jj, 1), 1) ...
                    && jj == size(top_likelihood_indices, 1)
                top_likelihood_indices(jj + 1, 1) = ii;
                break;
            end
        end
    end
    % Select AoA
    fprintf('select AoA\n');
    max_likelihood_average_aoa = cluster_aoa(max_likelihood_index, 1);
    % Profit
    temp = find(top_likelihood_indices~=-1);
    top_likelihood_indices = top_likelihood_indices(temp);
    output_top_aoas = cluster_aoa(top_likelihood_indices);
end