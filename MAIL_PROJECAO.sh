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

declare -a CADAMEIAHORA=('00:15:00' '00:30:00' '00:45:00' '01:00:00' '01:15:00' '01:30:00' '01:45:00' '02:00:00' '02:15:00' '02:30:00' '02:45:00' '03:00:00' '03:15:00' '03:30:00' '03:45:00' '04:00:00' '04:15:00' '04:30:00' '04:45:00' '05:00:00' '05:15:00' '05:30:00' '05:45:00' '06:00:00' '06:15:00' '06:30:00' '06:45:00' '07:00:00' '07:15:00' '07:30:00' '07:45:00' '08:00:00')

hoje=$(date +"%Y-%m-%d")
#enderecos="ptstf093@pt.ibm.com,ptstf031@pt.ibm.com,ptstf026@pt.ibm.com"
enderecos="ptstf093@pt.ibm.com,jose.gaspar@pt.ibm.com,ptstf026@pt.ibm.com,ptstf031@pt.ibm.com"
#enderecos="ptstf093@pt.ibm.com,jose.gaspar@pt.ibm.com"
#enderecos="ptstf093@pt.ibm.com"

#AO=$(echo "SELECT projecao FROM auditoria.projecao order by agora asc limit 1" | mysql auditoria -u $user -p$password)
#AO=$(mysql auditoria -u $user -p$password -se "SELECT projecao FROM auditoria.projecao order by agora desc limit 1"|cut -f1)
AO=$(mysql auditoria -u $user -p$password -se "SELECT hora FROM auditoria.AberturaOnline order by instante desc limit 1"|cut -f1)

#QUAL o JOB do ONLINE de HOJE?
ONLINE=$(mysql auditoria -u $user -p$password -se "SELECT online FROM auditoria.projecao order by agora desc limit 1"|cut -f1)
#echo "AO=$AO"

#Limpar ficheiro de saída
F="MAIL_PROJECAO.txt"
echo > $F

#Algum conteúdo para o mail
echo "Bom dia," >> $F
echo "" >> $F
echo "segue o controle de eficácia da projeção da hora de execução do SLA $ONLINE, relativo ao batch desta noite." >> $F
echo "" >> $F
#echo "Legendas:
#HORA REC -> hora da recolha
#T2P      -> Time to Projecao
#T2AO     -> Time to Abertura do Online (Real)
#DIFEREN. -> Diferança entre T2P e T2AO
#
#
#" >> $F

#cabecalho
#00:30:00 | 02:45:16 | 02:15:16 | 02:13:03 | 01:43:03 | 01:02:13

#echo "+--------------------+------------+------------+---------+" >>$F
#echo "|DATA/HORA RECOLHA   |Time to SLA |Time to SLA |Diferença|" >>$F
#echo "|                    |(estimativa)| (real)     |         |" >>$F
#echo "+--------------------+------------+------------+---------+" >>$F

printf "\n+--------------------+---------------+---------------+---------------+" >>$F
printf "\n|DATA/HORA RECOLHA   |Time to SLA    |Time to SLA    |Diferença      |" >>$F
printf "\n|                    |(estimativa)   | (real)        |               |" >>$F
printf "\n+--------------------+---------------+---------------+---------------+" >>$F

#echo "+--------------------+------------+------------+---------+
#|DATA/HORA RECOLHA   |Time to SLA |Time to SLA |Diferença|
#|                    |(estimativa)| (real)     |         |
#+--------------------+------------+------------+---------+"

printf "\n+--------------------+---------------+---------------+---------------+" 
printf "\n|DATA/HORA RECOLHA   |Time to SLA    |Time to SLA    |Diferença      |" 
printf "\n|                    |(estimativa)   | (real)        |               |" 
printf "\n+--------------------+---------------+---------------+---------------+" 


#echo "HORA REC            | T2P      | T2AO     | DIFEREN."
#echo "----------------------------------------------------" >> $F
#echo "HORA REC            | T2P      | T2AO     | DIFEREN." >> $F
#echo "----------------------------------------------------" >> $F

for meia in "${CADAMEIAHORA[@]}" ; do
	#calcular a diferenca de agora, pe 00:30 para a abertura previsa do online
	#primeiro capturar a projeção para 00h30
	#SELECT projecao FROM auditoria.projecao WHERE agora LIKE '2019-08-12 00:3%' ORDER BY agora ASC LIMIT 1 
	#frag_hora=${meia::4}
	#PROJECAO=$(mysql auditoria -u $user -p$password -se "SELECT projecao FROM auditoria.projecao WHERE agora LIKE '$hoje $frag_hora%' ORDER BY agora ASC LIMIT 1 " |cut -f1)
	PROJECAO=$(mysql auditoria -u $user -p$password -se "SELECT projecao FROM auditoria.projecao WHERE agora >= '$hoje $meia' ORDER BY agora ASC LIMIT 1 " |cut -f1)
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
	if [[ ! $DIFERENCA == *"-"* ]] ; then
		DIFERENCA="+$DIFERENCA"
	fi
	if [[ ! -z "$PROJECAO" ]] && [[ ! $T2P == *"-"* ]] ; then
		#echo "|$hoje $meia | $T2P   | $T2SLA   | $DIFERENCA|" 
		#echo "|$hoje $meia | $T2P   | $T2SLA   | $DIFERENCA|" >> $F
		printf "\n|%s %s | %-13s | %-13s | %13s |" "$hoje" "$meia" "$T2P" "$T2SLA" "$DIFERENCA" 
		printf "\n|%s %s | %-13s | %-13s | %13s |" "$hoje" "$meia" "$T2P" "$T2SLA" "$DIFERENCA" >> $F
	fi
done

#Finalmente imprimir a ultima recolha de informação
#Ultima hora existente na tabela de projeção
#UH=$(mysql auditoria -u $user -p$password -se "SELECT agora FROM auditoria.projecao ORDER BY agora DESC LIMIT 1 " |cut -f1)
#UPROJECAO=$(mysql auditoria -u $user -p$password -se "SELECT projecao FROM auditoria.projecao WHERE agora = '$UH'" |cut -f1)
#UT2P=$(mysql auditoria -u $user -p$password -se "select SEC_TO_TIME( (TIME_TO_SEC('$UPROJECAO')) - (TIME_TO_SEC('$UH')) )" |cut -f1)
#echo "$UH | $UT2P | -------- | --------"
#echo "$UH | $UT2P | -------- | --------" >> $F

#echo "+--------------------+------------+------------+---------+" >> $F
#echo "|$hoje $AO ===> $ONLINE executado!            |" >> $F
#echo "+--------------------+------------+------------+---------+" >> $F
#echo "+--------------------+------------+------------+---------+"
#echo "|$hoje $AO ===> $ONLINE executado!            |"
#echo "+--------------------+------------+------------+---------+"

printf "\n+--------------------+---------------+---------------+---------------+" >>$F
printf "\n|%s %s ===> %s executado!                        |" $hoje $AO $ONLINE >> $F
printf "\n+--------------------+---------------+---------------+---------------+" >>$F
printf "\n" >>$F

printf "\n+--------------------+---------------+---------------+---------------+" 
printf "\n|%s %s ===> %s executado!                        |" $hoje $AO $ONLINE 
printf "\n+--------------------+---------------+---------------+---------------+" 
printf "\n" 


printf "\n\n\n"
printf "\n\n\n" >>$F

#####################################
#####################################
#####################################
###  Jobs que cancelaram no caminho do luxo crítico

OUTPUT=$(mysql auditoria -u $user -p$password -N -t -e "select distinct(joberro) from auditoria.projecao_hotlist where instante like '$hoje %'")

if [ ! -z "$OUTPUT" ] ; then
	printf "JOBS que cancelaram no fluxo crítico:\n\n"
	printf "JOBS que cancelaram no fluxo crítico:\n\n" >>$F
	printf "%s\n" "$OUTPUT"
	printf "%s\n" "$OUTPUT" >>$F
#mysql auditoria -u $user -p$password -se "select distinct(joberro) from auditoria.projecao_hotlist where instante like '$hoje %'" >>$F
fi






#Iterar pelo ficheiro e montar um mail
cat $F | mutt -s "$ONLINE - controles de estimativa" -- $enderecos
