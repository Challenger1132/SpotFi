%theta：信号入射角
function data = data_productor(theta)
    s = randn(1,1);%源信号
    d = 0.06;%天线距离
    fc = 2400 * 10^6;%中心频率
    s1 = signal_productor(s,theta,fc,d);%第一根天线信号
    s2 = signal_productor(s,theta,fc,2*d);%第二份天线信号
    s3 = signal_productor(s,theta,fc,3*d);%第三根天线信号
    data = [s1;s2;s3];
end