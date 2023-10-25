%{
    Método #5. Modificación directa del espectro de fase
    Contiene Tx y Rx.
    Se generan los archivos .wav en Tx y se leen en Rx
%}

clear all, close all, clc;
      
res=8;     %resolución en cuantificación y codificación
Fsi=44100; %Frecuencia estándar para los audios portada

archivosTable=string(zeros(160,1));
fsTable=zeros(160,1);
fssTable=zeros(160,1);
snrTable=zeros(160,1);

carpetasP = dir('Portada/*');       %ubicación de los audios portada por genero
carpetasP = carpetasP(3:end);       %retira carpetas innecesarias
archivosS = dir('Secreto/*.mp3');   %ubicación de los audios secretos

iter=1;
for i = 1:length(carpetasP)         %iteración por cada carpeta de audios Portada
   archivosP = dir(strcat('Portada/',carpetasP(i).name,'/*.mp3'));

    for j = 1:length(archivosP)     %iteración por los arhivos de audio de la carpeta
        nombre_portada = archivosP(j).name;

        %-------------- TRANSMISOR
        %lectura de Audio Portada
        [xc,Fs] = audioread(fullfile('Portada',carpetasP(i).name,nombre_portada));
        x=0.5*(xc(:,1)+xc(:,2));
        if Fs~=Fsi
            x=resample(x,Fsi,Fs);
            Fs=Fsi;
        end
        x=x(10*Fs:60*Fs);            %Obtención del fragmento de la canción
        x=x';
        if rem(length(x),2) == 0        
            x = x(1,1:length(x)-1); 
        end

        X=fftshift(fft(ifftshift(x)));   
        Xm=abs(X);
        Xp=angle(X); 
        f=linspace(-0.5*Fs,0.5*Fs,numel(Xp));
        fp=f(f>0);
        Xpp=Xp(f>0);
       
%        for k=3:3 
       for k=1:length(archivosS) 
            nombre_secreto = archivosS(k).name;

            %lectura del audio secreto
            [sc,Fss] = audioread(fullfile('Secreto',nombre_secreto));
            s=0.5*(sc(:,1)+sc(:,2));
            s=s(20*Fs:28*Fs);                  %Obtención del fragmento de la canción
            s=s';

            %Incrustacion
            if length(s)>length(Xpp)/2
                sl=s(1:floor(length(Xpp)/2));  %Se limita el número de muestras a incrustar a 1/4 del tamaño total del audio portada
            else 
                sl=s;
            end 

            XppI=Xpp;
            for h=1:2:(length(sl)*2)-1          %Se igualan las muestras adyancentes, respecto a la de menor valor 
                XppI(h+1)=XppI(h);
            end
           XppI=XppI/2;                         %Se reduce la magnitud de las muestras a 1/2 (valor max=pi/2)    
           
           Xpps=XppI;
           n=1;
           for h=1:2:length(Xpps)-1
               Xpps(h+1)=Xpps(h+1)-sl(n);
               n=n+1;
                if n>length(sl)
                   break;
                end
           end   

           Xps=[fliplr(-1*Xpps) 0 Xpps];
           Xs=Xm.*exp(1i*Xps); 
           xs=fftshift(ifft(ifftshift(Xs)));
            
           nombre_stego=sprintf('%s_%s.wav',nombre_portada(1:end-4),nombre_secreto(1:end-4));
           ruta_stego=sprintf('Stego/metodo5/%s/%s',carpetasP(i).name,nombre_stego);
           audiowrite(ruta_stego,xs,Fs,'BitsPerSample',32);
           
           %------------------- RECEPTOR
           [y,Fsr] = audioread(ruta_stego);
           y = y';
           Y=fftshift(fft(ifftshift(y)));
           Ym=abs(Y);                    
           Yp=angle(Y); 
           Ypp=Yp(f>0);
    
           %extraccion
           sr=zeros(1,floor(length(sl)));
           n=1;
           for h=1:2:(length(sl)*2)-1 
             sr(n)=Ypp(h)-Ypp(h+1);
             n=n+1;
           end  
           secret=sr;

           nombre_recuperado=sprintf('%s_%s_Rx.wav',nombre_portada(1:end-4),nombre_secreto(1:end-4));
           ruta_resultado=sprintf('ResultadoSecreto/metodo5/%s',nombre_recuperado);
           audiowrite(ruta_resultado,secret,Fss,'BitsPerSample',32);

    
           %----------- MÉTICAS
           %métrica SNR
           xs=double(xs);
           Pxn=sum(x.^2)/length(x);  %Potencia del audio portada
           Pn=sum((x-xs).^2)/length(x);  %Potencia de ruido presente en el audio stego
           SNR=10*log10(Pxn/Pn);

           clear xs;
           archivosTable(iter,:)=nombre_stego;
           fsTable(iter,:)=Fs;
           fssTable(iter,:)=Fss;
           snrTable(iter,:)=SNR;
           iter=iter+1
        end
    end
end

T=table(archivosTable,fsTable,fssTable,snrTable);
T.Properties.VariableNames={'Archivo', 'Fs','Fss', 'SNR'};
writetable(T,'informe.xlsx','sheet','Metodo5','Range','A2');

%as=audioplayer(xs,Fs); 
 
         
  