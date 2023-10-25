%Función encargada de la decodificación de fuente

function Xcr = DeCod(Xcode,res,Xmin,Xmax)
    N=2^res; 
    delta=(abs(Xmin)+abs(Xmax))/N;
    Ncuan=Xmin+0.5*delta:delta:Xmax-0.5*delta;
    Nc_E=0:numel(Ncuan)-1;

    Xdr=bit2int(Xcode,res,true); 
    Xcr=Xdr;
    for i=1:N
        Xcr(Xdr==Nc_E(i))=Ncuan(i);
    end
end