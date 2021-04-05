clear all
close all
clc

x1 = load('e1.dat'); % load the ECG signal from the file
fs = 200;              % Sampling rate 200Hz
N = length (x1);       % Signal length
t = [0:N-1]/fs;        % time index

%CANCELLATION DC DRIFT AND NORMALIZATION
x1 = x1 - mean (x1 );    % cancel DC components
x1 = x1/ max( abs(x1 )); % normalize to one

subplot(1,2,1)
plot(t,x1)
xlabel('second');ylabel('Volts');title('Input ECG Signal (ECG1.DAT)')

%First, in order to attenuate noise, the signal passes through a
%digital bandpass filter composed of cascaded high-pass and lowpass filters.
%The bandpass filter, formed using lowpass and highpass filters, reduces noise in the ECG
%signal. Noise such as muscle noise, 60 Hz interference, and baseline drift are removed by bandpass
%filtering.

%LOW PASS FILTERING
% LPF (1-z^-6)^2/(1-z^-1)^2
b=[1 0 0 0 0 0 -2 0 0 0 0 0 1];
a=[1 -2 1];
h_LP=filter(b,a,[1 zeros(1,12)]); % transfer function of LPF
x2 = conv (x1 ,h_LP);
x2 = x2/ max( abs(x2 )); % normalize , for convenience .

%HIGH PASS FILTERING
% HPF = Allpass-(Lowpass) = z^-16-[(1-z^-32)/(1-z^-1)]
b = [-1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 32 -32 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1];
a = [1 -1];
h_HP=filter(b,a,[1 zeros(1,32)]); % impulse response of HPF
x3 = conv (x2 ,h_HP);
x3 = x3/ max( abs(x3 ));

%DERIVATIVE FILTER
% Make impulse response
h = [-1 -2 0 2 1]/8;
% Apply filter
x4 = conv (x3 ,h);
x4 = x4 (2+[1: N]);
x4 = x4/ max( abs(x4 ));
%SQUARING
x5 = x4 .^2;
x5 = x5/ max( abs(x5 ));

%MOVING WINDOW INTEGRATION
% Make impulse response
h = ones (1 ,31)/31;
% Apply filter
x6 = conv (x5 ,h);
x6 = x6 (15+[1: N]);
x6 = x6/ max( abs(x6 ));
subplot(1,2,2)
plot([0:length(x6)-1]/fs,x6)
xlabel('second');ylabel('Volts');title(' ECG Signal After Applying Pan Tomkins Algorithm')

%Finding the R in QRS
y=[0:length(x6)-1]/fs;
[pks,locs]=findpeaks(x6,'MinPeakDistance',150);
[pmks,ilocs]=findpeaks(-x6,'MinPeakDistance',100);
hold on
figure(2);
subplot(1,2,1);
plot([0:length(x6)-1]/fs,x6,y(locs),pks,'o','MarkerFaceColor','r','MarkerSize',10);
title('Plotting The R for Heart Rate Calculation');
subplot(1,2,2);
plot([0:length(x6)-1]/fs,x6,y(ilocs),pmks,'o','MarkerFaceColor','g','MarkerSize',10);
title('Plotting the Q and S for Calculation of QRS Width');
%Calculating Heart Rate
%Heart Rate= (fs*60)/y;
nobh=length(pks);
tl=length(x6)/fs;
hr=(nobh*60)/tl;
disp('Heart Rate ');
fprintf('%d\n',round(hr))

%Calculating QRS Width
QrsWidth=mean(diff(ilocs));

disp('QRS Width in MiliSeconds');
fprintf('%d\n',round(QrsWidth))

