%   Skript zum Start der Regelung
%
%   Prof. Dr.-Ing. Tobias Weiser
%   HS Kempten
%   21.05.2022
clc; clear;
imaqreset;
MOUNTING = 0;
%Sprung_Aufzeichnung(MOUNTING,0.35,0.3,'pan')
Sprung_Aufzeichnung_Filter(MOUNTING, 0.35, 0.3, 'pan', 'none'); %Filter none lässt verschiedene Filter auch noch im Nachgang probieren!
%Framework_Regelung(MOUNTING);