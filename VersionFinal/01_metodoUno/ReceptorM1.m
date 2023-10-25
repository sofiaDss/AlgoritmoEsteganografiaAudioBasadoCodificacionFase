%{
    Método #1. Modificación de todas las muestras
    
    RECEPTOR
    consideraciones: 
        1. Mismas Fs y Fss, obligatorias en Tx y Rx (no se recibe)
        2. Misma res, obligatoria en Tx y Rx (no se recibe)
        3. Número de LSB n_lsb (se recibe)
        4. Número total de bits incrustados Ts (se recibe)
        5. Límite inferior y superior de las regiones de cuantificación del
           audio secreto: minS y maxS (se recibe)
%}

function [Rx,svr] = ReceptorM1(rutaStego, Ls, n_lsb, minS, maxS, rutaSecreto, nombreSecreto)

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
    Ypp=Yp(f>0);
    
    %Cuantificación y codificación del espectro de fase
    Yppm=CuanCod(Ypp,res,-pi,pi);

    %Extracción
    if dirIncrustacion==1
        svr=Yppm(res-n_lsb+1:res,1:Ls);
    else
        svr=Yppm(res-n_lsb+1:res,end-(Ls-1):end);
    end
    svrTa=reshape(svr,1,[]);
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
