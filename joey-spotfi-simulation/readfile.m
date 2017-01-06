function csi_trace = readfile(filepath)
%	path('../linux-80211n-csitool-supplementary/matlab', path);
	temp = read_bf_file(filepath);
    flag=cellfun(@isempty,temp);
    k=1;
    for i=1:size(temp,1)
        if flag(i,1)==0
            csi_trace(k,1)=temp(i,1);
            k=k+1;
        end
    end
end
