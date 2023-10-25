%{
    Método #1. Modificación de todas las muestras
    
    TRANSMISOR
    consideraciones: 
        1. Mismas Fs y Fss, obligatorias en Tx y Rx (no se envia)
        2. Misma res, obligatoria en Tx y Rx (no se envia)
        3. Número de LSB n_lsb (se envia)
        4. Número total de muestras incrustadas Ls (se envia)
        5. Límite inferior y superior de las regiones de cuantificación del
           audio secreto: minS y maxS  (se envia)
%}

function [Tx,n_lsb,svLim,minS,maxS,SNR,NMSE,SSIM,PEAQodg] = TransmisorM1(rutaPortada, nombrePortada, rutaSecreto, nombreSecreto, duracionAudioSecreto, rutaStego)

    %Atributos de Tx
    Fsi=44100;
    Fssi=48000;
    res=8;
    dirIncrustacion=0;         %dirección desde la cual se insertan los datos (inicio o fin del audio)
%    duracionAudioPortada=90;   %atributo para Pruebas
%    duracionAudioSecreto=8;    %atributo para Pruebas

    %Lectura del audio portada
    [xc,Fs] = audioread(rutaPortada);
    infoPortada=audioinfo(rutaPortada);
    x=sum(xc,2)/infoPortada.NumChannels;

    %Adecuación del audio portada
    if Fs~=Fsi
        x=resample(x,Fsi,Fs);
        Fs=Fsi;
    end    
%    x=x(10*Fs:(10+duracionAudioPortada)*Fs);   %atributo para Pruebas
    x=x';
    if rem(length(x),2) == 0        
        x = x(1,1:length(x)-1); 
    end

    %versión de comparación para PEAQ-ODG
    rutaWav=sprintf('../PortadaPEAQ/%s.wav',nombrePortada(1:end-4));
    audiowrite(rutaWav,x,Fs,'BitsPerSample',32);

    %FFT
    X=fftshift(fft(ifftshift(x)));   
    Xm=abs(X);

    %Espectro de fase positivo
    Xp=angle(X); 
    f=linspace(-0.5*Fs,0.5*Fs,numel(Xp));
    Xpp=Xp(f>0);
    
    %Cuantificación y codificación del espectro de fase
    Xppm=CuanCod(Xpp,res,-pi,pi);
    Xppms=Xppm;

    %Lectura del audio secreto
    [sc,Fss] = audioread(rutaSecreto);
    infoSecreto=audioinfo(rutaSecreto);
    s=sum(sc,2)/infoSecreto.NumChannels;

    if Fss~=Fssi
        s=resample(s,Fssi,Fss);
        Fss=Fssi;
    end   
    s=s(10*Fss:(10+duracionAudioSecreto)*Fss);   %atributo para Pruebas
    s=s';

    %Cuantificación y codificación del audio secreto
    minS=min(s);
    maxS=max(s);
    sm=CuanCod(s,res,minS,maxS);
    sv=reshape(sm,1,[]);

    %Número de LSB
    n_lsb=ceil(round((2*length(sv))/length(x),2));
    if n_lsb>res-1 
        n_lsb=res-1;
    end
   % disp(sprintf('nLSB: %d',n_lsb));

    %Incrustación 
    if rem(length(sv),n_lsb) ~= 0
        sv=sv(:,1:end-rem(length(sv),n_lsb));
    end
    svLim=reshape(sv,n_lsb,[]);
    if length(svLim)>length(Xppms)
        svLim=svLim(:,1:length(Xppms));
    end
    
    if dirIncrustacion==1
        Xppms(res-n_lsb+1:res,1:length(svLim))=svLim;
    else
        Xppms(res-n_lsb+1:res,end-(length(svLim)-1):end)=svLim;
    end
    
    %Construcción del audio stego
    Xpps=DeCod(Xppms,res,-pi,pi);   
    Xps=[fliplr(-1*Xpps) 0 Xpps];
    Xs=Xm.*exp(1i*Xps);         
    xs=fftshift(ifft(ifftshift(Xs)));
    nombreStego=sprintf('%s_lsb%d_%s.wav',nombrePortada,n_lsb,nombreSecreto);
    Tx=sprintf('%s/%s',rutaStego,nombreStego);
    audiowrite(Tx,xs,Fs,'BitsPerSample',32);

    %Métricas
    SNR=metricaSNR(double(xs),x);
    NMSE=metricaNMSE(double(xs),x);
    SSIM=ssim(xs,x);
    [PEAQodg, ~]=metricaPEAQ(Tx,rutaWav);
end
