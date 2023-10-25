%{
    Método #1 Temporal. Modificación de todas las muestras en dominio temporal
    Contiene Tx y Rx.
    Se generan los archivos .wav en Tx y se leen en Rx
%}

clear all, close all, clc;
      
numRegistros=240;
archivosTable=string(zeros(numRegistros,1));
nlsbTable=zeros(numRegistros,1);
fsTable=zeros(numRegistros,1);
bitsIncrusTable=zeros(numRegistros,1);
fssTable=zeros(numRegistros,1);
berTable=zeros(numRegistros,1);
snrTable=zeros(numRegistros,1);
nmseTable=zeros(numRegistros,1);
ssimTable=zeros(numRegistros,1);
peaqOdgTable=zeros(numRegistros,1);

carpetasP = dir('../Portada/*');       %ubicación de los audios portada por genero
carpetasP = carpetasP(3:end);           %retira carpetas innecesarias
archivosS = dir('../Secreto/*.mp3');    %ubicación de los audios secretos

iter=1;
for i = 1:length(carpetasP)             %iteración por cada carpeta de audios Portada
   archivosP = dir(sprintf('../Portada/%s/*.mp3', carpetasP(i).name));

   for j = 1:length(archivosP)          %iteración por los arhivos de audio de la carpeta
        nombre_portada = archivosP(j).name;

        for k=1:length(archivosS) 
%         for duracionAudioSecreto=1:2:16 
            duracionAudioSecreto=7;
            nombre_secreto = archivosS(k).name;

            %------------------- TRANSMISOR
            [ruta_stego,n_lsb,svLim,minS,maxS,minX,maxX,SNR,NMSE,SSIM,PEAQodg]=TransmisorM1Temporal(...
                sprintf('../Portada/%s/%s',carpetasP(i).name,nombre_portada),...
                nombre_portada(1:end-4), ...
                sprintf('../Secreto/%s', nombre_secreto), ...
                nombre_secreto(1:end-4), ...
                duracionAudioSecreto,...
                sprintf('Stego/%s',carpetasP(i).name)...
                );

            %Parámetros
            Ls=length(svLim);

            %------------------- RECEPTOR
            [ruta_secreto,svr] = ReceptorM1Temporal(...
                ruta_stego,...
                Ls,...
                n_lsb,...
                minS,...
                maxS,...
                minX,...
                maxX,...
                sprintf('ResultadoSecreto/'),...
                sprintf('%s_%s_Rx',nombre_portada(1:end-4),nombre_secreto(1:end-4))...
                );
            
            %----------- MÉTICAS
            %BER
            [numE,BER] = biterr(svLim,svr);

            archivosTable(iter,:)=sprintf('%s_lsb%d_%s.wav',nombre_portada(1:end-4),n_lsb,nombre_secreto(1:end-4));
            nlsbTable(iter,:)=n_lsb;
            fsTable(iter,:)=44100;
            bitsIncrusTable(iter,:)=Ls*n_lsb;
            fssTable(iter,:)=48000;
            berTable(iter,:)=BER;
            snrTable(iter,:)=SNR;
            nmseTable(iter,:)=NMSE;
            ssimTable(iter,:)=SSIM;
            peaqOdgTable(iter,:)=PEAQodg;
            iter=iter+1;
        end
    end
end

T=table(archivosTable,fsTable,nlsbTable,bitsIncrusTable,fssTable,berTable,snrTable,nmseTable,ssimTable,peaqOdgTable);
T.Properties.VariableNames={'Archivo', 'Fs','n_lsb', 'bitsIncrustados','Fss','BER', 'SNR','NMSE','SSIM','PEAQ-ODG'};
writetable(T,'../informeIncrustacion.xlsx','sheet','Metodo1Temporal','Range','A2');

disp('PROCESO CONCLUIDO');
%as=audioplayer(xs,Fs); 

   