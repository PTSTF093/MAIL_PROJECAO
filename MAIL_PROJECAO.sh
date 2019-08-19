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
user="root"
password="openpipes"

declare -a CADAMEIAHORA=('00:30:00' '01:00:00' '01:30:00' '02:00:00' '02:30:00' '03:00:00' '03:30:00' '04:00:00' '04:30:00' '05:00:00' '05:30:00' '06:00:00' '06:30:00' '07:00:00' '07:30:00' '08:00:00')

hoje=$(date +"%Y-%m-%d")
#enderecos="ptstf093@pt.ibm.com,ptstf031@pt.ibm.com,ptstf026@pt.ibm.com"
enderecos="ptstf093@pt.ibm.com,jose.gaspar@pt.ibm.com,ptstf026@pt.ibm.com"
#enderecos="ptstf093@pt.ibm.com,jose.gaspar@pt.ibm.com"

#AO=$(echo "SELECT projecao FROM auditoria.projecao order by agora asc limit 1" | mysql auditoria -u $user -p$password)
AO=$(mysql auditoria -u $user -p$password -se "SELECT projecao FROM auditoria.projecao order by agora desc limit 1"|cut -f1)

#QUAL o JOB do ONLINE de HOJE?
ONLINE=$(mysql auditoria -u $user -p$password -se "SELECT online FROM auditoria.projecao order by agora desc limit 1"|cut -f1)
#echo "AO=$AO"

#Limpar ficheiro de saída
F="MAIL_PROJECAO.txt"
echo > $F

#Algum conteúdo para o mail
echo "Bom dia," >> $F
echo "" >> $F
echo "segue o controle de estimativa para a projeção do batch de hoje e para o online $ONLINE" >> $F
echo "" >> $F
echo "Legendas:
HORA REC -> hora da recolha
PROJECAO -> previsao feita na hora da recolha
T2P      -> Time to Projecao
A.ONLINE -> Abertura do Online
T2AO     -> Time to Abertura do Online (Real)
DIFEREN. -> Diferança entre T2P e T2AO


" >> $F

#cabecalho
#00:30:00 | 02:45:16 | 02:15:16 | 02:13:03 | 01:43:03 | 01:02:13
echo "HORA REC | PROJECAO | T2P      | A.ONLINE | T2AO     | DIFEREN."
echo "---------------------------------------------------------------" >> $F
echo "HORA REC | PROJECAO | T2P      | A.ONLINE | T2AO     | DIFEREN." >> $F
echo "---------------------------------------------------------------"
echo "---------------------------------------------------------------" >> $F

for meia in "${CADAMEIAHORA[@]}" ; do
	#calcular a diferenca de agora, pe 00:30 para a abertura previsa do online
	#primeiro capturar a projeção para 00h30
	#SELECT projecao FROM auditoria.projecao WHERE agora LIKE '2019-08-12 00:3%' ORDER BY agora ASC LIMIT 1 
	frag_hora=${meia::4}
	PROJECAO=$(mysql auditoria -u $user -p$password -se "SELECT projecao FROM auditoria.projecao WHERE agora LIKE '$hoje $frag_hora%' ORDER BY agora ASC LIMIT 1 " |cut -f1)
	T2P=$(mysql auditoria -u $user -p$password -se "select SEC_TO_TIME( (TIME_TO_SEC('$PROJECAO')) - (TIME_TO_SEC('$meia')) )" |cut -f1)
	#echo "$meia T2P=$T2P"
	
	#calcular a diferenca de agora, pe 00:30 para a abertura do online
	#T2SLA Time 2 SLA = Abertura do online AO menos 00h30
	#T2SLA=$(echo "select SEC_TO_TIME( (TIME_TO_SEC('$AO')) - (TIME_TO_SEC('00:30:00')) )" | mysql auditoria -u $user -p$password)
	T2SLA=$(mysql auditoria -u $user -p$password -se "select SEC_TO_TIME( (TIME_TO_SEC('$AO')) - (TIME_TO_SEC('$meia')) )" |cut -f1)
	#echo "$meia T2SLA=$T2SLA"
	
	#fazer a diferença entre T2SLA e T2P
	#SELECT SUBTIME('12:35:00', '1:30');
	DIFERENCA=$(mysql auditoria -u $user -p$password -se "select SUBTIME('$T2P', '$T2SLA')" |cut -f1)
	
	#display dos resultados
	if [ ! -z "$PROJECAO" ] ; then
		echo "$meia | $PROJECAO | $T2P | $AO | $T2SLA | $DIFERENCA"
		echo "$meia | $PROJECAO | $T2P | $AO | $T2SLA | $DIFERENCA" >> $F
	fi
done

#Iterar pelo ficheiro e montar um mail
cat $F | mutt -s "$ONLINE - controles de estimativa" -- $enderecos
