%{
    Método #2. Modificación de muestras alternadas del espectro de fase
    Contiene Tx y Rx.
    Se generan los archivos .wav en Tx y se leen en Rx
%}

clear all, close all, clc

res=8;     %resolución en cuantificación y codificación
Fsi=44100; %Frecuencia estándar para los audios portada

archivosTable=string(zeros(160,1));
nlsbTable=zeros(160,1);
fsTable=zeros(160,1);
bitsIncrusTable=zeros(160,1);
fssTable=zeros(160,1);
berTable=zeros(160,1);
snrTable=zeros(160,1);

carpetasP = dir('Portada/*');       %ubicación de los audios portada por genero
carpetasP = carpetasP(3:end);       %retira carpetas innecesarias
archivosS = dir('Secreto/*.mp3');   %ubicación de los audios secretos

iter=1;
for i = 1:length(carpetasP)         %iteración por cada carpeta de audios Portada
   archivosP = dir(strcat('Portada/',carpetasP(i).name,'/*.mp3'));
   
%     for j = 3:3 
    for j = 1:length(archivosP)     %iteración por los arhivos de audio de la carpeta
        nombre_portada = archivosP(j).name;

        %-------------- TRANSMISOR
        %lectura de Audio Portada
        [xc,Fs] = audioread(fullfile('Portada',carpetasP(i).name,nombre_portada));
        x = 0.5*(xc(:,1)+xc(:,2));
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
          
        [Xppm, Mxcuan, Mxc_E]=CuanCod(Xpp,res,-pi,pi);
          
        for k = 1:length(archivosS)   %iteración por cada archivo de audio secreto
            Xppms=Xppm;
            nombre_secreto = archivosS(k).name;
               
            %lectura del audio secreto
            [sc,Fss] = audioread(fullfile('Secreto',nombre_secreto));
            s=0.5*(sc(:,1)+sc(:,2));
            s=s(20*Fs:28*Fs);            %Obtención del fragmento de la canción
            s=s';

            [sm, Mscuan, Msc_E]=CuanCod(s,res,min(s),max(s));
            sv=reshape(sm,1,[]);
            n_lsb=ceil(round((4*length(sv))/length(x),2));
            if n_lsb>res-1
                n_lsb=res-1;
            end
                
            %Incrustación 
            NumColMod=floor(length(Xppms)/2);
            if rem(length(sv),n_lsb) ~= 0
                sv=sv(:,1:end-rem(length(sv),n_lsb));
            end
            svLim=reshape(sv,n_lsb,[]);

            if length(svLim)>NumColMod
                svLim=svLim(:,1:NumColMod);
            end

            n=1;
            for h=length(Xppms)-(length(svLim)*2)+1:2:length(Xppms)
              Xppms(res-n_lsb+1:res,h)=svLim(:,n);
              n=n+1;
            end
            Ts=length(svLim)*n_lsb;
            Ls=length(svLim);
        
            %construcción del audio stego
            Xpps=DeCod(Xppms,res,Mxcuan, Mxc_E);   
            Xps=[fliplr(-1*Xpps) 0 Xpps]; 
            Xs=Xm.*exp(1i*Xps);         
            
            xs=fftshift(ifft(ifftshift(Xs)));
             
            nombre_stego=sprintf('%s_lsb%d_%s.wav',nombre_portada(1:end-4),n_lsb,nombre_secreto(1:end-4));
            ruta_stego=sprintf('Stego/metodo2/%s/%s',carpetasP(i).name,nombre_stego);
            audiowrite(ruta_stego,xs,Fs,'BitsPerSample',32);

            %------------------- RECEPTOR
            [y,Fsr] = audioread(ruta_stego);
            y = y';
        
            Y=fftshift(fft(ifftshift(y)));
            Ym=abs(Y);                    
            Yp=angle(Y); 
            Ypp=Yp(f>0);
            [Yppm, ~, ~]=CuanCod(Ypp,res,-pi,pi);

            %Extracción
            n=1;
            svr=zeros(n_lsb,Ls);
            for g=length(Yppm)-(Ls*2)+1:2:length(Yppm)
                svr(:,n)=Yppm(res-n_lsb+1:res,g);
                n=n+1;
            end
        
            svrTa=reshape(svr,1,[]);
            if rem(length(svrTa),res)~=0
                svrT=[svrTa zeros(1,res-rem(length(svrTa),res))];  %Adiciona ceros para completar las muestras a la resolución usada.
            else
                svrT=svrTa;
            end
            smr=reshape(svrT,res,[]);
            secret = DeCod(smr,res,Mscuan,Msc_E);
     
            nombre_recuperado=sprintf('%s_lsb%d_%s_Rx.wav',nombre_portada(1:end-4),n_lsb,nombre_secreto(1:end-4));
            ruta_resultado=sprintf('ResultadoSecreto/metodo2/%s',nombre_recuperado);
            audiowrite(ruta_resultado,secret,Fss,'BitsPerSample',32);


            %----------- MÉTICAS
            %BER
            [numE,BER] = biterr(svLim,svr);
    
            %métrica SNR
            xs=double(xs);
            Pxn=sum(x.^2)/length(x); 
            Pn=sum((x-xs).^2)/length(x);  
            SNR=10*log10(Pxn/Pn);

            clear xs;
            clear svr;
            archivosTable(iter,:)=nombre_stego;
            nlsbTable(iter,:)=n_lsb;
            fsTable(iter,:)=Fs;
            bitsIncrusTable(iter,:)=length(sv);
            fssTable(iter,:)=Fss;
            berTable(iter,:)=BER;
            snrTable(iter,:)=SNR;
            iter=iter+1
        end
    end
end

T=table(archivosTable,fsTable,nlsbTable,bitsIncrusTable,fssTable,berTable,snrTable);
T.Properties.VariableNames={'Archivo', 'Fs','n_lsb', 'bitsIncrustados','Fss','BER', 'SNR'};
writetable(T,'informe.xlsx','sheet','Metodo2','Range','A2');

%as=audioplayer(xs,Fs); 

% tiempoPortada=50;
% tiempoSecreto=(tiempoPortada*48000)/(41100*4)
   