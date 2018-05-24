%% Bu, Puma_Simulation.m, �leri ve Ters Kinematik problemlerini 
% ��zme yetene�ine sahip bir Puma 762 manip�lat�r�n�n 3D Matlab 
% Kinematik modelinin sim�lasyonudur. Kod, Don Riley taraf�ndan
% puma3d.m'ye dayanmaktad�r ve Paschalis Pelitaris taraf�ndan 
% de�i�tirilmi� ve geli�tirilmi�tir.
%
% Ters ters kinematik problemi (pozisyon ve oryantasyon) i�in 
% daha eksiksiz bir ��z�m sa�lamak i�in fonksiyonlarda baz� de�i�iklikler
% yap�ld�. GUI baz� yeni �zellikler ile geli�tirilmi�tir. IK de�i�kenleri
% giri�i i�in bir 'Ters Kinematik' paneli, farkl� ��z�mleri g�r�nt�lemek 
% i�in Radyo D��meleri, bir 'D-H parametreleri' tablosu ve bir 'D�n���m matrisi'
% tablosu. 'Demo' butonu yeni '�izimler' ile 'Draw' olarak de�i�tirildi.
%
% puma3d.m kodu, https://www.mathworks.com/matlabcentral/fileexchange/14
% 932-3d-puma-robot-demo adresinde bulunabilir. Ayr�ca Oliver Woodford 
% https: //www.mathworks taraf�ndan maximize.m i�levini de kullan�r. 
% com / matlabcentral / fileexchange / 25471-en �st d�zeye ��kar
%
% Dosya, Mathworks merkezi dosya payla��m�nda bulunan cad2matdemo.m'yi
% kullanarak Matlab'a d�n��t�r�len CAD verilerini kullan�r.
%

function Puma_Simulation
% Puma Robotu i�in GUI kinematik demo.
% Robot geometrisi, Mathworks dosya payla��m�nda CAD2MATDEMO kodunu kullan�r
%
%%
clear;close all; clc
%% GUI Ba�lang��  
loaddata
InitHome 
%
% Basma butonlar�n� olu�turun: pos is: [sol alt geni�lik y�kseklik]
draw_demo = uicontrol(fig_1,'String','Draw','callback',@draw_demo_button_press,...
    'Position',[20 5 60 20]);

Drawing_pop = uicontrol(fig_1,'style','popupmenu',...
    'String',{'fibonacci' 'Puma' 'Duth Robotics' 'DUTH' 'P.P.'}, 'Value', 1,...
    'Position',[85 10 50 15]);

rnd_demo = uicontrol(fig_1,'String','Random Move','callback',@rnd_demo_button_press,...
    'Position',[150 5 80 20]);

clr_trail = uicontrol(fig_1,'String','Clr Trail','callback',@clr_trail_button_press,...
    'Position',[250 5 60 20]);
%
home = uicontrol(fig_1,'String','Home','callback',@home_button_press,...
    'Position',[330 5 70 20]);
%
DH_Tm = uicontrol(fig_1,'String','DH & T matrix','callback',@DH_Tm_button_press,...
    'Position',[420 5 100 20]);
%
InverseKin = uicontrol(fig_1, 'units','normalized', 'String','Inverse Kinematics','callback',@InverseKin_button_press,...
    'Position',[0.0781 0.385 0.0781 0.029]);

%
%% Kinematik Panel
%
K_p = uipanel(fig_1, 'units','normalized', 'Position',[0.0156 0.05625 0.207 ,0.31], ...
    'Title','Forward Kinematics','FontSize',11);

%% ters Kinematik Panel
%
IK_p = uipanel(fig_1, 'units','normalized', 'Position',[0.0156 0.415 0.207 0.495],...
    'Title','Inverse Kinematics','FontSize',11);

%% D-H Table Panel
%
DH_p = uipanel(fig_1, 'units','normalized', 'Position',[0.7813 0.05625 0.207 0.365],...
    'Visible', 'On', 'Title','Denavit�Hartenberg','FontSize',11);

%%D�n���m matrisi Panel
%
Tm_p = uipanel(fig_1, 'units','normalized', 'Position',[0.75 0.43 0.25 0.3],...
    'Visible', 'On', 'Title','Tranformation matrix','FontSize',11);
%
% A�� Aral��� Varsay�lan Ad�
% Theta 1: 320 (-160 - 160) 90 Bel Eklemi
% Theta 2: 220 (-110 ila 110) -90 Omuz Eklemi
% Theta 3: 270 (-135 ila 135) -90 Dirsek Eklemi
% Theta 4: 532 (-266 ila 266) 0 Bileklik
% Theta 5: 200 (-100 ila 100) 0 Bilek Viraj
% Theta 6: 600 (-300 ila 300) 0 Bilek D�ner

t1_home = 90; % "ev" konumunu YUKARI olarak tan�mlamak i�in ofset.
t2_home = -90;
t3_home = -90;

LD = 105; % Sol, GUI'yi ayarlamak i�in kullan�l�r.
HT = 18;  % Height
BT = 156; % alt

%%  Theta 1. pos i�in GUI d��meleri: [sol alt geni�lik y�ksekli�i]
t1_slider = uicontrol(K_p,'style','slider',...
    'Max',160,'Min',-160,'Value',0,...
    'SliderStep',[0.05 0.2],...       % (160*2*0,05)  
    'callback',@t1_slider_button_press,...
    'Position',[LD BT 120 HT]);
t1_min = uicontrol(K_p,'style','text',...
    'String','-160',...
    'Position',[LD-30 BT+1 26 HT-4]); % L, alttan, W, H
t1_max = uicontrol(K_p,'style','text',...
    'String','+160',...
    'Position',[LD+125 BT+1 26 HT-4]); % L, B, W, H
t1_text = uibutton(K_p,'style','text',...  %G�zel program Doug. Uicontrol'lerde
    'String','\theta_1',...                %  hi�bir TeX'e gerek yok. 
    'Position',[LD-100 BT 20 HT]); % L, B, W, H
% t1_text = uicontrol (K_p, 'style', 'text', ...% matlab d�zeltmeleri uicontrol
% 'String', 't1', ...% TeX i�in, sonra bunu kullanabilirim.
% 'Pozisyon', [LD-100 BT 20 HT]); % L, B, W, H
t1_edit = uicontrol(K_p,'style','edit',...
    'String',0,...
    'callback',@t1_edit_button_press,...
    'Position',[LD-75 BT 30 HT]); % L, B, W, H
%
%% teta 2 ekseni i�in GUI d��meleri.
BT = 126;   % Bottom
t2_slider = uicontrol(K_p,'style','slider',...
    'Max',110,'Min',-110,'Value',0,...       
    'SliderStep',[0.05 0.2],...
    'callback',@t2_slider_button_press,...
    'Position',[LD BT 120 HT]);
t2_min = uicontrol(K_p,'style','text',...
    'String','-110',...
    'Position',[LD-30 BT+1 26 HT-4]); % L, from bottom, W, H
t2_max = uicontrol(K_p,'style','text',...
    'String','+110',...
    'Position',[LD+125 BT+1 26 HT-4]); % L, B, W, H
t2_text = uibutton(K_p,'style','text',...
    'String','\theta_2',...
    'Position',[LD-100 BT 20 HT]); % L, B, W, H
t2_edit = uicontrol(K_p,'style','edit',...
    'String',0,...
    'callback',@t2_edit_button_press,...
    'Position',[LD-75 BT 30 HT]); % L, B, W, H
%
%%  teta 3 ekseni i�in GUI d��meleri.
BT = 96;   % alt
t3_slider = uicontrol(K_p,'style','slider',...
    'Max',135,'Min',-135,'Value',0,...
    'SliderStep',[0.05 0.2],...
    'callback',@t3_slider_button_press,...
    'Position',[LD BT 120 HT]);
t3_min = uicontrol(K_p,'style','text',...
    'String','-135',...
    'Position',[LD-30 BT+1 26 HT-4]); % L, Alttan, W, H
t3_max = uicontrol(K_p,'style','text',...
    'String','+135',...
    'Position',[LD+125 BT+1 26 HT-4]); % L, B, W, H
t3_text = uibutton(K_p,'style','text',...
    'String','\theta_3',...
    'Position',[LD-100 BT 20 HT]); % L, B, W, H
t3_edit = uicontrol(K_p,'style','edit',...
    'String',0,...
    'callback',@t3_edit_button_press,...
    'Position',[LD-75 BT 30 HT]); % L, B, W, H
%
%%  teta 4 ekseni i�in GUI d��meleri.
BT = 66;   % alt
t4_slider = uicontrol(K_p,'style','slider',...
    'Max',266,'Min',-266,'Value',0,...
    'SliderStep',[0.05 0.2],...
    'callback',@t4_slider_button_press,...
    'Position',[LD BT 120 HT]);
t4_min = uicontrol(K_p,'style','text',...
    'String','-266',...
    'Position',[LD-30 BT+1 26 HT-4]); % L, Alttan, W, H
t4_max = uicontrol(K_p,'style','text',...
    'String','+266',...
    'Position',[LD+125 BT+1 26 HT-4]); % L, B, W, H
t4_text = uibutton(K_p,'style','text',...
    'String','\theta_4',...
    'Position',[LD-100 BT 20 HT]); % L, B, W, H
t4_edit = uicontrol(K_p,'style','edit',...
    'String',0,...
    'callback',@t4_edit_button_press,...
    'Position',[LD-75 BT 30 HT]); % L, B, W, H
%
%%  teta 5 ekseni i�in GUI d��meleri.
BT = 36;   % alt
t5_slider = uicontrol(K_p,'style','slider',...
    'Max',100,'Min',-100,'Value',0,...
    'SliderStep',[0.05 0.2],...
    'callback',@t5_slider_button_press,...
    'Position',[LD BT 120 HT]);
t5_min = uicontrol(K_p,'style','text',...
    'String','-100',...
    'Position',[LD-30 BT+1 26 HT-4]); % L, Alttan, W, H
t5_max = uicontrol(K_p,'style','text',...
    'String','+100',...
    'Position',[LD+125 BT+1 26 HT-4]); % L, B, W, H
t5_text = uibutton(K_p,'style','text',...
    'String','\theta_5',...
    'Position',[LD-100 BT 20 HT]); % L, B, W, H
t5_edit = uicontrol(K_p,'style','edit',...
    'String',0,...
    'callback',@t5_edit_button_press,...
    'Position',[LD-75 BT 30 HT]); % L, B, W, H
%
%%  teta 6 ekseni i�in GUI d��meleri.
BT = 6;   % alt
t6_slider = uicontrol(K_p,'style','slider',...
    'Max',300,'Min',-300,'Value',0,...
    'SliderStep',[0.05 0.2],...
    'callback',@t6_slider_button_press,...
    'Position',[LD BT 120 HT]);
t6_min = uicontrol(K_p,'style','text',...
    'String','-300',...
    'Position',[LD-30 BT+1 26 HT-4]); % L, Alttan, W, H
t6_max = uicontrol(K_p,'style','text',...
    'String','+300',...
    'Position',[LD+125 BT+1 26 HT-4]); % L, B, W, H
t6_text = uibutton(K_p,'style','text',...
    'String','\theta_6',...
    'Position',[LD-100 BT 20 HT]); % L, B, W, H
t6_edit = uicontrol(K_p,'style','edit',...
    'String',0,...
    'callback',@t6_edit_button_press,...
    'Position',[LD-75 BT 30 HT]); % L, B, W, H
%

BT = 275;

%%  Px ekseni i�in GUI d��meleri.

Px_slider = uicontrol(IK_p,'style','slider',...
    'Max',1250,'Min',-1250,'Value',0,...      wsto
    'SliderStep',[0.05 0.2],...
    'callback',@Px_slider_button_press,...
    'Position',[LD BT 120 HT]);
Px_min = uicontrol(IK_p,'style','text',...
    'String','-1250',...
    'Position',[LD-33 BT+1 32 HT-4]); % L, Alttan, W, H
Px_max = uicontrol(IK_p,'style','text',...
    'String','+1250',...
    'Position',[LD+122 BT+1 32 HT-4]); % L, B, W, H
Px_text = uibutton(IK_p,'style','text',...
    'String','P_x',...
    'Position',[LD-100 BT 20 HT]); % L, B, W, H
Px_edit = uicontrol(IK_p,'style','edit',...
    'String',0,...
    'callback',@Px_edit_button_press,...
    'Position',[LD-75 BT 30 HT]); % L, B, W, H 
%%  Py ekseni i�in GUI d��meleri.
BT = BT-30;
Py_slider = uicontrol(IK_p,'style','slider',...
    'Max',1250,'Min',-1250,'Value',0,...       
    'SliderStep',[0.05 0.2],...
    'callback',@Py_slider_button_press,...
    'Position',[LD BT 120 HT]);
Py_min = uicontrol(IK_p,'style','text',...
    'String','-1250',...
    'Position',[LD-33 BT+1 32 HT-4]); % L, Alttan, W, H
Py_max = uicontrol(IK_p,'style','text',...
    'String','+1250',...
    'Position',[LD+122 BT+1 32 HT-4]); % L, B, W, H
Py_text = uibutton(IK_p,'style','text',...
    'String','P_y',...
    'Position',[LD-100 BT 20 HT]); % L, B, W, H
Py_edit = uicontrol(IK_p,'style','edit',...
    'String',0,...
    'callback',@Py_edit_button_press,...
    'Position',[LD-75 BT 30 HT]); % L, B, W, H
%%  Pz ekseni i�in GUI d��meleri.
BT = BT-30;
Pz_slider = uicontrol(IK_p,'style','slider',...
    'Max',1250,'Min',-1250,'Value',0,...     
    'SliderStep',[0.05 0.2],...
    'callback',@Pz_slider_button_press,...
    'Position',[LD BT 120 HT]);
Pz_min = uicontrol(IK_p,'style','text',...
    'String','-1250',...
    'Position',[LD-33 BT+1 32 HT-4]); % L, from bottom, W, H
Pz_max = uicontrol(IK_p,'style','text',...
    'String','+1250',...
    'Position',[LD+122 BT+1 32 HT-4]); % L, B, W, H
Pz_text = uibutton(IK_p,'style','text',...
    'String','P_z',...
    'Position',[LD-100 BT 20 HT]); % L, B, W, H
Pz_edit = uicontrol(IK_p,'style','edit',...
    'String',0,...
    'callback',@Pz_edit_button_press,...
    'Position',[LD-75 BT 30 HT]); % L, B, W, H

%%  R11 ekseni i�in GUI d��meleri.
BT = BT-30;
R11_slider = uicontrol(IK_p,'style','slider',...
    'Max',1,'Min',-1,'Value',0,...        
    'SliderStep',[0.05 0.2],...
    'callback',@R11_slider_button_press,...
    'Position',[LD BT 120 HT]);
R11_min = uicontrol(IK_p,'style','text',...
    'String','-1',...
    'Position',[LD-30 BT+1 25 HT-4]); % L, from bottom, W, H
R11_max = uicontrol(IK_p,'style','text',...
    'String','+1',...
    'Position',[LD+125 BT+1 25 HT-4]); % L, B, W, H
R11_text = uibutton(IK_p,'style','text',...
    'String','r_1_1',...
    'Position',[LD-100 BT 20 HT]); % L, B, W, H
R11_edit = uicontrol(IK_p,'style','edit',...
    'String',0,...
    'callback',@R11_edit_button_press,...
    'Position',[LD-75 BT 30 HT]); % L, B, W, H
%%  R21 ekseni i�in GUI d��meleri.GUI buttons for R21 axis.
BT = BT-30;
R21_slider = uicontrol(IK_p,'style','slider',...
    'Max',1,'Min',-1,'Value',0,...
    'SliderStep',[0.05 0.2],...
    'callback',@R21_slider_button_press,...
    'Position',[LD BT 120 HT]);
R21_min = uicontrol(IK_p,'style','text',...
    'String','-1',...
    'Position',[LD-30 BT+1 25 HT-4]); % L, from bottom, W, H
R21_max = uicontrol(IK_p,'style','text',...
    'String','+1',...
    'Position',[LD+125 BT+1 25 HT-4]); % L, B, W, H
R21_text = uibutton(IK_p,'style','text',...
    'String','r_2_1',...
    'Position',[LD-100 BT 20 HT]); % L, B, W, H
R21_edit = uicontrol(IK_p,'style','edit',...
    'String',0,...
    'callback',@R21_edit_button_press,...
    'Position',[LD-75 BT 30 HT]); % L, B, W, H
%%  R31 ekseni i�in GUI d��meleri.
BT = BT-30;
R31_slider = uicontrol(IK_p,'style','slider',...
    'Max',1,'Min',-1,'Value',0,...
    'SliderStep',[0.05 0.2],...
    'callback',@R31_slider_button_press,...
    'Position',[LD BT 120 HT]);
R31_min = uicontrol(IK_p,'style','text',...
    'String','-1',...
    'Position',[LD-30 BT+1 25 HT-4]); % L, Alttan, W, H
R31_max = uicontrol(IK_p,'style','text',...
    'String','+1',...
    'Position',[LD+125 BT+1 25 HT-4]); % L, B, W, H
R31_text = uibutton(IK_p,'style','text',...
    'String','r_3_1',...
    'Position',[LD-100 BT 20 HT]); % L, B, W, H
R31_edit = uicontrol(IK_p,'style','edit',...
    'String',0,...
    'callback',@R31_edit_button_press,...
    'Position',[LD-75 BT 30 HT]); % L, B, W, H
%%  R13 ekseni i�in GUI d��meleri.
BT = BT-30;
R13_slider = uicontrol(IK_p,'style','slider',...
    'Max',1,'Min',-1,'Value',0,...
    'SliderStep',[0.05 0.2],...
    'callback',@R13_slider_button_press,...
    'Position',[LD BT 120 HT]);
R13_min = uicontrol(IK_p,'style','text',...
    'String','-1',...
    'Position',[LD-30 BT+1 25 HT-4]); % L, Alttan, W, H
R13_max = uicontrol(IK_p,'style','text',...
    'String','+1',...
    'Position',[LD+125 BT+1 25 HT-4]); % L, B, W, H
R13_text = uibutton(IK_p,'style','text',...
    'String','r_1_3',...
    'Position',[LD-100 BT 20 HT]); % L, B, W, H
R13_edit = uicontrol(IK_p,'style','edit',...
    'String',0,...
    'callback',@R13_edit_button_press,...
    'Position',[LD-75 BT 30 HT]); % L, B, W, H
%%  R23 ekseni i�in GUI d��meleri.
BT = BT-30;
R23_slider = uicontrol(IK_p,'style','slider',...
    'Max',1,'Min',-1,'Value',0,...
    'SliderStep',[0.05 0.2],...
    'callback',@R23_slider_button_press,...
    'Position',[LD BT 120 HT]);
R23_min = uicontrol(IK_p,'style','text',...
    'String','-1',...
    'Position',[LD-30 BT+1 25 HT-4]); % L, Alttan, W, H
R23_max = uicontrol(IK_p,'style','text',...
    'String','+1',...
    'Position',[LD+125 BT+1 25 HT-4]); % L, B, W, H
R23_text = uibutton(IK_p,'style','text',...
    'String','r_2_3',...
    'Position',[LD-100 BT 20 HT]); % L, B, W, H
R23_edit = uicontrol(IK_p,'style','edit',...
    'String',0,...
    'callback',@R23_edit_button_press,...
    'Position',[LD-75 BT 30 HT]); % L, B, W, H
%%  R33 ekseni i�in GUI d��meleri.
BT = BT-30;
R33_slider = uicontrol(IK_p,'style','slider',...
    'Max',1,'Min',-1,'Value',0,...
    'SliderStep',[0.05 0.2],...
    'callback',@R33_slider_button_press,...
    'Position',[LD BT 120 HT]);
R33_min = uicontrol(IK_p,'style','text',...
    'String','-1',...
    'Position',[LD-30 BT+1 25 HT-4]); % L,Alttan, W, H
R33_max = uicontrol(IK_p,'style','text',...
    'String','+1',...
    'Position',[LD+125 BT+1 25 HT-4]); % L, B, W, H
R33_text = uibutton(IK_p,'style','text',...
    'String','r_3_3',...
    'Position',[LD-100 BT 20 HT]); % L, B, W, H
R33_edit = uicontrol(IK_p,'style','edit',...
    'String',0,...
    'callback',@R33_edit_button_press,...
    'Position',[LD-75 BT 30 HT]); % L, B, W, H

%% Dirsek ve �evirme i�areti
 Elbow_Sign_button = uicontrol(IK_p,'style','radiobutton',...
     'String','Elbow Up / Down',...
     'callback',@elbow_sign_func,...
     'Position',[LD-100 BT-30 130 HT]);
 Flip_Sign_button = uicontrol(IK_p,'style','radiobutton',...
     'String','No Flip',...
     'callback',@flip_sign_func,...
     'Position',[LD+40 BT-30 130 HT]);
 
%% D-H Parametreleri Tablosu
% Dolinsky Jens-Uwe taraf�ndan Kinematik Robot Kalibrasyonu
% i�in Genetik Programlama Y�nteminin Geli�tirilmesi.

BT = 195;

 link_txt  = uibutton(DH_p,'style','text',...
    'FontSize', 11, 'String','Link',...
    'Position',[LD-92 BT 20 HT]); % L, B, W, H
    
 link1_txt  = uibutton(DH_p,'style','text',...
    'FontSize', 11, 'String','1',...
    'Position',[LD-92 BT-30 20 HT]); % L, B, W, H
 link2_txt  = uibutton(DH_p,'style','text',...
    'FontSize', 11, 'String','2',...
    'Position',[LD-92 BT-60 20 HT]); % L, B, W, H
 link3_txt  = uibutton(DH_p,'style','text',...
    'FontSize', 11, 'String','3',...
    'Position',[LD-92 BT-90 20 HT]); % L, B, W, H
 link4_txt  = uibutton(DH_p,'style','text',...
    'FontSize', 11, 'String','4',...
    'Position',[LD-92 BT-120 20 HT]); % L, B, W, H
 link5_txt  = uibutton(DH_p,'style','text',...
    'FontSize', 11, 'String','5',...
    'Position',[LD-92 BT-150 20 HT]); % L, B, W, H
 link6_txt  = uibutton(DH_p,'style','text',...
    'FontSize', 11, 'String','6',...
    'Position',[LD-92 BT-180 20 HT]); % L, B, W, H
   
    
 Joint_txt  = uibutton(DH_p,'style','text',...
    'FontSize', 11, 'String','Joint Type',...
    'Position',[LD-32 BT 20 HT]); % L, B, W, H

 Joint1_txt  = uibutton(DH_p,'style','text',...
    'FontSize', 9, 'String','Revolute',...
    'Position',[LD-32 BT-30 20 HT]); % L, B, W, H
 Joint2_txt  = uibutton(DH_p,'style','text',...
    'FontSize', 9, 'String','Revolute',...
    'Position',[LD-32 BT-60 20 HT]); % L, B, W, H
 Joint3_txt  = uibutton(DH_p,'style','text',...
    'FontSize', 9, 'String','Revolute',...
    'Position',[LD-32 BT-90 20 HT]); % L, B, W, H
 Joint4_txt  = uibutton(DH_p,'style','text',...
    'FontSize', 9, 'String','Revolute',...
    'Position',[LD-32 BT-120 20 HT]); % L, B, W, H
 Joint5_txt  = uibutton(DH_p,'style','text',...
    'FontSize', 9, 'String','Revolute',...
    'Position',[LD-32 BT-150 20 HT]); % L, B, W, H
 Joint6_txt  = uibutton(DH_p,'style','text',...
    'FontSize', 9, 'String','Revolute',...
    'Position',[LD-32 BT-180 20 HT]); % L, B, W, H

 Theta_txt  = uibutton(DH_p,'style','text',...
    'FontSize', 12, 'String','\theta *',...
    'FontWeight', 'bold',...
    'Position',[LD+28.5 BT 20 HT]); % L, B, W, H

 Th1_txt  = uibutton(DH_p,'style','text',...
    'FontSize', 9, 'String','0',...
    'Position',[LD+28.5 BT-30 20 HT]); % L, B, W, H
 Th2_txt  = uibutton(DH_p,'style','text',...
    'FontSize', 9, 'String','0',...
    'Position',[LD+28.5 BT-60 20 HT]); % L, B, W, H
 Th3_txt  = uibutton(DH_p,'style','text',...
    'FontSize', 9, 'String','0',...
    'Position',[LD+28.5 BT-90 20 HT]); % L, B, W, H
 Th4_txt  = uibutton(DH_p,'style','text',...
    'FontSize', 9, 'String','0',...
    'Position',[LD+28.5 BT-120 20 HT]); % L, B, W, H
 Th5_txt  = uibutton(DH_p,'style','text',...
    'FontSize', 9, 'String','0',...
    'Position',[LD+28.5 BT-150 20 HT]); % L, B, W, H
 Th6_txt  = uibutton(DH_p,'style','text',...
    'FontSize', 9, 'String','0',...
    'Position',[LD+28.5 BT-180 20 HT]); % L, B, W, H

 d_txt  = uibutton(DH_p,'style','text',...
    'FontSize', 12, 'String','d',...
    'Position',[LD+60 BT 20 HT]); % L, B, W, H
 d1_txt  = uibutton(DH_p,'style','text',...
    'FontSize', 9, 'String','0',...
    'Position',[LD+60 BT-30 20 HT]); % L, B, W, H
 d2_txt  = uibutton(DH_p,'style','text',...
    'FontSize', 9, 'String','190',...
    'Position',[LD+60 BT-60 20 HT]); % L, B, W, H
 d3_txt  = uibutton(DH_p,'style','text',...
    'FontSize', 9, 'String','0',...
    'Position',[LD+60 BT-90 20 HT]); % L, B, W, H
 d4_txt  = uibutton(DH_p,'style','text',...
    'FontSize', 9, 'String','600',...
    'Position',[LD+60 BT-120 20 HT]); % L, B, W, H
 d5_txt  = uibutton(DH_p,'style','text',...
    'FontSize', 9, 'String','0',...
    'Position',[LD+60 BT-150 20 HT]); % L, B, W, H
 d6_txt  = uibutton(DH_p,'style','text',...
    'FontSize', 9, 'String','125',...
    'Position',[LD+60 BT-180 20 HT]); % L, B, W, H

 a_txt  = uibutton(DH_p,'style','text',...
    'FontSize', 12, 'String','a',...
    'Position',[LD+92.5 BT 20 HT]); % L, B, W, H   
 a1_txt  = uibutton(DH_p,'style','text',...
    'FontSize', 9, 'String','0',...
    'Position',[LD+92.5 BT-30 20 HT]); % L, B, W, H
 a2_txt  = uibutton(DH_p,'style','text',...
    'FontSize', 9, 'String','650',...
    'Position',[LD+92.5 BT-60 20 HT]); % L, B, W, H
 a3_txt  = uibutton(DH_p,'style','text',...
    'FontSize', 9, 'String','0',...
    'Position',[LD+92.5 BT-90 20 HT]); % L, B, W, H
 a4_txt  = uibutton(DH_p,'style','text',...
    'FontSize', 9, 'String','0',...
    'Position',[LD+92.5 BT-120 20 HT]); % L, B, W, H
 a5_txt  = uibutton(DH_p,'style','text',...
    'FontSize', 9, 'String','0',...
    'Position',[LD+92.5 BT-150 20 HT]); % L, B, W, H
 a6_txt  = uibutton(DH_p,'style','text',...
    'FontSize', 9, 'String','0',...
    'Position',[LD+92.5 BT-180 20 HT]); % L, B, W, H
    
 alpha_txt  = uibutton(DH_p,'style','text',...
    'FontSize', 12, 'String','\alpha',...
    'FontWeight', 'bold',...
    'Position',[LD+125 BT 20 HT]); % L, B, W, H
 alp1_txt  = uibutton(DH_p,'style','text',...
    'FontSize', 9, 'String','-90',...
    'Position',[LD+125 BT-30 20 HT]); % L, B, W, H
 alp2_txt  = uibutton(DH_p,'style','text',...
    'FontSize', 9, 'String','0',...
    'Position',[LD+125 BT-60 20 HT]); % L, B, W, H
 alp3_txt  = uibutton(DH_p,'style','text',...
    'FontSize', 9, 'String','90',...
    'Position',[LD+125 BT-90 20 HT]); % L, B, W, H
 alp4_txt  = uibutton(DH_p,'style','text',...
    'FontSize', 9, 'String','-90',...
    'Position',[LD+125 BT-120 20 HT]); % L, B, W, H
 alp5_txt  = uibutton(DH_p,'style','text',...
    'FontSize', 9, 'String','90',...
    'Position',[LD+125 BT-150 20 HT]); % L, B, W, H
 alp6_txt  = uibutton(DH_p,'style','text',...
    'FontSize', 9, 'String','0',...
    'Position',[LD+125 BT-180 20 HT]); % L, B, W, H

%% D�n���m matrisi Tablosu

 nx_txt  = uibutton(Tm_p,'style','text',...
    'FontSize', 11, 'String','n_x=',...
    'Position',[LD-75 BT-60 20 HT]); % L, B, W, H 
 ny_txt  = uibutton(Tm_p,'style','text',...
    'FontSize', 11, 'String','n_y=',...
    'Position',[LD-75 BT-100 20 HT]); % L, B, W, H
 nz_txt  = uibutton(Tm_p,'style','text',...
    'FontSize', 11, 'String','n_z=',...
    'Position',[LD-75 BT-140 20 HT]); % L, B, W, H
 lr1_txt  = uibutton(Tm_p,'style','text',...
    'FontSize', 11, 'String','0',...
    'Position',[LD-75 BT-180 20 HT]); % L, B, W, H

 ox_txt  = uibutton(Tm_p,'style','text',...
    'FontSize', 11, 'String','o_x= ',...
    'Position',[LD BT-60 20 HT]); % L, B, W, H 
 oy_txt  = uibutton(Tm_p,'style','text',...
    'FontSize', 11, 'String','o_y= ',...
    'Position',[LD BT-100 20 HT]); % L, B, W, H
 oz_txt  = uibutton(Tm_p,'style','text',...
    'FontSize', 11, 'String','o_z= ',...
    'Position',[LD BT-140 20 HT]); % L, B, W, H
 lr2_txt  = uibutton(Tm_p,'style','text',...
    'FontSize', 11, 'String','0',...
    'Position',[LD BT-180 20 HT]); % L, B, W, H

 ax_txt  = uibutton(Tm_p,'style','text',...
    'FontSize', 11, 'String','a_x=',...
    'Position',[LD+85 BT-60 20 HT]); % L, B, W, H 
 ay_txt  = uibutton(Tm_p,'style','text',...
    'FontSize', 11, 'String','a_y=',...
    'Position',[LD+85 BT-100 20 HT]); % L, B, W, H
 az_txt  = uibutton(Tm_p,'style','text',...
    'FontSize', 11, 'String','a_z=',...
    'Position',[LD+85 BT-140 20 HT]); % L, B, W, H
 lr3_txt  = uibutton(Tm_p,'style','text',...
    'FontSize', 11, 'String','0',...
    'Position',[LD+85 BT-180 20 HT]); % L, B, W, H
 
 px_txt  = uibutton(Tm_p,'style','text',...
    'FontSize', 11, 'String','p_x=',...
    'Position',[LD+165 BT-60 20 HT]); % L, B, W, H 
 py_txt  = uibutton(Tm_p,'style','text',...
    'FontSize', 11, 'String','p_y=',...
    'Position',[LD+165 BT-100 20 HT]); % L, B, W, H
 pz_txt  = uibutton(Tm_p,'style','text',...
    'FontSize', 11, 'String','p_z= ',...
    'Position',[LD+165 BT-140 20 HT]); % L, B, W, H
 lr4_txt  = uibutton(Tm_p,'style','text',...
    'FontSize', 11, 'String','1',...
    'Position',[LD+165 BT-180 20 HT]); % L, B, W, H

%% teta 1 hareketi i�in kayd�r�c�
% 
    function t1_slider_button_press(h,dummy)
        slider_value = round(get(h,'Value'));
        set(t1_edit,'string',slider_value);
        T_Old = getappdata(0,'ThetaOld');
        t2old = T_Old(2); t3old = T_Old(3); t4old = T_Old(4);
        t5old = T_Old(5); t6old = T_Old(6);
        pumaANI(slider_value+t1_home,t2old,t3old,t4old,t5old,t6old,10,'n')
    end
%
%% teta 2 hareketi i�in kayd�r�c�
    function t2_slider_button_press(h,dummy)
        slider_value = round(get(h,'Value'));
        set(t2_edit,'string',slider_value);
        T_Old = getappdata(0,'ThetaOld');
        t1old = T_Old(1); t3old = T_Old(3); t4old = T_Old(4);
        t5old = T_Old(5); t6old = T_Old(6);
        pumaANI(t1old,slider_value+t2_home,t3old,t4old,t5old,t6old,10,'n')
    end
%
%% teta 3 hareketi i�in kayd�r�c�
    function t3_slider_button_press(h,dummy)
        slider_value = round(get(h,'Value'));
        set(t3_edit,'string',slider_value);
        T_Old = getappdata(0,'ThetaOld');
        t1old = T_Old(1); t2old = T_Old(2); t4old = T_Old(4);
        t5old = T_Old(5); t6old = T_Old(6);
        pumaANI(t1old,t2old,slider_value+t3_home,t4old,t5old,t6old,10,'n')
    end
%
%% teta 4 hareketi i�in kayd�r�c�
    function t4_slider_button_press(h,dummy)
        slider_value = round(get(h,'Value'));
        set(t4_edit,'string',slider_value);
        T_Old = getappdata(0,'ThetaOld');
        t1old = T_Old(1); t2old = T_Old(2); t3old = T_Old(3);
        t5old = T_Old(5); t6old = T_Old(6);
        pumaANI(t1old,t2old,t3old,slider_value,t5old,t6old,10,'n')
    end
%
%% teta 5 hareketi i�in kayd�r�c�
    function t5_slider_button_press(h,dummy)
        slider_value = round(get(h,'Value'));
        set(t5_edit,'string',slider_value);
        T_Old = getappdata(0,'ThetaOld');
        t1old = T_Old(1); t2old = T_Old(2); t3old = T_Old(3);
        t4old = T_Old(4); t6old = T_Old(6);
        pumaANI(t1old,t2old,t3old,t4old,slider_value,t6old,10,'n')
    end
%
%% teta 6 hareketi i�in kayd�r�c�
    function t6_slider_button_press(h,dummy)
        slider_value = round(get(h,'Value'));
        set(t6_edit,'string',slider_value);
        T_Old = getappdata(0,'ThetaOld');
        t1old = T_Old(1); t2old = T_Old(2); t3old = T_Old(3);
        t4old = T_Old(4); t5old = T_Old(5);
        pumaANI(t1old,t2old,t3old,t4old,t5old,slider_value,10,'n')
    end
%

%% Px hareketi i�in kayd�r�c�
%
    function Px_slider_button_press(h,dummy)
        slider_value = get(h,'Value');
        set(Px_edit,'string',slider_value);
    end
%
%% Py hareketi i�in kayd�r�c�
%
    function Py_slider_button_press(h,dummy)
        slider_value = get(h,'Value');
        set(Py_edit,'string',slider_value);
    end
%
%% Pz hareketi i�in kayd�r�c�
%
    function Pz_slider_button_press(h,dummy)
        slider_value = get(h,'Value');
        set(Pz_edit,'string',slider_value);
    end
%
%% R11 hareketi i�in kayd�r�c�
%
    function R11_slider_button_press(h,dummy)
        slider_value = get(h,'Value');
        set(R11_edit,'string',slider_value);
    end
%
%% R21 hareketi i�in kayd�r�c�
%
    function R21_slider_button_press(h,dummy)
        slider_value = get(h,'Value');
        set(R21_edit,'string',slider_value);
    end
%
%% R31 hareketi i�in kayd�r�c�
%
    function R31_slider_button_press(h,dummy)
        slider_value = get(h,'Value');
        set(R31_edit,'string',slider_value);
    end
%
%% R13 hareketi i�in kayd�r�c�
%
    function R13_slider_button_press(h,dummy)
        slider_value = get(h,'Value');
        set(R13_edit,'string',slider_value);
    end
    %
%% R23 hareketi i�in kayd�r�c�
%
    function R23_slider_button_press(h,dummy)
        slider_value = get(h,'Value');
        set(R23_edit,'string',slider_value);
    end
%
%% R33 hareketi i�in kayd�r�c�.
%
    function R33_slider_button_press(h,dummy)
        slider_value = get(h,'Value');
        set(R33_edit,'string',slider_value);
    end
%

%% teta 1 hareketi i�in d�zenleme kutusu.
%
     function t1_edit_button_press(h,dummy)
        user_entry = check_edit(h,-160,160,0,t1_edit);
        set(t1_slider,'Value',user_entry);  
        T_Old = getappdata(0,'ThetaOld');   % Current pose    
        %
        t2old = T_Old(2); t3old = T_Old(3); t4old = T_Old(4);
        t5old = T_Old(5); t6old = T_Old(6);
        %
        pumaANI(user_entry+t1_home,t2old,t3old,t4old,t5old,t6old,10,'n')
    end
%
%% teta 2 hareketi i�in d�zenleme kutusu.
%
    function t2_edit_button_press(h,dummy)
        user_entry = check_edit(h,-110,110,0,t2_edit);
        set(t2_slider,'Value',user_entry);  
        T_Old = getappdata(0,'ThetaOld');   % Current pose    
        %
        t1old = T_Old(1); t3old = T_Old(3); t4old = T_Old(4);
        t5old = T_Old(5); t6old = T_Old(6);
        %
        pumaANI(t1old,user_entry+t2_home,t3old,t4old,t5old,t6old,10,'n')
    end
%% teta 3 hareketi i�in d�zenleme kutusu.
%
    function t3_edit_button_press(h,dummy)
        user_entry = check_edit(h,-135,135,0,t3_edit);
        set(t3_slider,'Value',user_entry);  
        T_Old = getappdata(0,'ThetaOld');   % Current pose    
        %
        t1old = T_Old(1); t2old = T_Old(2); t4old = T_Old(4);
        t5old = T_Old(5); t6old = T_Old(6);
        %
        pumaANI(t1old,t2old,user_entry+t3_home,t4old,t5old,t6old,10,'n')
    end
%% teta 4 hareketi i�in d�zenleme kutusu.
    function t4_edit_button_press(h,dummy)
        user_entry = check_edit(h,-266,266,0,t4_edit);
        set(t4_slider,'Value',user_entry);  
        T_Old = getappdata(0,'ThetaOld');   % Current pose    
        %
        t1old = T_Old(1); t2old = T_Old(2); t3old = T_Old(3);
        t5old = T_Old(5); t6old = T_Old(6);
        %
        pumaANI(t1old,t2old,t3old,user_entry,t5old,t6old,10,'n')
    end
%% teta 5 hareketi i�in d�zenleme kutusu.
%
    function t5_edit_button_press(h,dummy)
        user_entry = check_edit(h,-100,100,0,t5_edit);
        set(t5_slider,'Value',user_entry);  
        T_Old = getappdata(0,'ThetaOld');   % Current pose    
        %
        t1old = T_Old(1); t2old = T_Old(2); t3old = T_Old(3);
        t4old = T_Old(4); t6old = T_Old(6);
        %
        pumaANI(t1old,t2old,t3old,t4old,user_entry,t6old,10,'n')
    end
%% teta 6 hareketi i�in d�zenleme kutusu.
%
    function t6_edit_button_press(h,dummy)
        user_entry = check_edit(h,-300,300,0,t6_edit);
        disp (user_entry);
        set(t6_slider,'Value',user_entry);  
        T_Old = getappdata(0,'ThetaOld');   % Current pose    
        %
        t1old = T_Old(1); t2old = T_Old(2); t3old = T_Old(3);
        t4old = T_Old(4); t5old = T_Old(5);
        %
        pumaANI(t1old,t2old,t3old,t4old,t5old,user_entry,10,'n')
    end
%

%% Px hareketi i�in d�zenleme kutusu.
%
    function Px_edit_button_press(h,dummy)
        user_entry = check_edit(h,-1250,1250,0,Px_edit);
        set(Px_slider,'Value',user_entry);  
        setappdata (0,'Pxold',user_entry);
    end
%% Py hareketi i�in d�zenleme kutusu.
%
    function Py_edit_button_press(h,dummy)
        user_entry = check_edit(h,-1250,1250,0,Py_edit);
        set(Py_slider,'Value',user_entry);  
        setappdata (0,'Pyold',user_entry);
    end
%% Pz hareketi i�in d�zenleme kutusu. 
%
    function Pz_edit_button_press(h,dummy)
        user_entry = check_edit(h,-1250,1250,0,Pz_edit);
        set(Pz_slider,'Value',user_entry);  
        setappdata (0,'Pzold',user_entry);
    end
%% R11 hareketi i�in d�zenleme kutusu.
%
    function R11_edit_button_press(h,dummy)
        user_entry = check_edit(h,-1200,1200,0,R11_edit);
        set(R11_slider,'Value',user_entry);  
        setappdata (0,'R11old',user_entry);
    end
%% R21 hareketi i�in d�zenleme kutusu.
%
    function R21_edit_button_press(h,dummy)
        user_entry = check_edit(h,-1200,1200,0,R21_edit);
        set(R21_slider,'Value',user_entry);  
        setappdata (0,'R21old',user_entry);
    end
%% Edit box for R31 motion.
%
    function R31_edit_button_press(h,dummy)
        user_entry = check_edit(h,-1200,1200,0,R31_edit);
        set(R31_slider,'Value',user_entry);  
        setappdata (0,'R31old',user_entry);
    end
%% R13 hareketi i�in d�zenleme kutusu.
%
    function R13_edit_button_press(h,dummy)
        user_entry = check_edit(h,-1200,1200,0,R13_edit);
        set(R13_slider,'Value',user_entry);  
        setappdata (0,'R13old',user_entry);
    end
%% R23 hareketi i�in d�zenleme kutusu.
%
    function R23_edit_button_press(h,dummy)
        user_entry = check_edit(h,-1200,1200,0,R23_edit);
        set(R23_slider,'Value',user_entry);  
        setappdata (0,'R23old',user_entry);
    end
%% R33 hareketi i�in d�zenleme kutusu.
%
    function R33_edit_button_press(h,dummy)
        user_entry = check_edit(h,-1200,1200,0,R33_edit);
        set(R33_slider,'Value',user_entry);  
        setappdata (0,'R33old',user_entry);
    end

%% UIControl fonksiyonu
    function elbow_sign_func (h,dummy)
        if get(Elbow_Sign_button,'Value')== 1
            set(Elbow_Sign_button, 'String', 'Elbow Down'); %D��menin Dize de�i�tir
        else
            set(Elbow_Sign_button, 'String', 'Elbow Up');   % D��menin Dize de�i�tir
        end
    end

    function flip_sign_func (h,dummy)
        if get(Flip_Sign_button,'Value')== 1
            set(Flip_Sign_button, 'String', 'Flip');     % D��menin Dize de�i�tir
        else
            set(Flip_Sign_button, 'String', 'No Flip');  % D��menin Dize de�i�tir
        end
    end

    function user_entry = check_edit(h,min_v,max_v,default,h_edit)
 % Bu fonksiyon metin giri� kutusuna yaz�lan de�eri min ve maksimum
 % de�erlere g�re kontrol eder ve hatalar� d�zeltir.
 %
% Kontrol edilecek minimum : min_v dk de�eri
% Kontrol edilecek maksimum : max_v maksimum de�er
% Kullan�c� numaras�z girerse, varsay�lan de�er varsay�lan de�erdir
% h_edit, g�ncellenecek d�zenleme de�eridir.
        %
        user_entry = str2double(get(h,'string'));
        if isnan(user_entry)
            errordlg(['You must enter a numeric value, defaulting to ',num2str(default),'.'],'Bad Input','modal')
            set(h_edit,'string',default);
            user_entry = default;
        end
        %
        if user_entry < min_v
            errordlg(['Minimum limit is ',num2str(min_v),' degrees, using ',num2str(min_v),'.'],'Bad Input','modal')
            user_entry = min_v;
            set(h_edit,'string',user_entry);
        end
        if user_entry > max_v
            errordlg(['Maximum limit is ',num2str(max_v),' degrees, using ',num2str(max_v),'.'],'Bad Input','modal')
            user_entry = max_v;
            set(h_edit,'string',user_entry);
        end
    end

% demo butonunun geri �agr�s�n� �iz
    function draw_demo_button_press(h,dummy)
        
        clr_trail_button_press(h,dummy);
        drawing = get (Drawing_pop, 'Value');
        graphics=load('graphics', 'FI', 'DR', 'DU', 'PU', 'PP');
        n = 2;    % ba�lamak i�in ani ad�mlar� ad�mlar�n� 
        num = 30; % �izin ve ani ad�mlar�na son verin
        
        switch drawing
            case 1,     graf = graphics.FI;
            case 2,     graf = graphics.PU;
            case 3,     graf = graphics.DR;
            case 4,     graf = graphics.DU;
            case 5,     graf = graphics.PP;
            otherwise,  disp('something went wrong');
        end
        
        for i=1:size(graf,1)
            Px = graf(i,1);
            Pz = graf(i,2);
            Py = graf(i,3);
            [theta1,theta2,theta3,theta4,theta5,theta6] = PumaIK(Px,Py,Pz,0,0,0,0,0,0);
            pumaANI(theta1,theta2,theta3-180,theta4,theta5,theta6,n,'y')
            set(t1_edit,'string',round(theta1)); % Kayd�r�c�y� ve metni g�ncelleyin.
            set(t1_slider,'Value',round(theta1));
            set(Th1_txt,'string',round(theta1));
            set(t2_edit,'string',round(theta2));
            set(t2_slider,'Value',round(theta2));
            set(Th2_txt,'string',round(theta2));
            set(t3_edit,'string',round(theta3-180));
            set(t3_slider,'Value',round(theta3-180));
            set(Th3_txt,'string',round(theta3-180));
            set(t4_edit,'string',round(theta4));
            set(t4_slider,'Value',round(theta4));
            set(Th4_txt,'string',round(theta4));
            set(t5_edit,'string',round(theta5));
            set(t5_slider,'Value',round(theta5));
            set(Th5_txt,'string',round(theta5));
            set(t6_edit,'string',round(theta6));
            set(t6_slider,'Value',round(theta6));
            set(Th6_txt,'string',round(theta6));
        end              
        gohome
    end

    function home_button_press(h,dummy)
        %disp('ev butonuna bas�l�rsa');
        gohome
    end

    function clr_trail_button_press(h,dummy)
        %disp('alt temizle butonuna bas�l�rsa');
        handles = getappdata(0,'patch_h');           %
        Tr = handles(9);
        %
        setappdata(0,'xtrail',0); % iz takibi i�in kullan�l�r.
        setappdata(0,'ytrail',0); % iz takibi i�in kullan�l�r.
        setappdata(0,'ztrail',0); % iz takibi i�in kullan�l�r.
        %
        set(Tr,'xdata',0,'ydata',0,'zdata',0);
    end

    function rnd_demo_button_press(h, dummy)
       % disp ('itti rastgele demo alt');
       % a = 10; b = 50; x = a + (b-a) * rand (5)
        % A�� Aral��� Varsay�lan Ad�
        % Theta 1: 320 (-160 - 160) 90 Bel Eklemi
        % Theta 2: 220 (-110 ila 110) -90 Omuz Eklemi
        % Theta 3: 270 (-135 ila 135) -90 Dirsek Eklemi
        % Theta 4: 532 (-266 ila 266) 0 Bileklik
        % Theta 5: 200 (-100 ila 100) 0 Bilek Viraj
        % Theta 6: 600 (-300 ila 300) 0 Bileklik
        t1_home = 90; % "ev" g�nderimini UP olarak tan�mlamak i�in ofsetler.
        t2_home = -90;
        t3_home = -90;
        theta1 = -160 + 320*rand(1); % UP konumunda ev i�in ofset.
        theta2 = -110 + 220*rand(1);
        theta3 = -135 + 270*rand(1);
        theta4 = -266 + 532*rand(1);
        theta5 = -100 + 200*rand(1);
        theta6 = -300 + 600*rand(1);
        n = 50;
        pumaANI(theta1+t1_home,theta2+t2_home,theta3+t3_home,theta4,theta5,theta6,n,'y')
        set(t1_edit,'string',round(theta1)); % Kayd�r�c�y� ve metni g�ncelleyin.
            set(t1_slider,'Value',round(theta1));
            set(Th1_txt,'string',round(theta1));
            set(t2_edit,'string',round(theta2));
            set(t2_slider,'Value',round(theta2));
            set(Th2_txt,'string',round(theta2));
            set(t3_edit,'string',round(theta3-180));
            set(t3_slider,'Value',round(theta3-180));
            set(Th3_txt,'string',round(theta3-180));
            set(t4_edit,'string',round(theta4));
            set(t4_slider,'Value',round(theta4));
            set(Th4_txt,'string',round(theta4));
            set(t5_edit,'string',round(theta5));
            set(t5_slider,'Value',round(theta5));
            set(Th5_txt,'string',round(theta5));
            set(t6_edit,'string',round(theta6));
            set(t6_slider,'Value',round(theta6));
            set(Th6_txt,'string',round(theta6));
    end
        
    function DH_Tm_button_press(h,dummy)
        if strcmp(DH_p.Visible,'off')
            DH_p.Visible = 'on';
            Tm_p.Visible = 'on';
        else
            DH_p.Visible = 'off';
            Tm_p.Visible = 'off';
        end
    end

    function InverseKin_button_press(h,dummy)
     
          Px=str2double(get(Px_edit,'string')); 
          Py=str2double(get(Py_edit,'string'));
          Pz=str2double(get(Pz_edit,'string'));
          R11=str2double(get(R11_edit,'string')); 
          R21=str2double(get(R21_edit,'string'));
          R31=str2double(get(R31_edit,'string'));
          R13=str2double(get(R13_edit,'string')); 
          R23=str2double(get(R23_edit,'string'));
          R33=str2double(get(R33_edit,'string'));
          
          [theta1,theta2,theta3,theta4,theta5,theta6,noplot] = PumaIK(Px,Py,Pz,R11,R21,R31,R13,R23,R33);

        if noplot == 0
            pumaANI(theta1,theta2,theta3-180,theta4,theta5,theta6,10,'n')
            set(t1_edit,'string',round((theta1-90)*100)/100); % Kayd�r�c�y� ve metni g�ncelleyin.
            set(t1_slider,'Value',round(theta1-90));
            set(Th1_txt,'string',round(theta1));
            set(t2_edit,'string',round((theta2+90)*100)/100);   % * 100) / 100'e 2 basama�a
            set(t2_slider,'Value',round(theta2+90));
            set(Th2_txt,'string',round((theta2+90)*100)/100);
            set(t3_edit,'string',round((theta3-90)*100)/100);
            set(t3_slider,'Value',round(theta3-90));
            set(Th3_txt,'string',round((theta3-90)*100)/100);
            set(t4_edit,'string',round((theta4)*100)/100); % Kayd�r�c�y� ve metni g�ncelleyin.
            set(t4_slider,'Value',round(theta4));
            set(Th4_txt,'string',round(((theta4)*100)/100));
            set(t5_edit,'string',round((theta5)*100)/100);
            set(t5_slider,'Value',round(theta5));
            set(Th5_txt,'string',round(((theta5)*100)/100));
            set(t6_edit,'string',round((theta6)*100)/100);
            set(t6_slider,'Value',round(theta6));
            set(Th6_txt,'string',round(((theta6)*100)/100));

        else
            h = errordlg('Point unreachable due to joint angle constraints. noplot = 1.','JOINT ERROR');
            waitfor(h);
        end
       
    end


%% Di�er GUI fonksiyonlar�

% Bu fonksiyon 3D CAD verilerini y�kleyecektir.
    function loaddata
% T�m link verilerini filedada.mat dosyas�ndan y�kler.
% Bu veri bir Pro / E 3D CAD modelinden gelir ve dosya de�i�iminden cad2matdemo.m
% ile yap�lm��t�r. Linksdata.mat i�inde manuel olarak saklanan t�m link verileri
[linkdata]=load('linksdata.mat','s1','s2','s3','s4','s5','s6','s7','A1');

%Robot ba�lant�s�n� 'veri' bir depolama alan�na yerle�tirin
setappdata(0,'Link1_data',linkdata.s1);
setappdata(0,'Link2_data',linkdata.s2);
setappdata(0,'Link3_data',linkdata.s3);
setappdata(0,'Link4_data',linkdata.s4);
setappdata(0,'Link5_data',linkdata.s5);
setappdata(0,'Link6_data',linkdata.s6);
setappdata(0,'Link7_data',linkdata.s7);
setappdata(0,'Area_data',linkdata.A1);
    end

% Bu i�lev GUI aray�z�n� ba�latacak
    function InitHome
        % Robotu belirtilen bir konfig�rasyona yerle�tirmek i�in
        % ileri kinematik kullan�n. Kurulum ayar verilerini kurun,
        % GUI i�in yeni bir �ekil olu�turun
        set(0,'Units','pixels')
        dim = get(0,'ScreenSize');
        fig_1 = figure('doublebuffer','on','Position',[0,35,dim(3)-200,dim(4)-100],...
            'Name',' 3D Puma Robot Graphical Demo',...
            'NumberTitle','off');

        hold on;
        %���kl�l�k('pozisyon',[-1 0 0]);
        light                               % varsay�lan ���kl�l�k ekle
        daspect([1 1 1])                    % En boy oran�n� ayarlama
        view(135,25)
        xlabel('X'),ylabel('Y'),zlabel('Z');
        title ('PUMA 762 Simulation');
        axis([-1500 1500 -1500 1500 -1120 1500]);
        plot3([-1500,1500],[-1500,-1500],[-1120,-1120],'k')
        plot3([-1500,-1500],[-1500,1500],[-1120,-1120],'k')
        plot3([-1500,-1500],[-1500,-1500],[-1120,1500],'k')
        plot3([-1500,-1500],[1500,1500],[-1120,1500],'k')
        plot3([-1500,1500],[-1500,-1500],[1500,1500],'k')
        plot3([-1500,-1500],[-1500,1500],[1500,1500],'k')
        grid on;

        s1 = getappdata(0,'Link1_data');
        s2 = getappdata(0,'Link2_data');
        s3 = getappdata(0,'Link3_data');
        s4 = getappdata(0,'Link4_data');
        s5 = getappdata(0,'Link5_data');
        s6 = getappdata(0,'Link6_data');
        s7 = getappdata(0,'Link7_data');
        A1 = getappdata(0,'Area_data');
        %
        a2 = 650;
        a3 = 0;
        d3 = 190;
        d4 = 600;
        d6 = 125;
%         Px = 5000;
%         Py = 5000;
%         Pz = 5000;
%         R11 = 0;
%         R21 = 0;
%         R31 = 0;
%         R13 = 0;
%         R23 = 0;
%         R33 = 0;

        %Init i�in 'ev' pozisyonu.
        t1 = 90;
        t2 = -90;
        t3 = -90;
        t4 = 0;
        t5 = 0;
        t6 = 0;
        
        % �leri Kinematik
        T_01 = tmat(0, 0, 0, t1);
        T_12 = tmat(-90, 0, 0, t2);
        T_23 = tmat(0, a2, d3, t3);
        T_34 = tmat(-90, a3, d4, t4);
        T_45 = tmat(90, 0, 0, t5);
        T_56 = tmat(-90, 0, 0, t6);

        % Each link fram to base frame transformation
        T_02 = T_01*T_12;
        T_03 = T_02*T_23;
        T_04 = T_03*T_34;
        T_05 = T_04*T_45;
        T_06 = T_05*T_56;
        
        % Robot ba�lant�lar�n�n ger�ek vertex verileri
        Link1 = s1.V1;
        Link2 = (T_01*s2.V2')';
        Link3 = (T_02*s3.V3')';
        Link4 = (T_03*s4.V4')';
        Link5 = (T_04*s5.V5')';
        Link6 = (T_05*s6.V6')';
        Link7 = (T_06*s7.V7')';
        
        % puan izlemek i�in e�lenceli de�il, 3d g�r�nmesi.
        L1 = patch('faces', s1.F1, 'vertices' ,Link1(:,1:3));
        L2 = patch('faces', s2.F2, 'vertices' ,Link2(:,1:3));
        L3 = patch('faces', s3.F3, 'vertices' ,Link3(:,1:3));
        L4 = patch('faces', s4.F4, 'vertices' ,Link4(:,1:3));
        L5 = patch('faces', s5.F5, 'vertices' ,Link5(:,1:3));
        L6 = patch('faces', s6.F6, 'vertices' ,Link6(:,1:3));
        L7 = patch('faces', s7.F7, 'vertices' ,Link7(:,1:3));
        A1 = patch('faces', A1.Fa, 'vertices' ,A1.Va(:,1:3));
        Tr = plot3(0,0,0,'b.'); % iz yollar� i�in tutucu
        setappdata(0,'patch_h',[L1,L2,L3,L4,L5,L6,L7,A1,Tr])
        %
        setappdata(0,'xtrail',0); % iz takibi i�in kullan�l�r.
        setappdata(0,'ytrail',0); % iz takibi i�in kullan�l�r.
        setappdata(0,'ztrail',0); % iz takibi i�in kullan�l�r.
        %
        % Linkler Renkler [R, G, B] (1'den daha y�ksek ayarlamay�n)
        set(L1, 'facec', [0.717,0.116,0.123]); 
        set(L1, 'EdgeColor','none');
        set(L2, 'facec', [0.216,1,.583]);
        set(L2, 'EdgeColor','none');
        set(L3, 'facec', [0.306,0.733,1]);
        set(L3, 'EdgeColor','none');
        set(L4, 'facec', [1,0.542,0.493]);
        set(L4, 'EdgeColor','none');
        set(L5, 'facec', [0.216,1,.583]);
        set(L5, 'EdgeColor','none');
        set(L6, 'facec', [1,1,0.255]);
        set(L6, 'EdgeColor','none');
        set(L7, 'facec', [0.306,0.733,1]);
        set(L7, 'EdgeColor','none');
        set(A1, 'facec', [.8,.8,.8],'FaceAlpha',.25);
        set(A1, 'EdgeColor','none');
        %
        setappdata(0,'ThetaOld',[90,-90,-90,0,0,0]);
        %
        setappdata(0,'XYZOld', [0,0,1300]);
        
        maximize;
    end

% Bu i�lev rakam� en �st d�zeye ��kar�r
    function maximize(hFig)

    %MAXIMIZE Ekran� doldurmak i�in bir �ekil penceresini maksimize edin
    %
    % �rnekler:
    % maksimize
    % maksimize (hFig)
    %
    % Ge�erli veya giri� �eklini en �st d�zeye ��kar�r,
    % b�ylece �ekil �u andaki ekran�n tamam�n� doldurur. 
    % Bu i�lev platformdan ba��ms�zd�r.
    %
    %IN:
    %   hFig - En �st d�zeye ��karmak i�in �eklin kolu. varsay�lan: gcf.
        
        if nargin < 1
            hFig = gcf;
        end
        drawnow % Java hatalar�n� �nlemek i�in gerekli
        jFig = get(handle(hFig), 'JavaFrame'); 
        jFig.setMaximized(true);
    end

    function del_app(varargin)
        %Bu, geometri i�in kullan�ld���ndan dolay� b�rak�labilecek uygulama
        %verilerini kald�rmak i�in ana �ekil penceresi kapatma i�levidir.
        %CloseRequestFcn, kald�r�lacak veriler:

        %     Link1_data: [1x1 struct]
        %     Link2_data: [1x1 struct]
        %     Link3_data: [1x1 struct]
        %     Link4_data: [1x1 struct]
        %     Link5_data: [1x1 struct]
        %     Link6_data: [1x1 struct]
        %     Link7_data: [1x1 struct]
        %      Area_data: [1x1 struct]
        %        patch_h: [1x9 double]
        %       ThetaOld: [90 -182 -90 -106 80 106]
        %         xtrail: 0
        %         ytrail: 0
        %         ztrail: 0
        % �imdi onlar� kald�r�n.
        rmappdata(0,'Link1_data');
        rmappdata(0,'Link2_data');
        rmappdata(0,'Link3_data');
        rmappdata(0,'Link4_data');
        rmappdata(0,'Link5_data');
        rmappdata(0,'Link6_data');
        rmappdata(0,'Link7_data');
        rmappdata(0,'ThetaOld');
        rmappdata(0,'XYZOld'); 
        rmappdata(0,'Area_data');
        rmappdata(0,'patch_h');
        rmappdata(0,'xtrail');
        rmappdata(0,'ytrail');
        rmappdata(0,'ztrail');
        delete(fig_1);
    end


%% ��te bu robot i�in Kinematik Problemleri ��zmek i�in kullan�lan fonksiyonlar:
%
% Bu fonksiyon �a�r�ld���nda Puma 762 robotunun bir komplounu,
% ev oryantasyonunda �izerek ve mevcut a��lar� buna g�re ayarlayarak 
% basit�e ba�latacakt�r.
    function gohome()
        pumaANI(90,-90,-90,0,0,0,20,'n') % evi canl� g�ster
        %PumaPOS(90,-90,-90,0,0,0)  %Eve git, canland�rmaya gerek yok.
        set(t1_edit,'string',0);
        set(t1_slider,'Value',0);  %Ev konumunda, t�m s�rg� ve giri� kutular� = 0.
        set(t2_edit,'string',0);   
        set(t2_slider,'Value',0);
        set(t3_edit,'string',0);
        set(t3_slider,'Value',0);
        set(t4_edit,'string',0);
        set(t4_slider,'Value',0);
        set(t5_edit,'string',0);
        set(t5_slider,'Value',0);
        set(t6_edit,'string',0);
        set(t6_slider,'Value',0);
        
        set(Px_edit,'string',0);
        set(Px_slider,'Value',0);  %ters Kinematics i�in de ayn�
        set(Py_edit,'string',0);   
        set(Py_slider,'Value',0);
        set(Pz_edit,'string',0);
        set(Pz_slider,'Value',0);
        set(R11_edit,'string',0);
        set(R11_slider,'Value',0);
        set(R21_edit,'string',0);
        set(R21_slider,'Value',0);
        set(R31_edit,'string',0);
        set(R31_slider,'Value',0);
        set(R13_edit,'string',0);
        set(R13_slider,'Value',0);  
        set(R23_edit,'string',0);   
        set(R23_slider,'Value',0);
        set(R33_edit,'string',0);
        set(R33_slider,'Value',0);
                
        setappdata(0,'ThetaOld',[90,-90,-90,0,0,0]);
    end

% Robotu belirtilen bir konfig�rasyona yerle�tirmek i�in ileri kinematik kullan�n.
%(animasyon yetenekleri olmadan)
    function PumaPOS(theta1,theta2,theta3,theta4,theta5,theta6) 

        s1 = getappdata(0,'Link1_data');
        s2 = getappdata(0,'Link2_data');
        s3 = getappdata(0,'Link3_data');
        s4 = getappdata(0,'Link4_data');
        s5 = getappdata(0,'Link5_data');
        s6 = getappdata(0,'Link6_data');
        s7 = getappdata(0,'Link7_data');
        A1 = getappdata(0,'Area_data');

        a2 = 650;         
        a3 = 0;
        d3 = 190;           
        d4 = 600;
        d6 = 125;
        Px = 5000;
        Py = 5000;
        Pz = 5000;

        t1 = theta1; 
        t2 = theta2; 
        t3 = theta3;
        t4 = theta4; 
        t5 = theta5; 
        t6 = theta6; 
        %
        % ileri Kinematik
        T_01 = tmat(0, 0, 0, t1);
        T_12 = tmat(-90, 0, 0, t2);
        T_23 = tmat(0, a2, d3, t3);
        T_34 = tmat(-90, a3, d4, t4);
        T_45 = tmat(90, 0, 0, t5);
        T_56 = tmat(-90, 0, d6, t6);

        T_02 = T_01*T_12;
        T_03 = T_02*T_23;
        T_04 = T_03*T_34;
        T_05 = T_04*T_45;
        T_06 = T_05*T_56;
        %
        Link1 = s1.V1;
        Link2 = (T_01*s2.V2')';
        Link3 = (T_02*s3.V3')';
        Link4 = (T_03*s4.V4')';
        Link5 = (T_04*s5.V5')';
        Link6 = (T_05*s6.V6')';
        Link7 = (T_06*s7.V7')';

        handles = getappdata(0,'patch_h');           %
        L1 = handles(1);
        L2 = handles(2);
        L3 = handles(3);
        L4 = handles(4);
        L5 = handles(5);
        L6 = handles(6);
        L7 = handles(7);
        %
        set(L1,'vertices',Link1(:,1:3),'facec', [0.717,0.116,0.123]);
        set(L1, 'EdgeColor','none');
        set(L2,'vertices',Link2(:,1:3),'facec', [0.216,1,.583]);
        set(L2, 'EdgeColor','none');
        set(L3,'vertices',Link3(:,1:3),'facec', [0.306,0.733,1]);
        set(L3, 'EdgeColor','none');
        set(L4,'vertices',Link4(:,1:3),'facec', [1,0.542,0.493]);
        set(L4, 'EdgeColor','none');
        set(L5,'vertices',Link5(:,1:3),'facec', [0.216,1,.583]);
        set(L5, 'EdgeColor','none');
        set(L6,'vertices',Link6(:,1:3),'facec', [1,1,0.255]);
        set(L6, 'EdgeColor','none');
        set(L7,'vertices',Link7(:,1:3),'facec', [0.306,0.733,1]);
        set(L7, 'EdgeColor','none');
    end
 
%Bu i�lev Puma 762 robotu i�in �leri Kinemati�i hesaplar
%(animasyon yetenekleri ile)
    function pumaANI(theta1,theta2,theta3,theta4,theta5,theta6,n,trail)
        % Bu i�lev, eklem a��lar� verilen Puma 762 robotunu canland�r�r. 
        % n, bir iz b�rakt���n�z i�in animasyon izinin 'y' veya 'n'
        % (n = ba�ka bir �ey) oldu�u ad�m say�s�d�r.
        % disp ('canland�rmada');
        
        a2 = 650; %D-H parametreleri
        a3 = 0;
        d3 = 190;
        d4 = 600;
        d6 = 125;

        ThetaOld = getappdata(0,'ThetaOld');
        
        theta1old = ThetaOld(1);
        theta2old = ThetaOld(2);
        theta3old = ThetaOld(3);
        theta4old = ThetaOld(4);
        theta5old = ThetaOld(5);
        theta6old = ThetaOld(6);
        %
        t1 = linspace(theta1old,theta1,n); 
        t2 = linspace(theta2old,theta2,n); 
        t3 = linspace(theta3old,theta3,n);  
        t4 = linspace(theta4old,theta4,n); 
        t5 = linspace(theta5old,theta5,n); 
        t6 = linspace(theta6old,theta6,n); 

        n = length(t1);
        for i = 2:1:n
            % ileri kinematik
            
            T_01 = tmat(0, 0, 0, t1(i));
            T_12 = tmat(-90, 0, 0, t2(i));
            T_23 = tmat(0, a2, d3, t3(i));
            T_34 = tmat(-90, a3, d4, t4(i));
            T_45 = tmat(90, 0, 0, t5(i));
            T_56 = tmat(-90, 0, 0, t6(i));
            T_67 = tmat(0, 0, d6, 0);
            
            T_02 = T_01*T_12;
            T_03 = T_02*T_23;
            T_04 = T_03*T_34;
            T_05 = T_04*T_45;
            T_06 = T_05*T_56;
            T_07 = T_06*T_67;
            %
            s1 = getappdata(0,'Link1_data');
            s2 = getappdata(0,'Link2_data');
            s3 = getappdata(0,'Link3_data');
            s4 = getappdata(0,'Link4_data');
            s5 = getappdata(0,'Link5_data');
            s6 = getappdata(0,'Link6_data');
            s7 = getappdata(0,'Link7_data');
            A1 = getappdata(0,'Area_data');

            Link1 = s1.V1;
            Link2 = (T_01*s2.V2')';
            Link3 = (T_02*s3.V3')';
            Link4 = (T_03*s4.V4')';
            Link5 = (T_04*s5.V5')';
            Link6 = (T_05*s6.V6')';
            Link7 = (T_06*s7.V7')';
        
            handles = getappdata(0,'patch_h');           
            L1 = handles(1);
            L2 = handles(2);
            L3 = handles(3);
            L4 = handles(4);
            L5 = handles(5);
            L6 = handles(6);
            L7 = handles(7);
            Tr = handles(9);
            %
            set(L1,'vertices',Link1(:,1:3),'facec', [0.717,0.116,0.123]);
            set(L1, 'EdgeColor','none');
            set(L2,'vertices',Link2(:,1:3),'facec', [0.216,1,.583]);
            set(L2, 'EdgeColor','none');
            set(L3,'vertices',Link3(:,1:3),'facec', [0.306,0.733,1]);
            set(L3, 'EdgeColor','none');
            set(L4,'vertices',Link4(:,1:3),'facec', [1,0.542,0.493]);
            set(L4, 'EdgeColor','none');
            set(L5,'vertices',Link5(:,1:3),'facec', [0.216,1,.583]);
            set(L5, 'EdgeColor','none');
            set(L6,'vertices',Link6(:,1:3),'facec', [1,1,0.255]);
            set(L6, 'EdgeColor','none');
            set(L7,'vertices',Link7(:,1:3),'facec', [0.306,0.733,1]);
            set(L7, 'EdgeColor','none');
            % appdata'da ma�aza takibi 
            if trail == 'y'
                x_trail = getappdata(0,'xtrail');
                y_trail = getappdata(0,'ytrail');
                z_trail = getappdata(0,'ztrail');
                %
                xdata = [x_trail T_04(1,4)];
                ydata = [y_trail T_04(2,4)];
                zdata = [z_trail T_04(3,4)];
                %
                setappdata(0,'xtrail',xdata); % iz takibi i�in kullan�l�r.
                setappdata(0,'ytrail',ydata); % iz takibi i�in kullan�l�r.
                setappdata(0,'ztrail',zdata); % iz takibi i�in kullan�l�r.
                %
                set(Tr,'xdata',xdata,'ydata',ydata,'zdata',zdata);
            end
            drawnow
        end
        
        format bank
        set (nx_txt,'String',['n_x= ',num2str(round(T_06(1,1), 2))]);
        set (ny_txt,'String',['n_y= ',num2str(round(T_06(2,1), 2))]);
        set (nz_txt,'String',['n_z= ',num2str(round(T_06(3,1), 2))]);
        set (ox_txt,'String',['o_x= ',num2str(round(T_06(1,2), 2))]);
        set (oy_txt,'String',['o_y= ',num2str(round(T_06(2,2), 2))]);
        set (oz_txt,'String',['o_z= ',num2str(round(T_06(3,2), 2))]);
        set (ax_txt,'String',['a_x= ',num2str(round(T_06(1,3), 2))]);
        set (ay_txt,'String',['a_y= ',num2str(round(T_06(2,3), 2))]);
        set (az_txt,'String',['a_z= ',num2str(round(T_06(3,3), 2))]);
        set (px_txt,'String',['p_x= ',num2str(round(T_06(1,4)))]);
        set (py_txt,'String',['p_y= ',num2str(round(T_06(2,4)))]);
        set (pz_txt,'String',['p_z= ',num2str(round(T_06(3,4)))]);
        format long
        setappdata(0,'ThetaOld',[theta1,theta2,theta3,theta4,theta5,theta6]);
    end

% Bu i�lev Puma 762 robotu i�in Ters Kinemati�i hesaplar
    function [theta1,theta2,theta3,theta4,theta5,theta6,noplot] = PumaIK(Px,Py,Pz,R11,R21,R31,R13,R23,R33)
       
        angles= [];
        a2 = 650;
        a3 = 0;
        d3 = 190;
        d4 = 600;
        d6 = 125;
        
        sign1 = 1;
        sign2 = 1;
        nogo = 0;
        noplot = 0;
        elbowSign = get(Elbow_Sign_button,'Value');
        flipSign = get(Flip_Sign_button,'Value');
        
        if elbowSign == 0
            % Dirsek konfig�rasyonuna g�re dirsekSign
            elbowSign=-1;
        end
        % Teta1 & theta3'teki sqrt terimi + veya - olabilece�inden,
        % t�m olas� kombinasyonlardan (i = 4) ge�iyor ve ortak a�� 
        %k�s�tlamalar�na uygun olan ilk kombinasyonu al�yoruz....
        while nogo == 0;
            for i = 1:1:4
                if i == 1
                    sign1 = -elbowSign;
                    sign2 = -elbowSign;
                elseif i == 2
                    sign1 = -elbowSign;
                    sign2 = elbowSign;
                elseif i == 3
                    sign1 = elbowSign;
                    sign2 = -elbowSign;
                else
                    sign1 = elbowSign;
                    sign2 = elbowSign;
                end
                
                r11 = R11;
                r21 = R21;
                r31 = R31;
                r13 = R13; 
                r23 = R23; 
                r33 = R33;
                %rho = sqrt (Px ^ 2 + Py ^ 2);
                % phi = atan2 (Py, Px); 
                % atan2, 2pi, -2pi aras�ndaki a��lar� d�nd�r�r
                K = (Px^2+Py^2+Pz^2-a2^2-a3^2-d3^2-d4^2)/(2*a2);
                    
                theta1 = (atan2(Py,Px)-atan2(d3,sign1*sqrt(Px^2+Py^2-d3^2)));
                c1 = cos(theta1);
                s1 = sin(theta1);
          
                theta3 = (atan2(a3,d4)-atan2(real(K),real(sign2*sqrt(a3^2+d4^2-K^2))));
                c3 = cos(theta3);
                s3 = sin(theta3);

                t23 = atan2((-a3-a2*c3)*Pz-(c1*Px+s1*Py)*(d4-a2*s3),(a2*s3-d4)*Pz+(a3+a2*c3)*(c1*Px+s1*Py));
                theta2 = (t23 - theta3);
                c2 = cos(theta2);
                s2 = sin(theta2);
                s23 = ((-a3-a2*c3)*Pz+(c1*Px+s1*Py)*(a2*s3-d4))/(Pz^2+(c1*Px+s1*Py)^2);
                c23 = ((a2*s3-d4)*Pz+(a3+a2*c3)*(c1*Px+s1*Py))/(Pz^2+(c1*Px+s1*Py)^2);
                
                theta4 = atan2(-r13*s1+r23*c1,-r13*c1*c23-r23*s1*c23 + r33*s23);
                c4 = cos(theta4);
                s4 = sin (theta4);
                
                s5 = -(r13*(c1*c23*c4+s1*s4)+r23*(s1*c23*c4-c1*s4)-r33*(s23*c4));
                c5 = r13*(-c1*s23)+r23*(-s1*s23)+r33*(-c23);
                theta5 = atan2(s5,c5);

                s6 = -r11*(c1*c23*s4-s1*c4)-r21*(s1*c23*s4+c1*c4)+r31*(s23*s4);
                c6 = r11*((c1*c23*c4+s1*s4)*c5-c1*s23*s5)+r21*((s1*c23*c4-c1*s4)*c5-s1*s23*s5)-r31*(s23*c4*c5+c23*s5);
                theta6 = atan2(s6,c6);

                % Radyandan dereceye
                theta1 = theta1*180/pi;
                theta2 = theta2*180/pi;
                theta3 = theta3*180/pi;
                theta4 = theta4*180/pi;
                theta5 = theta5*180/pi;
                theta6 = theta6*180/pi;
               
                if flipSign == 1
                    theta4= theta4+180;
                    theta5=-theta5;
                    theta6=theta6+180;
                end
                
                if theta2>=160 && theta2<=180
                  %  teta2 = -teta2;
                end
                
                %T�m a��lar�n mech i�inde olup olmad���n� kontrol edin. s�n�rlama.
                %Evet ise ��z�m kabul edilir.
                %                                    20 ile -200
                if theta1<=160 && theta1>=-160 && (theta2<=110 && theta2>=-110) && theta3<=45 && theta3>=-225 && theta4<=266 && theta4>=-266 && theta5<=100 && theta5>=-100 && theta6<=300 && theta6>=-300
                    nogo = 1;
                    theta3 = theta3+180;
                    
                    % a��lar�, hangisini istedi�inizi se�mek i�in birden fazla
                    % gruba (t�m ��z�mler) d�nmek i�in kullan�labilir.
                    angles = [angles; theta1-90,theta2+90,theta3+90,theta4,theta5,theta6];
                    
                    break
                end
                
                
                if i == 4 && nogo == 0
                    %h = errordlg ('Eklem a��s� k�s�tlamalar� nedeniyle ula��lamayan nokta.', 'JOINT ERROR');
                     % BEKLE (h)
                    nogo = 1;
                    noplot = 1;
                        break
                end
                
            end
        end
    end

% Bu fonksiyon kinematik problemleri ��zmek i�in gerekli olan d�n���m matrisini hesaplar.
    function T = tmat(alpha, a, d, theta)
        % tmat (alfa, a, d, theta) (Robotikte kullan�lan T-Matrix) Robotik
        % sistemlerde (veya e�de�erde) Kinematik Denklemlerde kullan�lan
        % "T-MATRIX" denilen homojen d�n���m....
        %
        % Craig'in "Robotiklere Giri�" deki denklem 3.6'd�r.
        % alpha, a, d, theta, Denavit-Hartenberg parametreleridir.
        %
        % (NOTE: T�M A�ILAR DERECEDE OLMALIDIR.)
        %
        alpha = alpha*pi/180;    %Not: Teta radyanda.
        theta = theta*pi/180;    %Not: Teta radyanda.
        c = cos(theta);
        s = sin(theta);
        ca = cos(alpha);
        sa = sin(alpha);
        T = [c -s 0 a; s*ca c*ca -sa -sa*d; s*sa c*sa ca ca*d; 0 0 0 1];
    end

%% uibutton: Uicontrol'den daha esnek etiketleme ile d��me olu�turun.
    function [hout,ax_out] = uibutton(varargin)
        %uibutton: Uicontrol'den daha esnek etiketleme ile basma d��mesi olu�turun.
        % Usage:
        %   uibutton, a�a��daki �zellik de�i�ikli�i haricinde, 
        %  uicontrol ile ayn� arg�manlar� kabul eders:
        %
        %     Property      Values
        %     -----------   ------------------------------------------------------
        %     Style         'pushbutton', 'togglebutton' or 'text', default =
        %                   'pushbutton'.
        %
        %     String        Metin dizileri ve TeX veya LaTeX yorumlar�n�n h�cre 
        %                   dizisi de dahil olmak �zere.
        %
        %     Interpreter  'tex', 'lateks' veya 'none', varsay�lan = metin i�in varsay�lan ()
        %
        % Syntax:
        %   handle = uibutton('PropertyName',PropertyValue,...)
        %   handle = uibutton(parent,'PropertyName',PropertyValue,...)
        %   [text_obj,axes_handle] = uibutton('Style','text',...
        %       'PropertyName',PropertyValue,...)
        %
        % uibutton, g�r�nt�lenecek metni i�eren ge�ici bir eksen ve metin
        % nesnesi olu�turur, eksenleri bir g�r�nt� olarak yakalar, eksenleri
        % siler ve daha sonra g�r�nt�y� uicontrol �zerinde g�r�nt�ler. 
        % Uicontrol i�leminin tan�t�c�s� iade edilir. 
        % �lk arg�man olarak mevcut bir uicontol tutamac�n� iletirseniz,
         %uibutton bu uicontrol� kullan�r ve yeni bir tane olu�turmaz.
        %
        % Stil 'metin' olarak ayarlanm��sa, eksen nesnesi silinmez ve
        % metin nesne tan�t�c�s� d�nd�r�l�r (ayr�ca ikinci bir ��k�� arg�man�
        % i�indeki eksenlerin tutama��).
        % 
        % Ayr�ca UICONTROL'e bak�n�z.
        %
        % Version: 1.6, 20 April 2006
        % Author:  Douglas M. Schwarz
        % Email:   dmschwarz=ieee*org, dmschwarz=urgrad*rochester*edu
        % Real_email = regexprep(Email,{'=','*'},{'@','.'})


        % �lk arg�man�n bir uicontrol kolu olup olmad���n� alg�la.
        keep_handle = false;
        if nargin > 0
            h = varargin{1};
            if isscalar(h) && ishandle(h) && strcmp(get(h,'Type'),'uicontrol')
                keep_handle = true;
                varargin(1) = [];
            end
        end

        % 'Yorumlay�c�' �zelli�ini arayan ayr��t�rma arg�manlar�.
        %Bulunursa, de�erini not edin ve bulundu�unuz yerden kald�r�n.
        interp_value = get(0,'DefaultTextInterpreter');
        arg = 1;
        remove = [];
        while arg <= length(varargin)
            v = varargin{arg};
            if isstruct(v)
                fn = fieldnames(v);
                for i = 1:length(fn)
                    if strncmpi(fn{i},'interpreter',length(fn{i}))
                        interp_value = v.(fn{i});
                        v = rmfield(v,fn{i});
                    end
                end
                varargin{arg} = v;
                arg = arg + 1;
            elseif ischar(v)
                if strncmpi(v,'interpreter',length(v))
                    interp_value = varargin{arg+1};
                    remove = [remove,arg,arg+1];
                end
                arg = arg + 2;
            elseif arg == 1 && isscalar(v) && ishandle(v) && ...
                    any(strcmp(get(h,'Type'),{'figure','uipanel'}))
                arg = arg + 1;
            else
                error('Invalid property or uicontrol parent.')
            end
        end
        varargin(remove) = [];

        % Uicontrol olu�turun, �zelliklerini al�n ve gizleyin.
        if keep_handle
            set(h,varargin{:})
        else
            h = uicontrol(varargin{:});
        end
        s = get(h);
        if ~any(strcmp(s.Style,{'pushbutton','togglebutton','text'}))
            delete(h)
            error('''Style'' must be pushbutton, togglebutton or text.')
        end
        set(h,'Visible','off')

        % Eksenler olu�turun.
        parent = get(h,'Parent');
        ax = axes('Parent',parent,...
            'Units',s.Units,...
            'Position',s.Position,...
            'XTick',[],'YTick',[],...
            'XColor',s.BackgroundColor,...
            'YColor',s.BackgroundColor,...
            'Box','on',...
            'Color',s.BackgroundColor);
        % En iyi g�r�n�m i�in eksenlerin boyutunu ayarlay�n.
        set(ax,'Units','pixels')
        pos = round(get(ax,'Position'));
        if strcmp(s.Style,'text')
            set(ax,'Position',pos + [0 1 -1 -1])
        else
            set(ax,'Position',pos + [4 4 -8 -8])
        end
        switch s.HorizontalAlignment
            case 'left'
                x = 0.0;
            case 'center'
                x = 0.5;
            case 'right'
                x = 1;
        end
        % Create text object.
        text_obj = text('Parent',ax,...
            'Position',[x,0.5],...
            'String',s.String,...
            'Interpreter',interp_value,...
            'HorizontalAlignment',s.HorizontalAlignment,...
            'VerticalAlignment','middle',...
            'FontName',s.FontName,...
            'FontSize',s.FontSize,...
            'FontAngle',s.FontAngle,...
            'FontWeight',s.FontWeight,...
            'Color',s.ForegroundColor);

        % Bir metin uicontrol gibi g�r�nen bir �ey yarat�yorsak,
        %hepimiz bitti ve biz bir uicontrol tutamac�ndan ziyade
        %metin nesnesini ve eksenleri d�nd�r�yoruz.
        if strcmp(s.Style,'text')
            delete(h)
            if nargout
                hout = text_obj;
                ax_out = ax;
            end
            return
        end

        % Eksenleri yakalay�n ve ard�ndan eksenleri silin.
        frame = getframe(ax);
        delete(ax)

        % RGB g�r�nt�s� olu�turun, arka plan piksellerini NaN olarak ayarlay�n
        %ve uicontrol i�in 'CData'ya yerle�tirin.
        if isempty(frame.colormap)
            rgb = frame.cdata;
        else
            rgb = reshape(frame.colormap(frame.cdata,:),[pos([4,3]),3]);
        end
        size_rgb = size(rgb);
        rgb = double(rgb)/255;
        back = repmat(permute(s.BackgroundColor,[1 3 2]),size_rgb(1:2));
        isback = all(rgb == back,3);
        rgb(repmat(isback,[1 1 3])) = NaN;
        set(h,'CData',rgb,'String','','Visible',s.Visible)

        % Gerekiyorsa ��kt� arg�man�n� atay�n.
        if nargout
            hout = h;
        end

    end
end
% En sonunda bitti.