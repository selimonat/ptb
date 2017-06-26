function sample = exprndtrunc(rate, low, high)
x = low:high;
y = exppdf(x, rate);
y = cumsum(y/sum(y));
y = y/max(y);
t = rand;
idx = find(t<=y, 1, 'first');
sample = x(idx);

end