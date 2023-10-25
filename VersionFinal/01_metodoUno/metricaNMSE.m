function nmse = metricaNMSE(test,ref)
    ref = ref/max(abs(ref));
    test = test/max(abs(test));
    num = sum((ref - test).^2);
    den = sum(ref.^2);
    nmse = 1 - (0.5 * sqrt(num / den));
end