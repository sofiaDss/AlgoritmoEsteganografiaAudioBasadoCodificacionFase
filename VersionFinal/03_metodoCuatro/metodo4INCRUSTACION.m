%{
    Método #4. Modificación de bandas de frecuencia continuas
    Contiene Tx y Rx.
    Se generan los archivos .wav en Tx y se leen en Rx
    Incrustacción iterativa: multiples audios portada y audios secreto
%}

clear all, close all, clc;
      
numRegistros=250;
archivosTable=string(zeros(numRegistros,1));
nlsbB1Table=zeros(numRegistros,1);
nlsbB2Table=zeros(numRegistros,1);
nlsbB3Table=zeros(numRegistros,1);
nlsbB4Table=zeros(numRegistros,1);
nlsbB5Table=zeros(numRegistros,1);
fsTable=zeros(numRegistros,1);

bitsIncrusTable=zeros(numRegistros,1);
fssTable=zeros(numRegistros,1);
berTable=zeros(numRegistros,1);
snrTable=zeros(numRegistros,1);
nmseTable=zeros(numRegistros,1);
ssimTable=zeros(numRegistros,1);
peaqOdgTable=zeros(numRegistros,1);

carpetasP = dir('../Portada/*');      %ubicación de los audios portada por genero
carpetasP = carpetasP(3:end);          %retira carpetas innecesarias
archivosS = dir('../Secreto/*.mp3');   %ubicación de los audios secretos

iter=1;
for i = 1:length(carpetasP)         %iteración por cada carpeta de audios Portada
   archivosP = dir(sprintf('../Portada/%s/*.mp3', carpetasP(i).name));

%    for j = 1:1 
   for j = 1:length(archivosP)     %iteración por los arhivos de audio de la carpeta
        nombre_portada = archivosP(j).name;

        for k=1:length(archivosS) 
%         for duracionAudioSecreto=1:2:16 
            duracionAudioSecreto=7;
            nombre_secreto = archivosS(k).name;

            %------------------- TRANSMISOR
            [ruta_stego,n_lsb_Bn,Bn,svLim,minS,maxS,SNR,NMSE,SSIM,PEAQodg]=TransmisorM4(...
                sprintf('../Portada/%s/%s',carpetasP(i).name,nombre_portada),...
                nombre_portada(1:end-4), ...
                sprintf('../Secreto/%s', nombre_secreto), ...
                nombre_secreto(1:end-4), ...
                duracionAudioSecreto, ...
                sprintf('Stego/%s',carpetasP(i).name)...
                );

            %Parámetros
            Ts=length(svLim);

            %------------------- RECEPTOR
            [ruta_secreto,svr] = ReceptorM4(...
                ruta_stego,...
                Ts,...
                n_lsb_Bn,...
                Bn,...
                minS,...
                maxS,...
                sprintf('ResultadoSecreto/'),...
                sprintf('%s_%s_Rx',nombre_portada(1:end-4),nombre_secreto(1:end-4))...
                );
            
            %----------- MÉTICAS
            %BER
            [numE,BER] = biterr(svLim,svr);

            archivosTable(iter,:)=sprintf('%s_lsb%d%d%d%d%d_%s.wav',nombre_portada(1:end-4),n_lsb_Bn(1),n_lsb_Bn(2),n_lsb_Bn(3),n_lsb_Bn(4),n_lsb_Bn(5),nombre_secreto(1:end-4));
            nlsbB1Table(iter,:)=n_lsb_Bn(1);
            nlsbB2Table(iter,:)=n_lsb_Bn(2);
            nlsbB3Table(iter,:)=n_lsb_Bn(3);
            nlsbB4Table(iter,:)=n_lsb_Bn(4);
            nlsbB5Table(iter,:)=n_lsb_Bn(5);
            fsTable(iter,:)=44100;
            bitsIncrusTable(iter,:)=Ts;
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

T=table(archivosTable,fsTable,nlsbB1Table,nlsbB2Table,nlsbB3Table,nlsbB4Table,nlsbB5Table,bitsIncrusTable,fssTable,berTable,snrTable,nmseTable,ssimTable,peaqOdgTable);
T.Properties.VariableNames={'Archivo', 'Fs','n_lsb1','n_lsb2','n_lsb3','n_lsb4','n_lsb5', 'bitsIncrustados','Fss','BER', 'SNR','NMSE','SSIM','PEAQ-ODG'};
writetable(T,'../informeIncrustacion.xlsx','sheet','Metodo4','Range','A2');

disp('PROCESO CONCLUIDO');
%as=audioplayer(xs,Fs); 
