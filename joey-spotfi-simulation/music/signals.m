function ss = signals(theta)
    s = rand(1,30);
    c = 3.0 * 10^8;%光速
    fc = 2.422*10^9;
    d = 0.06;
    theta = (theta/180)*pi;
    
    tau1 = sin(theta)*d/c;%时间差
    s1 = s*exp(-1i*2*pi*fc*tau1);
    
    tau2 = sin(theta)*2*d/c;
    s2 = s*exp(-1i*2*pi*fc*tau2);
    
    tau3 = sin(theta)*3*d/c;
    s3 = s*exp(-1i*2*pi*fc*tau3);
    
    ss = [s1;s2;s3];
    
    R = ss*ss';
    [eigenvectors, eigenvalue_matrix] = eig(R);
    I = eye(3);
    theta = -90:1:90;
    Pmusic = zeros(length(theta),1);
    for ii = 1:length(theta)
        steering_vector = comput_steering_vector(theta(ii), fc, d);
        PP = steering_vector'*(I-eigenvectors*eigenvectors')*steering_vector;
        Pmusic(ii) =abs(1/PP);
    end
    Pmusic = 10*log10(Pmusic);
    plot(theta, Pmusic');
end

function steering_vector = comput_steering_vector(theta, freq, ant_dist)
    steering_vector = zeros(3,1);
    for ii = 1:3
        steering_vector(ii) = phi_aoa_phase(theta, freq, (ii-1)*ant_dist);
    end
end

function angle_phase = phi_aoa_phase(theta, frequency, d)
    % Speed of light (in m/s)
    c = 3.0 * 10^8;
    % Convert to radians
    theta = theta / 180 * pi;
    angle_phase = exp(-1i * 2 * pi * d * sin(theta) * (frequency / c));
end