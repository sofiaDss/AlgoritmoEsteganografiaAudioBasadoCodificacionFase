function snr = metricaSNR(test,ref)
    Pxn=sum(ref.^2)/length(ref);         %Potencia del audio portada
    Pn=sum((ref-test).^2)/length(ref);   %Potencia de ruido presente en el audio stego
    snr=10*log10(Pxn/Pn);
end