function doa=get_pic_doa2(url,fig)
csi_trace = read_bf_file(url);
[csi_size,tmp]=size(csi_trace);
set(figure(fig),'WindowStyle','docked');

for ii=200:200

csi_entry = csi_trace{ii};
csi_s=size(csi_entry);
    if(csi_s(1)==0)
        csi_size=ii;
        break;
    end
csi = csi_entry.csi;
if csi==0
    break;
end

cir = cir_via_ifft(csi,fig);
cir=cir';
M=3;
fc = 2400e6; 
lambda = physconst('LightSpeed')/fc;
hura = phased.ULA('NumElements',M,'ElementSpacing',lambda/2);

hbeam = phased.BeamscanEstimator('SensorArray',hura,'OperatingFrequency',fc,'ScanAngles',-90:90,'DOAOutputPort',true,'NumSignals',1);
[~,sigang] = step(hbeam,cir);
plotSpectrum(hbeam);

hroot = phased.RootMUSICEstimator('SensorArray',hura,'OperatingFrequency',fc,'NumSignalsSource','Property','NumSignals',1,'ForwardBackwardAveraging',true);
doa = step(hroot,cir);

end
