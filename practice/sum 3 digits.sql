select
    listagg(n,'+')within group(order by ceil(n/3), n) || '=' || sum(n) rslt
from xmltable('1 to 7' columns n number path '.')
group by ceil(n/3);


select rslt from xmltable('1 to 7' columns rn for ordinality, n number path '.')
model
return updated rows
dimension by(rn)
measures(n, cast(null as varchar2(50)) rslt)
rules (
    rslt [mod(rn,3)=1] order by rn = n[cv()] || 
                                     presentv(n[cv()+1],'+'||n[cv()+1],null) || 
                                     presentv(n[cv()+2],'+'||n[cv()+2],null) || '=' || 
                                     sum(n)[for rn from cv() to cv()+2 increment 1]
);