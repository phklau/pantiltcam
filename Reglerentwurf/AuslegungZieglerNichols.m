%Berechnungen der Reglerparameter anhand Methode 2 Ziegler Nichols

%Prozessparameter
K = 1.175;
T = 0.091;
DT = 0.3;
%T_t = DT/2; %Mindeste Totzeit, durch diskrete Abtastung
T_t = 2*DT; %Erfahrungswert aus Sprungantwort
%Prozess
P_s = tf([K], [T 1]);

%Reglerparameter
kp = (0.9/K)*(T/T_t)
ki = kp/(3.33*T_t)
%Regler
C_s = tf([kp ki],[1 0]);

%Übertragungsfunktion offener Regelkreis
F_0 = tf([K*kp K*ki], [T 1 0]);

%Führungsübertragungsfunktion
H_s = tf([K*kp K*ki], [T (1+K*kp) K*ki]);
%Polstellen der Führungsübertagungsfunktion
s_1 = (-(1+K*kp)+sqrt((1+K*kp)^2-4*T*K*ki))/(2*T)
s_2 = (-(1+K*kp)-sqrt((1+K*kp)^2-4*T*K*ki))/(2*T)

%Stabilitätsreserven für Robustheit gegenüber der Totzeit
step(H_s);
[Gm, Pm, ~, ~] = margin(F_0);

%Diskretisierung des Reglers
c2d(C_s, DT, 'tustin')




