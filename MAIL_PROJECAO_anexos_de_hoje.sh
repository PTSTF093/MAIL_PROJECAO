#!/bin/bash

: '
Abertura do online:
	SELECT projecao
	FROM projecao
	ORDER BY agora desc
	LIMIT 1 
02:13:03

02:13:03 - 00:03:00 = select SEC_TO_TIME( (TIME_TO_SEC(02:13:03)) - (TIME_TO_SEC(00:30:00)) )
'

#Guardar a abertura do online numa variavel

hoje=$(date +"%d-%m-%Y")
tar cvzf LOG_PROJECAO_$hoje.tar.gz *$hoje*.txt

enderecos="ptstf093@pt.ibm.com,"
#enderecos="ptstf093@pt.ibm.com,jose.gaspar@pt.ibm.com,vmmbastos@pt.ibm.com"

echo "Bom dia, segue os ficheiros de log da projeção de hoje para PDBDDSNC"  | mutt -a LOG_PROJECAO_$hoje.tar.gz -s "$ONLINE - Logs dos controles de estimativa de hoje" -- $enderecos
