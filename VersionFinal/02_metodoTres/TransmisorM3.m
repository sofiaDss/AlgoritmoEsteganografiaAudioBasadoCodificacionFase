%{
    Método #3. Modificación de bandas de frecuencia
    
    TRANSMISOR
    consideraciones: 
        1. Mismas Fs y Fss, obligatorias en Tx y Rx (no se envia)
        2. Misma res, obligatoria en Tx y Rx (no se envia)
        3. Número de LSB de cada banda n_lsb_Bn (se envia)
        4. Número total de bits incrustados Ts (se envia)
        5. Límite inferior y superior de las regiones de cuantificación del
           audio secreto: minS y maxS  (se envia)
%}

function [Tx,n_lsb_Bn,Bn,svLim,minS,maxS,SNR,NMSE,SSIM,PEAQodg] = TransmisorM3(rutaPortada, nombrePortada, rutaSecreto, nombreSecreto, duracionAudioSecreto, rutaStego)

    %Atributos de Tx
    Fsi=44100;
    Fssi=48000;
    res=8;
    dirIncrustacion=0;
    Bn=[0 200 500 800 10000 Fsi/2];
    Bk=[0.9, 0.5, 0.9];
%     duracionAudioPortada=90;   %atributo para Pruebas
%     duracionAudioSecreto=8;   %atributo para Pruebas

    %Lectura del audio portada
    [xc,Fs] = audioread(rutaPortada);
    infoPortada=audioinfo(rutaPortada);
    x=sum(xc,2)/infoPortada.NumChannels;

    %Adecuación del audio portada
    if Fs~=Fsi
        x=resample(x,Fsi,Fs);
        Fs=Fsi;
    end    
%     x=x(10*Fs:(10+duracionAudioPortada)*Fs);   %atributo para Pruebas
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
    fp=f(f>0);
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

    %Bandas
    LimI_B1=find((fp<=Bn(2) & fp>=Bn(1)),1,'first');
    LimS_B1=find((fp<=Bn(2) & fp>=Bn(1)),1,'last');
    LimI_B2=find((fp<=Bn(4) & fp>=Bn(3)),1,'first'); 
    LimS_B2=find((fp<=Bn(4) & fp>=Bn(3)),1,'last');   
    LimI_B3=find((fp<=Bn(6) & fp>=Bn(5)),1,'first'); 
    LimS_B3=find((fp<=Bn(6) & fp>=Bn(5)),1,'last');

    %Número de LSB
    n_lsb_Bn=[round(Bk(1)*(res-1)),...
              round(Bk(2)*(res-1)),...
              round(Bk(3)*(res-1)),...
    ];
    % disp(sprintf('nLSB: %d%d%d',n_lsb_Bn(1),n_lsb_Bn(2),n_lsb_Bn(3)));

    %Bits a incrustar en bandas  
    Numb_B1=n_lsb_Bn(1)*(LimS_B1-LimI_B1);
    Numb_B2=n_lsb_Bn(2)*(LimS_B2-LimI_B2);
    Numb_B3=n_lsb_Bn(3)*(LimS_B3-LimI_B3);

    %Incrustación 
    if dirIncrustacion==1
        while Numb_B1+Numb_B2+Numb_B3>length(sv)
            if Numb_B3>0
               Numb_B3=Numb_B3-n_lsb_Bn(3);
            elseif Numb_B2>0
               Numb_B2=Numb_B2-n_lsb_Bn(2);
            else
               Numb_B1=Numb_B1-n_lsb_Bn(1);
            end
        end
        svLim=sv(1,1:Numb_B1+Numb_B2+Numb_B3);

        sv_B1=svLim(1,1:Numb_B1);
        sv2_B1=reshape(sv_B1,n_lsb_Bn(1),[]);
        Xppms(res-n_lsb_Bn(1)+1:res,LimI_B1:LimI_B1+length(sv2_B1)-1)=sv2_B1;
        if Numb_B2>0
           sv_B2=svLim(1,Numb_B1+1:Numb_B1+Numb_B2);
           sv2_B2=reshape(sv_B2,n_lsb_Bn(2),[]);
           Xppms(res-n_lsb_Bn(2)+1:res,LimI_B2:LimI_B2+length(sv2_B2)-1)=sv2_B2;
        end
        if Numb_B3>0
           sv_B3=svLim(1,Numb_B1+Numb_B2+1:Numb_B1+Numb_B2+Numb_B3);
           sv2_B3=reshape(sv_B3,n_lsb_Bn(3),[]);
           Xppms(res-n_lsb_Bn(3)+1:res,LimI_B3:LimI_B3+length(sv2_B3)-1)=sv2_B3;
        end
    else
        while Numb_B1+Numb_B2+Numb_B3>length(sv)
            if Numb_B1>0
               Numb_B1=Numb_B1-n_lsb_Bn(1);
            elseif Numb_B2>0
               Numb_B2=Numb_B2-n_lsb_Bn(2);
            else
               Numb_B3=Numb_B3-n_lsb_Bn(3);
            end
        end
        svLim=sv(1,1:Numb_B1+Numb_B2+Numb_B3);
        Ts=length(svLim);

        sv_B3=svLim(1,end-Numb_B3+1:end);
        sv2_B3=reshape(sv_B3,n_lsb_Bn(3),[]);
        Xppms(res-n_lsb_Bn(3)+1:res,LimS_B3-length(sv2_B3)+1:LimS_B3)=sv2_B3;
        if Numb_B2>0
           sv_B2=svLim(1,end-Numb_B2-Numb_B3+1:end-Numb_B3);
           sv2_B2=reshape(sv_B2,n_lsb_Bn(2),[]);
           Xppms(res-n_lsb_Bn(2)+1:res,LimS_B2-length(sv2_B2)+1:LimS_B2)=sv2_B2;
        end
        if Numb_B1>0
           sv_B1=svLim(1,end-Numb_B1-Numb_B2-Numb_B3+1:end-Numb_B2-Numb_B3);
           sv2_B1=reshape(sv_B1,n_lsb_Bn(1),[]);
           Xppms(res-n_lsb_Bn(1)+1:res,LimS_B1-length(sv2_B1)+1:LimS_B1)=sv2_B1;
        end
    end
    
    %Construcción del audio stego
    Xpps=DeCod(Xppms,res,-pi,pi);   
    Xps=[fliplr(-1*Xpps) 0 Xpps];
    Xs=Xm.*exp(1i*Xps);         
    xs=fftshift(ifft(ifftshift(Xs)));
    nombreStego=sprintf('%s_lsb%d%d%d_%s.wav',nombrePortada,n_lsb_Bn(1),n_lsb_Bn(2),n_lsb_Bn(3),nombreSecreto);
    Tx=sprintf('%s/%s',rutaStego,nombreStego);
    audiowrite(Tx,xs,Fs,'BitsPerSample',32);

    %Métricas
    SNR=metricaSNR(xs,x);
    NMSE=metricaNMSE(xs,x);
    SSIM=ssim(xs,x);
    [PEAQodg, ~]=metricaPEAQ(Tx,rutaWav);
end
