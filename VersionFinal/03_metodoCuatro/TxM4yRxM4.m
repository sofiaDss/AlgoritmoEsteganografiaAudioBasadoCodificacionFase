%{
    Método #4. Modificación de bandas de frecuencia continuas
    Contiene Tx y Rx.
    Se generan los archivos .wav en Tx y se leen en Rx
%}

clear all, close all, clc;

carpetaP='clasica';
nombre_portada='nombreAudioPortada.mp3';
nombre_secreto='nombreAudioSecreto.mp3';
duracionAudioSecreto=7;
      
%------------------- TRANSMISOR
[ruta_stego,n_lsb_Bn,Bn,svLim,minS,maxS,SNR,NMSE,SSIM,PEAQodg]=TransmisorM4(...
    sprintf('../Portada/%s/%s',carpetaP,nombre_portada),...
    nombre_portada(1:end-4), ...
    sprintf('../Secreto/%s', nombre_secreto), ...
    nombre_secreto(1:end-4), ...
    duracionAudioSecreto,...
    sprintf('Stego/%s',carpetaP)...
    );
disp("rutaEstego: "+ruta_stego);
disp("snr: "+SNR);
disp("nmse: "+NMSE);
disp("ssim: "+SSIM);
disp("odg: "+PEAQodg);

%Escritura archivo Clave 
datos={length(svLim); n_lsb_Bn; Bn; minS; maxS};
writecell(datos,'datos.txt');
disp('listo Tx')

clear all, close all

%------------------- RECEPTOR
%Lectura Archivo Clave 
datos=readcell('datos.txt');
Ts=cell2mat(datos(1,1));
n_lsb_Bn=cell2mat(datos(2,1:5));
Bn=cell2mat(datos(3,:));
minS=cell2mat(datos(4,1));
maxS=cell2mat(datos(5,1));

ruta_stego=sprintf('carpeta1/carpeta2/nombreAudioStego.wav');
[ruta_secreto,svr] = ReceptorM4(...
    ruta_stego,...
    Ts,...
    n_lsb_Bn,...
    Bn,...
    minS,...
    maxS,...
    sprintf('ResultadoSecreto/'),...
    sprintf('Resultado_Rx')...
    );
disp('listo Rx') 

% %BER
% [numE,BER] = biterr(svLim,svr);