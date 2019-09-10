select 
    ndp.parameter,
    ndp.value database_value,
    nip.value instance_value,
    case when nip.value = ndp.value or nip.value is null then 'SUCCESS' else 'FAIL' end instance_value_comparison,
    np.value client_value,
    case when np.value = ndp.value or np.value is null then 'SUCCESS' else 'FAIL' end client_value_comparison
from nls_database_parameters ndp 
    left join nls_instance_parameters nip on ndp.parameter = nip.parameter
    left join v$nls_parameters np on ndp.parameter = np.parameter
order by parameter;
