%%

function sampled_csi = csi_sampling(csi_trace, n, alt_begin_index, alt_end_index)
    % Variable number of arguments handling
    if nargin < 3
        begin_index = 1;
        end_index = length(csi_trace);
    elseif nargin < 4
        begin_index = alt_begin_index;
        end_index = length(csi_trace);
    elseif nargin == 4
        begin_index = alt_begin_index;
        end_index = alt_end_index;
    end
    
    % Sampling
    sampling_interval = floor((end_index - begin_index + 1) / n);
    sampled_csi = cell(n, 1);
    jj = 1;
    for ii = begin_index:sampling_interval:end_index
        % Get CSI for current packet
        sampled_csi{jj} = csi_trace{ii};
        jj = jj + 1;
    end
end