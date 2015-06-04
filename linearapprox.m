clear all
close all
clc

more off

addpath('matpower4.1');
define_constants;

% Load case_ieee123, inspired by the IEEE 123 test feeder, with 
% - symmetric lines
% - balanced loads modeled as PQ buses
% - balanced shunt capacitors
% - switched in their normal position
% - ideal voltage regulators

% The modified testbed is distributed as case_ieee123.

mpc = loadcase('case_ieee123');

% Define useful constants

PCCindex = find(mpc.bus(:,BUS_TYPE)==3);
n = length(mpc.bus(:,BUS_TYPE));
PQnodes = setdiff(1:n,PCCindex);

% Build Laplacian L (neglecting shunt admittances)

nbr = size(mpc.branch,1);
nbu = size(mpc.bus,1);
L = zeros(nbu,nbu);

for br = 1:nbr
	br_F_BUS = mpc.branch(br,F_BUS);
	br_T_BUS = mpc.branch(br,T_BUS);
	br_BR_R = mpc.branch(br,BR_R);
	br_BR_X = mpc.branch(br,BR_X);
	br_Y = 1 / (br_BR_R + 1j * br_BR_X);

	L(br_F_BUS, br_T_BUS) = br_Y;
	L(br_T_BUS, br_F_BUS) = br_Y;
	L(br_F_BUS, br_F_BUS) = L(br_F_BUS, br_F_BUS) - br_Y;
	L(br_T_BUS, br_T_BUS) = L(br_T_BUS, br_T_BUS) - br_Y;
end

X = inv(L(PQnodes,PQnodes));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% linear-polar approximation

p = mpc.bus(:,PD) + mpc.bus(:,GS);
q = mpc.bus(:,QD) - mpc.bus(:,BS);
p(PCCindex) = -sum(p);
q(PCCindex) = -sum(q);

e0 = zeros(n,1); e0(PCCindex) = 1;
z = zeros(n,1);

LL = [real(L) -imag(L); imag(L) real(L)];

x = [LL; e0' z';z' e0']\[p;-q;1;0];

u_appr = x(PQnodes) .* exp(1j * x(n+PQnodes));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

results = runpf(mpc, mpoption('VERBOSE', 0, 'OUT_ALL',0));
u_true = results.bus(PQnodes,VM) .* exp(1j * results.bus(PQnodes,VA)/180*pi);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

figure(1);

disp('FIGURE 1: Voltage magnitude');

plot(1:(n-1), abs(u_true), 'ko ', 1:(n-1), abs(u_appr), 'k. ');
title('Voltage magnitude')
xlim([1 n-1]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

figure(2)

disp('FIGURE 2: Voltage angles');

plot(	1:(n-1), angle(u_true)/pi*180, 'ko ',		...
		1:(n-1), angle(u_appr)/pi*180, 'k. ');
title('Voltage angle')
xlim([1 n-1]);

