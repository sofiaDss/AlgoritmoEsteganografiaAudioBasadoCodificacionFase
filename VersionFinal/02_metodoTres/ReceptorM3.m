%{
    Método #3. Modificación de bandas de frecuencia
    
    RECEPTOR
    consideraciones: 
        1. Mismas Fs y Fss, obligatorias en Tx y Rx (no se recibe)
        2. Misma res, obligatoria en Tx y Rx (no se recibe)
        3. Número de LSB de cada banda n_lsb_Bn (se recibe)
        4. Número total de bits incrustados Ts (se recibe)
        5. Límite inferior y superior de las regiones de cuantificación del
           audio secreto: minS y maxS (se recibe)
%}

function [Rx,svr] = ReceptorM3(rutaStego, Ts, n_lsb_Bn, Bn, minS, maxS, rutaSecreto, nombreSecreto)

    %Atributos de Rx
    Fss=48000;
    res=8;
    dirIncrustacion=0;

    %Lectura del audio stego
    [yc,Fs] = audioread(rutaStego);
    infoStego=audioinfo(rutaStego);
    y=sum(yc,2)/infoStego.NumChannels;
    y=y';

    %FFT
    Y=fftshift(fft(ifftshift(y)));   

    %Espectro de fase positivo
    Yp=angle(Y);  
    f=linspace(-0.5*Fs,0.5*Fs,numel(Yp));
    fp=f(f>0);
    Ypp=Yp(f>0);
    
    %Cuantificación y codificación del espectro de fase
    Yppm=CuanCod(Ypp,res,-pi,pi);

    %Bandas
    LimI_B1=find((fp<=Bn(2) & fp>=Bn(1)),1,'first');
    LimS_B1=find((fp<=Bn(2) & fp>=Bn(1)),1,'last');
    LimI_B2=find((fp<=Bn(4) & fp>=Bn(3)),1,'first'); 
    LimS_B2=find((fp<=Bn(4) & fp>=Bn(3)),1,'last');   
    LimI_B3=find((fp<=Bn(6) & fp>=Bn(5)),1,'first'); 
    LimS_B3=find((fp<=Bn(6) & fp>=Bn(5)),1,'last');
    
    %Bits a incrustar en bandas  
    Numb_B1=n_lsb_Bn(1)*(LimS_B1-LimI_B1);
    Numb_B2=n_lsb_Bn(2)*(LimS_B2-LimI_B2);
    Numb_B3=n_lsb_Bn(3)*(LimS_B3-LimI_B3);

    %Extracción
    if dirIncrustacion==1
        while Numb_B1+Numb_B2+Numb_B3>Ts
            if Numb_B3>0
               Numb_B3=Numb_B3-n_lsb_Bn(3);
            elseif Numb_B2>0
               Numb_B2=Numb_B2-n_lsb_Bn(2);
            else
               Numb_B1=Numb_B1-n_lsb_Bn(1);
            end
        end
        Ls_B1=Numb_B1/n_lsb_Bn(1);
        svr_B1=Yppm(res-n_lsb_Bn(1)+1:res,LimI_B1:LimI_B1+Ls_B1-1);
        svr=reshape(svr_B1,1,[]);
        if Numb_B2>0
            Ls_B2=Numb_B2/n_lsb_Bn(2);
            svr_B2=Yppm(res-n_lsb_Bn(2)+1:res,LimI_B2:LimI_B2+Ls_B2-1);
            svr=[svr reshape(svr_B2,1,[])];
        end
        if Numb_B3>0
            Ls_B3=Numb_B3/n_lsb_Bn(3);
            svr_B3=Yppm(res-n_lsb_Bn(3)+1:res,LimI_B3:LimI_B3+Ls_B3-1);
            svr=[svr reshape(svr_B3,1,[])];
        end
    else
         while Numb_B1+Numb_B2+Numb_B3>Ts
            if Numb_B1>0
               Numb_B1=Numb_B1-n_lsb_Bn(1);
            elseif Numb_B2>0
               Numb_B2=Numb_B2-n_lsb_Bn(2);
            else
               Numb_B3=Numb_B3-n_lsb_Bn(3);
            end
        end
        Ls_B3=Numb_B3/n_lsb_Bn(3);
        svr_B3=Yppm(res-n_lsb_Bn(3)+1:res,LimS_B3-Ls_B3+1:LimS_B3);
        svr=reshape(svr_B3,1,[]);
        if Numb_B2>0
            Ls_B2=Numb_B2/n_lsb_Bn(2);
            svr_B2=Yppm(res-n_lsb_Bn(2)+1:res,LimS_B2-Ls_B2+1:LimS_B2);
            svr=[reshape(svr_B2,1,[]) svr];
        end
        if Numb_B1>0
            Ls_B1=Numb_B1/n_lsb_Bn(1);
            svr_B1=Yppm(res-n_lsb_Bn(1)+1:res,LimS_B1-Ls_B1+1:LimS_B1);
            svr=[reshape(svr_B1,1,[]) svr];
        end
    end

    svrTa=svr;
    if rem(length(svrTa),res)~=0
        svrT=[svrTa zeros(1,res-rem(length(svrTa),res))]; 
    else
        svrT=svrTa;
    end

    %Reconstrucción del audio secreto
    smr=reshape(svrT,res,[]);
    sr = DeCod(smr,res,minS,maxS);
    
    Rx=sprintf('%s/%s.wav',rutaSecreto,nombreSecreto);
    audiowrite(Rx,sr,Fss,'BitsPerSample',32);
end
