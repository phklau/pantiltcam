%   Skript zum Start der Regelung
%
%   Prof. Dr.-Ing. Tobias Weiser
%   HS Kempten
%   21.05.2022
%
clc; clear all;
close all; objects = imaqfind %find video input objects in memory
delete(objects) %delete a video input object from memory
MOUNTING = 0;
Framework_Regelung(MOUNTING);