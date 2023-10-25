%{
    Comparación de SNR entre métodos
%}

clear all, close all, clc;

SNRm1 = xlsread('informe.xlsx','Metodo1','G3:G152');
SNRm2 = xlsread('informe.xlsx','Metodo2','G3:G152');
SNRm3 = xlsread('informe.xlsx','Metodo3','I3:I152');
SNRm4 = xlsread('informe.xlsx','Metodo4','K3:K152');
SNRm5 = xlsread('informe.xlsx','Metodo5','D3:D152');

SNR=[SNRm1 SNRm2 SNRm3 SNRm4 SNRm5];

%% Gráfica 1
media=mean(SNR);
desviacion = std(SNR);
metodo = 1:size(SNR,2);
etiquetaM= {'One', '','Two','','Three','', 'Four','', 'Five'};
SNRlimite=min(SNRm3(SNRm3>17))*ones(1,length(metodo));

figure, hold on;
errorbar(metodo, media, desviacion,'LineWidth',1.5,'Color','#14C2CB',"LineStyle","none");
plot(metodo,media,'*','Color','#FFC000');
plot(metodo,SNRlimite,'Color','#FFC000'),text(1,SNRlimite(1),sprintf('%f',SNRlimite(1)),"HorizontalAlignment","right");
hold off, xticklabels(etiquetaM);
xlabel('Method'), ylabel('SNR [dB]'),grid;
set(gcf,'color','w');

%% Gráfica 2
media=mean(SNR);
desviacion = std(SNR);
metodo = 1:size(SNR,2);
etiquetaM= {'One', '','Two','','Three','', 'Four','', 'Five'};
SNRlimite=min(SNRm3(SNRm3>17))*ones(1,length(metodo));

figure, hold on;
for i=1:length(metodo)
    plot(metodo(i),SNR(:,i),'.','LineWidth',1.5,'Color','#14C2CB');
end
plot(metodo,media,'*','Color','#FFC000');
plot(metodo,SNRlimite,'Color','#FFC000'),text(1,SNRlimite(1),sprintf('%f',SNRlimite(1)),"HorizontalAlignment","right");
hold off, xticklabels(etiquetaM);
xlabel('Method'), ylabel('SNR [dB]'),grid;
set(gcf,'color','w');
