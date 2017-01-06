%s：源信号
%theta：角度
%fc：中心频率
%d：天线之间的距离
%s1：输出信号
function s1 = signal_productor(s, theta, fc, d)

    scale = 0.01;%控制噪声
    c = 3.0 * 10^8;%光速
    sub_freq_delta = (20 * 10^6)/30;%相邻子载波之间的频率差
    theta = (theta/180)*pi;
    tau = sin(theta)*d/c;%时间差
%     s1 = s*exp(-i*fc*tau);
    s1 = zeros(1,30);
    for ii = 1:30
        sub_freq = 2*pi* (fc + (ii-1)*sub_freq_delta);%子载波的频率
        s1(1,ii) = s*exp(-i*sub_freq*tau)+scale*(rand(1,1)+rand(1,1)*i);
    end
end