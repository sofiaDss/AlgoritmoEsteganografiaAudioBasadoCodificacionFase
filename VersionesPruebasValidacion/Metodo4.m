%{
    Método #4. Modificación de bandas de frecuencia consecutivas del espectro de fase
    Contiene Tx y Rx.
    Se generan los archivos .wav en Tx y se leen en Rx
%}

clear all, close all, clc

res=8;     %resolución en cuantificación y codificación
Fsi=44100; %Frecuencia estándar para los audios portada

archivosTable=string(zeros(160,1));
nlsbB1Table=zeros(160,1);
nlsbB2Table=zeros(160,1);
nlsbB3Table=zeros(160,1);
nlsbB4Table=zeros(160,1);
nlsbB5Table=zeros(160,1);
fsTable=zeros(160,1);
bitsIncrusTable=zeros(160,1);
fssTable=zeros(160,1);
berTable=zeros(160,1);
snrTable=zeros(160,1);
Bk=[0.4, 0.2, 0.3, 0.6, 0.8];       %no deben superar el 100%-> 1

carpetasP = dir('Portada/*');       %ubicación de los audios portada por genero
carpetasP = carpetasP(3:end);       %retira carpetas innecesarias
% carpetasP = carpetasP(6:6);       %retira carpetas innecesarias (PRUEBA RÁPIDA)
archivosS = dir('Secreto/*.mp3');   %ubicación de los audios secretos

iter=1;
for i = 1:length(carpetasP)         %iteración por cada carpeta de audios Portada
   archivosP = dir(strcat('Portada/',carpetasP(i).name,'/*.mp3'));

%    for j = 3:3
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
        x=x(10*Fs:60*Fs);           %Obtención del fragmento de la canción
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
           s=s(20*Fs:28*Fs);          %Obtención del fragmento de la canción
           s=s';

           [sm, Mscuan, Msc_E]=CuanCod(s,res,min(s),max(s));
           sv=reshape(sm,1,[]);

           %Bandas
           LimI_B1=0;
           LimS_B1=find(fp<=1000,1,'last');
           LimI_B2=LimS_B1+1; 
           LimS_B2=find((fp<=2000 & fp>1000),1,'last');  
           LimI_B3=LimS_B2+1;
           LimS_B3=find((fp<=5000 & fp>2000),1,'last'); 
           LimI_B4=LimS_B3+1;
           LimS_B4=find((fp<=7000 & fp>5000),1,'last');
           LimI_B5=LimS_B4+1;
           LimS_B5=length(fp);

           n_lsb_B1=ceil(Bk(1)*(res-1));
           n_lsb_B2=ceil(Bk(2)*(res-1));
           n_lsb_B3=ceil(Bk(3)*(res-1));
           n_lsb_B4=ceil(Bk(4)*(res-1));
           n_lsb_B5=ceil(Bk(5)*(res-1));

           if rem(length(sv),lcm(lcm(lcm(lcm(n_lsb_B1,n_lsb_B2),n_lsb_B3),n_lsb_B4),n_lsb_B5)) ~= 0
                sv=sv(:,1:end-rem(length(sv),lcm(lcm(lcm(lcm(n_lsb_B1,n_lsb_B2),n_lsb_B3),n_lsb_B4),n_lsb_B5)));
           end

           Numb_B1=n_lsb_B1*(LimS_B1-LimI_B1);
           Numb_B2=n_lsb_B2*(LimS_B2-LimI_B2);
           Numb_B3=n_lsb_B3*(LimS_B3-LimI_B3);
           Numb_B4=n_lsb_B4*(LimS_B4-LimI_B4);
           Numb_B5=n_lsb_B5*(LimS_B5-LimI_B5);

           while Numb_B1+Numb_B2+Numb_B3+Numb_B4+Numb_B5>length(sv)
               if Numb_B1>0
                  Numb_B1=Numb_B1-n_lsb_B1;
               elseif Numb_B2>0
                   Numb_B2=Numb_B2-n_lsb_B2;
               elseif Numb_B3>0
                   Numb_B3=Numb_B3-n_lsb_B3;
               elseif Numb_B4>0
                   Numb_B4=Numb_B4-n_lsb_B4;
               else
                   Numb_B5=Numb_B5-n_lsb_B5;
               end
           end

           %Incrustacion
           svLim=sv(1:Numb_B1+Numb_B2+Numb_B3+Numb_B4+Numb_B5);
           Ts=length(svLim);
           sv_B5=svLim(1,Numb_B1+Numb_B2+Numb_B3+Numb_B4+1:end);
           sv2_B5=reshape(sv_B5,n_lsb_B5,[]);
           Xppms(res-n_lsb_B5+1:res,end-length(sv2_B5)+1:end)=sv2_B5;

           if Numb_B4>0
               sv_B4=svLim(1,Numb_B1+Numb_B2+Numb_B3+1:Numb_B1+Numb_B2+Numb_B3+Numb_B4);
               sv2_B4=reshape(sv_B4,n_lsb_B4,[]);
               Xppms(res-n_lsb_B4+1:res,LimS_B4-length(sv2_B4)+1:LimS_B4)=sv2_B4;
           end

           if Numb_B3>0
               sv_B3=svLim(1,Numb_B1+Numb_B2+1:Numb_B1+Numb_B2+Numb_B3);
               sv2_B3=reshape(sv_B3,n_lsb_B3,[]);
               Xppms(res-n_lsb_B3+1:res,LimS_B3-length(sv2_B3)+1:LimS_B3)=sv2_B3;
           end

           if Numb_B2>0
               sv_B2=svLim(1,Numb_B1+1:Numb_B1+Numb_B2);
               sv2_B2=reshape(sv_B2,n_lsb_B2,[]);
               Xppms(res-n_lsb_B2+1:res,LimS_B2-length(sv2_B2)+1:LimS_B2)=sv2_B2;
           end

           if Numb_B1>0
               sv_B1=svLim(1,1:Numb_B1);
               sv2_B1=reshape(sv_B1,n_lsb_B1,[]); 
               Xppms(res-n_lsb_B1+1:res,LimS_B1-length(sv2_B1)+1:LimS_B1)=sv2_B1;
           end
       
           Xpps=DeCod(Xppms,res,Mxcuan, Mxc_E);   
           Xps=[fliplr(-1*Xpps) 0 Xpps]; 
           Xs=Xm.*exp(1i*Xps);          
           xs=fftshift(ifft(ifftshift(Xs)));
        
           nombre_stego=sprintf('%s_lsb%d%d%d%d%d_%s.wav',nombre_portada(1:end-4),n_lsb_B1,n_lsb_B2,n_lsb_B3,n_lsb_B4,n_lsb_B5,nombre_secreto(1:end-4));
           ruta_stego=sprintf('Stego/metodo4/%s/%s',carpetasP(i).name,nombre_stego);
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
           Numb_B1=n_lsb_B1*(LimS_B1-LimI_B1);
           Numb_B2=n_lsb_B2*(LimS_B2-LimI_B2);
           Numb_B3=n_lsb_B3*(LimS_B3-LimI_B3);
           Numb_B4=n_lsb_B4*(LimS_B4-LimI_B4);
           Numb_B5=n_lsb_B5*(LimS_B5-LimI_B5);

            while Numb_B1+Numb_B2+Numb_B3+Numb_B4+Numb_B5>Ts
               if Numb_B1>0
                   Numb_B1=Numb_B1-n_lsb_B1;
               elseif Numb_B2>0
                   Numb_B2=Numb_B2-n_lsb_B2;
               elseif Numb_B3>0
                   Numb_B3=Numb_B3-n_lsb_B3;
               elseif Numb_B4>0
                   Numb_B4=Numb_B4-n_lsb_B4;
               else
                   Numb_B5=Numb_B5-n_lsb_B5;
               end
            end
            
           Ts_B5=Numb_B5/n_lsb_B5;
           svr_B5=Yppm(res-n_lsb_B5+1:res,end-Ts_B5+1:end);
           svr=reshape(svr_B5,1,[]);

           if Numb_B4>0
               Ts_B4=Numb_B4/n_lsb_B4;
               svr_B4=Yppm(res-n_lsb_B4+1:res,LimS_B4-Ts_B4+1:LimS_B4);
               svr=[reshape(svr_B4,1,[]) svr];
           end

           if Numb_B3>0
               Ts_B3=Numb_B3/n_lsb_B3;
               svr_B3=Yppm(res-n_lsb_B3+1:res,LimS_B3-Ts_B3+1:LimS_B3);
               svr=[reshape(svr_B3,1,[]) svr];
           end

           if Numb_B2>0
               Ts_B2=Numb_B2/n_lsb_B2;
               svr_B2=Yppm(res-n_lsb_B2+1:res,LimS_B2-Ts_B2+1:LimS_B2);
               svr=[reshape(svr_B2,1,[]) svr];
           end

           if Numb_B1>0
               Ts_B1=Numb_B1/n_lsb_B1;
               svr_B1=Yppm(res-n_lsb_B1+1:res,LimS_B1-Ts_B1+1:LimS_B1);
               svr=[reshape(svr_B1,1,[]) svr];
           end

           svrT=reshape(svr,1,[]);
           if rem(length(svrT),res)~=0
                svrT=svrT(1:end-(rem(length(svrT),res)));  %Adiciona ceros para completar las muestras a la resolución usada.
           end
           smr=reshape(svrT,res,[]);
           secret = DeCod(smr,res,Mscuan,Msc_E);

           nombre_recuperado=sprintf('%s_lsb%d%d%d%d%d_%s_Rx.wav',nombre_portada(1:end-4),n_lsb_B1,n_lsb_B2,n_lsb_B3,n_lsb_B4,n_lsb_B5,nombre_secreto(1:end-4));
           ruta_resultado=sprintf('ResultadoSecreto/metodo4/%s',nombre_recuperado);
           audiowrite(ruta_resultado,secret,Fss,'BitsPerSample',32);


            %----------- MÉTICAS
           %BER
           [numE,BER] = biterr(svLim,svrT);
    
           %métrica SNR
           xs=double(xs);
           Pxn=sum(x.^2)/length(x);  
           Pn=sum((x-xs).^2)/length(x);
           SNR=10*log10(Pxn/Pn);

           clear xs;
           clear svrT;
           archivosTable(iter,:)=nombre_stego;
           nlsbB1Table(iter,:)=n_lsb_B1;
           nlsbB2Table(iter,:)=n_lsb_B2;
           nlsbB3Table(iter,:)=n_lsb_B3;
           nlsbB4Table(iter,:)=n_lsb_B4;
           nlsbB5Table(iter,:)=n_lsb_B5;
           fsTable(iter,:)=Fs;
           bitsIncrusTable(iter,:)=Ts;
           fssTable(iter,:)=Fss;
           berTable(iter,:)=BER;
           snrTable(iter,:)=SNR;
           iter=iter+1
        end
    end
end

T=table(archivosTable,fsTable,nlsbB1Table,nlsbB2Table,nlsbB3Table,nlsbB4Table,nlsbB5Table,bitsIncrusTable,fssTable,berTable,snrTable);
T.Properties.VariableNames={'Archivo', 'Fs','n_lsb1','n_lsb2','n_lsb3', 'n_lsb4', 'n_lsb5','bitsIncrustados','Fss','BER', 'SNR'};
writetable(T,'informe.xlsx','sheet','Metodo4','Range','A2');

%as=audioplayer(xs,Fs); 

% tiempoPortada=50;
% tiempoSecreto=((tiempoPortada*7)/(8*48000))*((1000*(0.4-0.2))+(2000*(0.2-0.3))+(5000*(0.3-0.6))+(7000*(0.6-0.8))+(22000*0.8))     