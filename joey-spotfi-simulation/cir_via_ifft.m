function cir = cir_via_ifft(csi)
    [rows, cols] = size(csi);
    cir = zeros(rows, cols);
    for ii = 1:rows
        tmp = csi(ii,:);
        tmp = tmp(:);
        tmp = ifft(tmp);
        cir(ii,:) = tmp';
    end
end