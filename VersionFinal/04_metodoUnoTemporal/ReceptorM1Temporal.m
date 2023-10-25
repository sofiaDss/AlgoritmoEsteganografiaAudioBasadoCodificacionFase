%{
    Método #1 Temporal. Modificación de todas las muestras en dominio temporal
    
    RECEPTOR
    consideraciones: 
        1. Mismas Fs y Fss, obligatorias en Tx y Rx (no se recibe)
        2. Misma res, obligatoria en Tx y Rx (no se recibe)
        3. Número de LSB n_lsb (se recibe)
        4. Número total de bits incrustados Ts (se recibe)
        5. Límite inferior y superior de las regiones de cuantificación del
           audio secreto: minS y maxS (se recibe)
%}

function [Rx,svr] = ReceptorM1Temporal(rutaStego, Ls, n_lsb, minS, maxS, minX, maxX, rutaSecreto, nombreSecreto)

    %Atributos de Rx
    Fss=48000;
    res=8;
    dirIncrustacion=0;

    %Lectura del audio stego
    [yc,Fs] = audioread(rutaStego);
    infoStego=audioinfo(rutaStego);
    y=sum(yc,2)/infoStego.NumChannels;
    y=y';
    yppm=CuanCod(y,res,minX,maxX);

    %Extracción
    if dirIncrustacion==1
        svr=yppm(res-n_lsb+1:res,1:Ls);
    else
        svr=yppm(res-n_lsb+1:res,end-(Ls-1):end);
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
