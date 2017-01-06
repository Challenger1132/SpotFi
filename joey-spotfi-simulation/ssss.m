s=randn(1,30);%源信号
theta = 0;%角度
theta_pi = (theta/180)*pi;
d = 0.06;%天线距离
c = 3.0*10^8;%光速
fc = 2400 * 10^6;%频率
tau = cos(theta_pi)*d/c;%时间
s1 = s*exp(-i*fc*tau);%输出信号

