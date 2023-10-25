%Función encargada de la cuantificación y codificación de fuente

function [Xcode, Ncuan, Nc_E] = CuanCod(X,res,Xmin,Xmax)
    N=2^res;                       
    delta=(abs(Xmin)+abs(Xmax))/N;
    Rcuan=Xmin:delta:Xmax;          
    Ncuan=Xmin+0.5*delta:delta:Xmax-0.5*delta;
    Xc=X;
    for i=1:N
        Xc(X>=Rcuan(i) & X<=Rcuan(i+1))=Ncuan(i);
    end
    Nc_E=0:numel(Ncuan)-1;
    Xd=Xc;
    for i=1:N
        Xd(Xc==Ncuan(i))=Nc_E(i);
    end   
    Xcode=int2bit(Xd,res,true);
end