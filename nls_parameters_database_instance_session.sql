select 
    ndp.parameter,
    ndp.value database_value,
    nip.value instance_value,
    case when nip.value = ndp.value or nip.value is null then 'SUCCESS' else 'FAIL' end instance_value_comparison,
    nsp.value session_value,
    case when nsp.value = ndp.value or nsp.value is null then 'SUCCESS' else 'FAIL' end session_value_comparison
from nls_database_parameters ndp 
    left join nls_instance_parameters nip on ndp.parameter = nip.parameter
    left join nls_session_parameters nsp on ndp.parameter = nsp.parameter
order by ndp.parameter;
