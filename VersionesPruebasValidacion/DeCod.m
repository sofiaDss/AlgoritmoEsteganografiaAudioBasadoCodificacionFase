%Función encargada de la decodificación de fuente

function [Xcr] = DeCuanDeCod(Xcode,res,Ncuan,Nc_E)
    N=2^res; 
    Xdr=bit2int(Xcode,res,true); 
    Xcr=Xdr;
    for i=1:N
        Xcr(Xdr==Nc_E(i))=Ncuan(i);
    end
end