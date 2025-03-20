%% This code is used to process the Low Rate Data
% GEL - EPFL - 2024
% Developed by Mohsen Talebkeikhah

%% cleanup first, set global parameters, and input initial values
clc
clear
close all

%% loading the low rate data (EC Probe + Pressure transducers + GDS pump + ISCO Pump)
% pressure in MPa and opening in micrometer
% opening measurement system
T_W_Data=xlsread('Opening_Measurement_Output.xlsx');

% pressure of ISCO pump and pressure transducers in the injection line
LowRateData=readtable('181030.csv');

Time=LowRateData.Time;
Time=Time-Time(1);

Upstream_P=LowRateData.LFmeasurement2; % pump pressure
Downstream_P1=LowRateData.LFmeasurement0; % pressure transducer after valve and out of the frame
Downstream_P2=LowRateData.LFmeasurement3; % pressure transducer close to the wellbore - inside frame
Downstream_P1=Downstream_P1-mean(Downstream_P1(1:5000)); % to remove the initial bias
Downstream_P2=Downstream_P2-mean(Downstream_P2(1:5000)); % to remove the initial bias

% pressure and volume of confinement stresses measured by GDS pump
GDS1P=LowRateData.Pump1Pressure;
GDS2P=LowRateData.Pump2Pressure;
GDS3P=LowRateData.Pump3Pressure;
GDS1V=LowRateData.Pump1Volume;
GDS2V=LowRateData.Pump2Volume;
GDS3V=LowRateData.Pump3Volume;

%% Remove time resonance in pressure data
matrix_P = [Time,Downstream_P2,Downstream_P1,Upstream_P];

sorted_matrix_P = sortrows(matrix_P, 1);

% Remove rows where the first column value is equal to the previous one
cleaned_matrix_P = sorted_matrix_P([true; diff(sorted_matrix_P(:,1)) ~= 0], :);

%% Smoothing
time_smth=cleaned_matrix_P(1:5:end,1);
Downstream_P2_smth=smooth(time_smth,cleaned_matrix_P(1:5:end,2),0.005);
Downstream_P1_smth=smooth(time_smth,cleaned_matrix_P(1:5:end,3),0.005);
Upstream_P_smth=smooth(time_smth,cleaned_matrix_P(1:5:end,4),0.005);

%% AE's counts
close all
AEdata=readtable('catalog-AE-count-M03-1.csv');

time_shift=-(3*60+27);

AEsTime=time_shift+AEdata.relative_time;
histogram(AEsTime,200)

%% Result plots
% close all

figure
plot(Time,Upstream_P)
hold on;
plot(Time,Downstream_P1)
plot(Time,Downstream_P2)
yline(7,'k--','\sigma = 7 MPa')
xlabel('time (s)')
ylabel('Pressure (MPa)')
grid on;
ylim([0 25])
legend('P_{upstream}','P_{downstream1}','P_{downstream2}')

figure
plot(Time,GDS1P/1000);
hold on;
plot(Time,GDS2P/1000);
plot(Time,GDS3P/1000);
xlabel('time (s)', 'FontSize', 16)
ylabel('Pressure (MPa)', 'FontSize', 16)
legend('GDS-1','GDS-2','GDS-3', 'FontSize', 16);
set(gca, 'FontSize', 16);

figure
plot(Time,GDS1V);
hold on;
plot(Time,GDS2V);
plot(Time,GDS3V);
xlabel('time (s)', 'FontSize', 16)
ylabel('Volume (ml)', 'FontSize', 16)
legend('GDS-1','GDS-2','GDS-3', 'FontSize', 16);
set(gca, 'FontSize', 16);

% Rate data (time+rate)
t1=581:0.5:610;
q1=5*ones(1,numel(t1));

t2=610:0.5:950;
q2=0.5*ones(1,numel(t2));

t3=950:0.5:1554.4;
q3=3*ones(1,numel(t3));

T_Q=[[t1' q1'];[t2' q2'];[t3' q3']];

%
figure
subplot(2,1,1)
plot(T_W_Data(:,1),T_W_Data(:,2),'LineWidth',1.5)
ylabel('w (\mum)', 'FontSize', 16)
set(gca, 'FontSize', 16);
ylim([0 300]);

subplot(2,1,2)
yyaxis right;
plot(T_Q(:,1),T_Q(:,2),'LineWidth',2)
ylabel('Q_{0} (ml/min)', 'FontSize', 16)
grid on;
ylim([0 6])
set(gca, 'FontSize', 16);

yyaxis left;
plot(time_smth,Upstream_P_smth,'b-','LineWidth',1.5)
hold on;
plot(time_smth,Downstream_P1_smth,'k-','LineWidth',1.5)
% plot(time_smth,Downstream_P2_smth,'k-')
yline(7,'k--','\sigma = 7 MPa', 'FontSize', 14)
xlabel('time (s)', 'FontSize', 16)
ylabel('Pressure (MPa)', 'FontSize', 16)
grid on;
set(gca, 'FontSize', 16);
xlim([0 2500])
legend('P_{upstream}','P_{downstream}')

figure
subplot(2,1,1)
plot(T_W_Data(:,1),T_W_Data(:,2),'k-','LineWidth',1.5)
ylabel('$$w\;(\mu m)$$','Interpreter','latex', 'FontSize', 16)
set(gca,'FontSize',16);
grid on;

subplot(2,1,2)
yyaxis right;
plot(T_Q(:,1),T_Q(:,2),'LineWidth',1.5)
ylabel('$$Q_{0}\;(ml/min)$$','Interpreter','latex', 'FontSize', 16)
grid on;
ylim([0 6])
set(gca, 'FontSize', 16);

yyaxis left;
plot(time_smth,Downstream_P2_smth,'-','LineWidth',1.5)
% yline(7,'k--','$$\sigma_{3}\;=\;7\;MPa$$','Interpreter','latex', 'FontSize', 16,'LineWidth',1.5)
xlabel('$$time\;(s)$$','Interpreter','latex', 'FontSize', 16)
ylabel('$$pressure\;(MPa)$$','Interpreter','latex', 'FontSize', 16)
grid on;
set(gca, 'FontSize', 16);
xlim([0 2500])
ylim([0 25])

figure
subplot(2,1,1)
plot(T_W_Data(:,1)-581,T_W_Data(:,2),'k-','LineWidth',1.5)
ylabel('$$w\;(\mu m)$$','Interpreter','latex', 'FontSize', 16)
set(gca,'FontSize',16);
xlim([0 2000])
grid on;

subplot(2,1,2)
yyaxis right;
plot(T_Q(:,1)-581,T_Q(:,2),'LineWidth',1.5)
ylabel('$$Q_{0}\;(ml/min)$$','Interpreter','latex', 'FontSize', 16)
grid on;
ylim([0 6])
set(gca, 'FontSize', 16);

yyaxis left;
plot(time_smth-581,Downstream_P2_smth,'-','LineWidth',1.5)
% yline(7,'k--','$$\sigma_{3}\;=\;7\;MPa$$','Interpreter','latex', 'FontSize', 16,'LineWidth',1.5)
% xlabel('$$time\;(s)$$','Interpreter','latex', 'FontSize', 16)
ylabel('$$pressure\;(MPa)$$','Interpreter','latex', 'FontSize', 16)
grid on;
set(gca, 'FontSize', 16);
xlim([0 2000])
ylim([0 25])

figure
subplot(2,1,1)
yyaxis left
plot(T_W_Data(:,1),T_W_Data(:,2),'LineWidth',1.5)
ylabel('$$w\;(\mu m)$$','Interpreter','latex', 'FontSize', 16)
ylim([0 300])
set(gca, 'FontSize', 16);
grid on;

yyaxis right;
histogram(AEsTime,300)
ylabel('$$AEs \; Count$$', 'Interpreter', 'latex', 'FontSize', 16)
set(gca, 'FontSize', 16);
xlim([0 2500])

subplot(2,1,2)
yyaxis right;
plot(T_Q(:,1),T_Q(:,2),'LineWidth',1.5)
ylabel('$$Q_{0}\;(ml/min)$$','Interpreter','latex', 'FontSize', 16)
grid on;
ylim([0 6])
set(gca, 'FontSize', 16);

yyaxis left;
plot(time_smth,Downstream_P2_smth,'k-','LineWidth',1.5)
yline(7,'k--','$$\sigma_{3}\;=\;7\;MPa$$','Interpreter','latex', 'FontSize', 16,'LineWidth',1.5)
xlabel('$$time\;(s)$$','Interpreter','latex', 'FontSize', 16)
ylabel('$$Pressure\;(MPa)$$','Interpreter','latex', 'FontSize', 16)
grid on;
set(gca, 'FontSize', 16);
xlim([0 2500])
ylim([0 25])

%% AEs, Time, Pressure, opening of each cycle's recession
% cycle 1
% (t=1556) -> (t=2035)
t_rec_begin=1556;
t_rec_end=2035;
Cy1_t_P_rec=[time_smth(time_smth<t_rec_end & time_smth>t_rec_begin),Downstream_P2_smth(time_smth<t_rec_end & time_smth>t_rec_begin)]; 
Cy1_t_w_rec=[T_W_Data(T_W_Data(:,1)<t_rec_end & T_W_Data(:,1)>t_rec_begin,1),T_W_Data(T_W_Data(:,1)<t_rec_end & T_W_Data(:,1)>t_rec_begin,2)];

%% Pressure Analyze & Sunset Solution
clc
close all

% 1st cycle
t_reccession = 981.9;
w_reccesion = Cy1_t_w_rec(1,2);

Outputs = ClosureAnalysis1(Cy1_t_P_rec,Cy1_t_w_rec,t_reccession,w_reccesion);

%% End