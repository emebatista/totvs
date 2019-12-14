#include "rwmake.ch"
#include "topconn.ch"
#include "totvs.ch"
#include "vkey.ch"
#include "colors.ch"
#INCLUDE 'FILEIO.CH'

#DEFINE CRLF Chr(13)+Chr(10)

/*/{Protheus.doc} QSQL
Função para abrir executar consultas SQL no banco de dados
@author Emerson D Batista
@since 11/12/2017
@version 1.0
/*/

User Function AfterLogin() 
	SetKey( VK_F11, { || u_qsql() } )
	SetKey( K_SH_F11, { || u_qsql() } )
Return nil

User Function QSQL(cFraseAuto,_aPosicoes,_oJanela)
	Local cRPO2
	Local btnX // Nome generico para botao

	Private cTemp    	:= "01"
	Private _cMyAlias 	:= ""
	Private _cQueryTxt 	:= space(500)//"Ctrl + Down para mostrar os campos (sair ESC)"+ CRLF +"F5 para executar a query"+CRLF
	Private cTitulo     := "QSQL"
	Private a_Cmps		:= {"D_E_L_E_T_"}
	Private cResult     := ""
	Private _cRet       := ""
	Private c_Pth := ""
	Private c_Dtmp := ""
	Private c_Hst := ""

//	SET AUTOPEN OFF
//	SET DELETED OFF
//	SET SOFTSEEK ON
//	SET DATE BRITISH
//	SET CENTURY ON
//	SET EPOCH TO 1950

	If Select("SX2")=0
		RPCCLEARENV()
		RPCSetType(3)
		RPCSetEnv("01","01","","","","",{})
	EndIf

	If ! IsInCallStack("U_SqlFile")
		If !(FWIsAdmin( __cUserID ) ) .AND. GetNewPar("MV_X_RSQL",.F.)
			MsgStop(' O usuario ' + __cUserID + ' nao pertence ao grupo de administradores!')
			Return
		Else
			IF GetNewPar("MV_X_QSQL1",.F.) .AND. MsgNoYes("Abrir SqlFile?")
				SetKey( VK_F11, NIL )

				While U_SqlFile()
				EndDo

				SetKey( VK_F11, { || u_qsql() } )

				Return
			Endif
		Endif
	Endif

	_cQueryTxt += space(500) //" <% e %> definem parametros. Ex. E5_DATA >= <%data_inicial%> "

	If !Empty(cFraseAuto)
		_cQueryTxt := cFraseAuto
	EndIf

	cRPO := GetSrvProfString("SourcePath", "\undefined")
	cRPO2:= cRPO
	If RAT("/",cRPO)>0
		nPos := RAT("/",cRPO)
		cRPO := Space(30)+"Data Promoçao RPO: "+DTOC(STOD(Substr(cRPO2,nPos+1,8)))
		cRPO := cRPO + " Hora: "+Substr(cRPO2,nPos+9,2)+":"+Substr(cRPO2,nPos+11,2)+":"+Substr(cRPO2,nPos+13,2)
	EndIf

	c_Hst := "\" + GetRmtInfo()[1]


	If GetRemoteType() = 2
		//l:\tmp\
		c_Dtmp := "l:" + StrTran(GetTempPath(),'/','\')
		c_Pth := "l:" + StrTran(GetTempPath(),'/','\') + 'cfgqsql.tmp'
	Else
		c_Dtmp := GetTempPath()
		c_Pth := GetTempPath() + 'cfgqsql.tmp'
	Endif

	If File(c_Pth)
		nHandle := FT_FUse(AllTrim(c_Pth))

		If nHandle == -1
			MessageBox('Não foi possível ler o arquivo ' + c_Pth , 'AVISO', 16)
		Else

			FT_FGoTop()
			While ! FT_FEof()
				//oTMultiget2:AppendText(Alltrim(FT_FReadLn()) + CRLF)
				//_cQueryTxt += Alltrim(FT_FReadLn()) + CRLF
				FT_FSkip()
			EndDo
			FT_FUSE()
		EndIf
	Else
		//oTMultiget2:AppendText("Ctrl + Down para mostrar os campos (sair ESC)"+ CRLF +"F5 para executar a query"+ CRLF + CRLF +"SELECT * FROM"+ CRLF +"WHERE D_E_L_E_T_ = ' '"+ CRLF)
	Endif


	If _aPosicoes == nil

		DEFINE MSDIALOG oDlg1 TITLE "DM Tools - QSQL "+SPACE(150)+cRPO From 001,001 To 040,150
		DEFINE FONT oFont NAME "Courier New" SIZE 0, -12 BOLD
		DEFINE FONT oFont2 NAME "Courier New" SIZE 0, -12
		oDlg1:lEscClose     := .F. //Nao permite sair ao se pressionar a tecla ESC.

		oTMultiget2 := TMultiget():Create(oDlg1,{|u|if(Pcount()>0,_cQueryTxt:=u,_cQueryTxt)},001,001,520,150,oFont,,,,,.T.,,,,,,,,,,,.T.)
		@ 010 	   ,525 SAY    "____________________"   OF oDlg1 pixel color CLR_HBLUE 

		@ 001      ,525 BUTTON "&Executa (F5)" 	Size 60,10 action fRun() 		Object btnOK
		@ 010+10*1 ,525 BUTTON "E&xporta XML" 	Size 60,10 action fExport()   	Object btnExp
	EndIf

	If Empty(cFraseAuto)
		SetKey( VK_F5 ,{|| fRun()})
		SetKey( 75,{|| LstCmp()})

		@ 010+09*02 ,525 BUTTON "Abrir"   			Size 55,10 action Open()     	Object btnAbrir
		@ 010+09*03 ,525 BUTTON "Salvar"   			Size 55,10 action Save()     	Object btnAbrir
		@ 010+09*04 ,525 BUTTON "Exec.Fórmula"   	Size 55,10 action Terminal()    Object btnAbrir
		@ 010+09*05 ,525 BUTTON "Editar Tabela"    	Size 55,10 action fDicio()    	Object btnDicio
		@ 010+09*06 ,525 BUTTON "Historico"			Size 55,10 action ShwHst(0)	 	Object btnHist
		@ 010+09*07 ,525 BUTTON "Limpa Hist"		Size 55,10 action ShwHst(1)	 	Object btnHist
		@ 010+09*08 ,525 BUTTON "Muda RPO"			Size 55,10 action u_MudaAmb()	 Object btnHist
		@ 010+09*09 ,525 BUTTON "Copia RPO"			Size 55,10 action u_Promove()	 Object btnHist
		@ 010+09*10 ,525 BUTTON "Comando no Srv."	Size 55,10 action fPowerShell()	 Object btnPS
		@ 010+09*11 ,525 BUTTON "Copia Arquivos"	Size 55,10 action fCopiar()	 Object btnCopiar
		@ 010+09*12 ,525 BUTTON "SQL File"	       	Size 55,10 action u_SqlFile()	 Object btnSqlF
		@ 010+09*13 ,525 BUTTON "Help" 				Size 55,10 action fHelp() Object btnX
		@ 010+09*14 ,525 BUTTON "Sair" 				Size 55,10 action oDlg1:End() 	Object btnCancela


		Activate Dialog oDlg1 centered
		SetKey( VK_F5, Nil )
		SetKey( 75,Nil)
	Else
		If _aPosicoes == nil
			fRun()
			fExport()
		Else
			fRun(_aPosicoes,_oJanela)
		EndIF
	EndIf

Return

Static Function fDicio()
	Static    cArqDic  := "SX3"
	Static    cFiltro  := Space(200)
	aPergs  := {}
	aRet    := {}
	Set(_SET_DELETED, .F.)
	aAdd( aPergs ,{1,"Alias da tabela ",cArqDic ,"!!!",'.T.',,'.T.',40,.F.}) 
	//   aAdd( aPergs ,{1,"Filtro Registros ",cFiltDic,"@!",'.T.',,'.T.',100,.F.}) 
	If ParamBox(aPergs ,"Confirme Dados",aRet)

		cArqDic  := aRet[1]

		DbSelectArea(cArqDic)

		cFiltro := StaticCall(APSDU, SduExp)

		If ! Empty(cFiltro)
			DbSetfilter({|| &(cFiltro)}, cFiltro)
		Else
			DbClearFilter()
		Endif

		fShowTrab(cArqDic)
		/*
		aStruct := DbStruct()
		aCpoBrw := {}

		For _i:=1 to Len(aStruct)
		AADD(aCpoBrw,{aStruct[_i][1],,aStruct[_i][1]})
		Next
		DbGoTop()
		oBrowseSQL := MsSelect():New(cArqDic,"","",aCpoBrw,.F.,"",{160,001,295,588})  	
		//oBrowseSQL:blDblClick := {|| fSduEditCel(oBrowseSQL,oBrowseSQL:nColPos,,.f.)} 

		oBrowseSQL:oBrowse:Refresh()
		*/
	EndIf
	Set(_SET_DELETED, .T.)

Return nil

Static Function fRun(_aPosicoes,_oJanela)
	Local aCpoBrw	:= {}
	Local cResult   := ""
	Local aStruct := {}
	Local _i := 0
	Local j := 0
	Local a_Qry := {}
	Local n_Pos := iif(type("oTMultiget2")=='O',oTMultiget2:nPos,1)
	Local n_TPos := 0
	Local n_PsBlB := 1
	Local n_PsBlE := 1
	Local a_QryTxt := {}

	If type("oBrowseSQL")=='O'
		oBrowseSQL:End()	
	EndIf
	if type("oResult") =="O"
		oResult:End()
	endif

	//	If File(c_Pth)
	//		If FErase(c_Pth,,.T.) = -1
	//			MessageBox('Não foi possível excluir o arquivo ' + c_Pth , 'AVISO', 16)
	//		Endif
	//	Endif
	//	
	//	Sleep(100)

	If _aPosicoes == nil
		MemoWrite(c_Pth,_cQueryTxt)
		cBkpSql := _cQueryTxt
		_cQueryTxt := Ltrim(StrTran(_cQueryTxt,CRLF,CRLF+"§$@"))
		a_Qry := StrToArray(_cQueryTxt,CRLF)
		n_PsBlE := Len(a_Qry)
		For _i := 1 to Len(a_Qry)
			a_Qry[_i] := StrTran(a_Qry[_i],"§$@","")
			if n_TPos < n_Pos
				If AllTrim(a_Qry[_i]) = ''
					n_PsBlB := _i
				Endif
			Endif
			n_TPos += Len(a_Qry[_i] + CRLF)

			if n_TPos > n_Pos
				If AllTrim(a_Qry[_i]) = ''
					n_PsBlE := _i
					Exit
				Endif
			Endif
		Next
		_cQueryTxt := ""
		For _i := n_PsBlB to n_PsBlE
			If At('--',a_Qry[_i]) > 0
				If At('--',Alltrim(a_Qry[_i])) > 1
					_cQueryTxt += SubStr(AllTrim(a_Qry[_i]),1,At('--',Alltrim(a_Qry[_i])) - 1)  + " "
				Endif
			Else
				_cQueryTxt += a_Qry[_i] + " "
			Endif

			If SubStr(AllTrim(_cQueryTxt),Len(AllTrim(_cQueryTxt)),1) = ';'
				aadd(a_QryTxt,_cQueryTxt)
				_cQueryTxt := "" 
			Endif

		Next

		For _i:=1 to Len(a_QryTxt)
			_cQueryTxt +=  a_QryTxt[_i]
		Next

	EndIf


	_i:=1
	_cOper:={"DROP","TRUNCATE","INSERT","UPDATE","DELETE"}
	lSelect := .t.
	For _i:=1 to Len(_cOper)
		If AT(_cOper[_i],UPPER(_cQueryTxt))>0
			APMsgAlert("Alteracao de dados NAO permitida!",cTitulo)
			Return
		Endif
		If AT("UPDATE",UPPER(_cQueryTxt))>0 .or. AT("DELETE",UPPER(_cQueryTxt))>0 
			lselect := .f.
			exit
		Endif
	Next


	nStart  := 0
	nFinish := 0
	lParse  := .T.

	_cQueryTxt := AllTrim(_cQueryTxt)
	For j:=1 to Len(_cQueryTxt)
		If Substr(_cQueryTxt,j,2)=="<%"
			nStart ++
		EndIf
		If Substr(_cQueryTxt,j,2)=="%>"
			nFinish ++
		EndIf
	Next

	If nStart > 0 .AND. nStart <> nFinish
		Alert("Tags de Parametros Incorretas")
		lParse  := .F.
	EndIf

	If lSelect
		nStart  := 0
		nFinish := 0
		aPergs := {}
		aRet   := {}
		aParam := {}

		For j:=1 to Len(_cQueryTxt)
			If Substr(_cQueryTxt,j,2)=="<%"
				nStart := j+3
			EndIf

			If Substr(_cQueryTxt,j,2)=="%>"
				nFinish := j-1
			EndIf

			IF nStart > 0 .and. nFinish > 0
				If aScan(aParam,{|x| x==Substr(_cQueryTxt,nStart-1,nFinish-nStart+2)}) = 0
					AADD(aParam,Substr(_cQueryTxt,nStart-1,nFinish-nStart+2))
					cComando := Space(100)
					aAdd( aPergs ,{1,aParam[Len(aParam)],cComando,"@!",'.T.',,'.T.',100,.T.})
				EndIf  
				nStart  := 0
				nFinish := 0
			EndIf 
		Next

		IF len(aPergs)>0
			If ParamBox(aPergs ,"Parametros",aRet,/*aButtons*/,/*lCentered*/,/*nPosX*/,/*nPosy*/,/*oDlgWizard*/,/*cLoad*/,.F./*lCanSave*/,.F./*lUserSave*/ )
				For j := 1 to Len(aRet)
					_cQueryTxt := StrTran(_cQueryTxt,"<%"+aParam[j]+"%>","'"+ Iif(Empty(aRet[j]),' ',Alltrim(aRet[j])) +"'")    
				Next
			EndIf
		EndIf

		_nRet = TCSQLEXEC(_cQueryTxt)
		If _nRet<>0
			_cRet = TCSQLERROR()
			//APMsgAlert(AllTrim(_cRet),cTitulo)
			oResult := TMultiget():Create(oDlg1,{|u|if(Pcount()>0,_cRet:=u,_cRet)},160,001,588,170,oFont2,,,,,.T.,,,,,,,,,,,.T.)
			_cRet = TCSQLERROR()
			_cQueryTxt := cBkpSql
			Return
		EndIf

		GrvHst(_cQueryTxt)

		IF Select("WORK1")
			WORK1->(DbCloseArea())
		EndIf

		cTemp := Soma1(cTemp)
		_cMyAlias := "XDBF"+cTemp

		IF SELECT(_cMyAlias )
			DbSelectArea(_cMyAlias)
			DbCloseArea()
		EndIf
		MsAguarde({|| dbUseArea(.T., "TOPCONN", TCGenQRY(,,_cQueryTxt), "WORK1", .F., .T.) },"Consultando","Aguarde...")
		//		FWMsgRun(,{|| dbUseArea(.T., "TOPCONN", TCGenQRY(,,_cQueryTxt), "WORK1", .F., .T.) },"Aguarde","Executando")

		If !Select("WORK1")
			Alert("Erro ao executar "+_cQueryTxt)
			Return .f.
		EndIf

		DBSELECTAREA("WORK1")
		DBGOTOP()
		_aStruct:=DbStruct()
		aStruct := {}
		For j:= 1 to Len(_aStruct)
		    If !AllTrim(_aStruct[j,1]) $ "R_E_C_N_O_ , R_E_C_D_E_L_ , D_E_L_E_T_"
		       AADD(aStruct,_aStruct[j])
		    EndIf
		Next
		aCpoBrw:={}
		_i:=1
		dbSelectArea("SX3")
		dbSetOrder(2)


		a_Cmps := {"D_E_L_E_T_"}
		For _i:=1 to Len(aStruct)
			if dbSeek(aStruct[_i][1])
				cLabel := AllTrim(x3Titulo()) + " ("+ AllTrim(aStruct[_i][1]) +")"
			else
				cLabel := aStruct[_i][1]
			endif
			AADD(aCpoBrw,{aStruct[_i][1],,cLabel})
			AADD(a_Cmps,aStruct[_i][1])
		Next

		aSort(a_Cmps)

		_i:=1
		dbSelectArea("WORK1")
		For _i := 1 to Len(aStruct)
			If aStruct[_i,2] != "C"
				TCSetField("WORK1", aStruct[_i,1], aStruct[_i,2],aStruct[_i,3],aStruct[_i,4])
				If aStruct[_i,2] = "N"
					aStruct[_i,3]:=15
					aStruct[_i,4]:=02
				Endif
			Endif
		Next
		_cQueryTxt := cBkpSql
		//_cArq := CriaTrab(aStruct,.T.)
		//dbUseArea(.T.,,_cArq,_cMyAlias,.T.)
		//DbSelectArea(_cMyAlias)

		oTempTable := FWTemporaryTable():New(_cMyAlias,aStruct)
		oTempTable:Create()
		DbSelectArea(_cMyAlias) 
		
		FWMsgRun(,{|| fAppend() },"Aguarde","Executando 2")

		&(_cMyAlias)->(dbgotop())
		WORK1->(dbclosearea())

		If _aPosicoes == nil
			_aPosicoes := {160,001,295,588}
		EndIf
		oBrowseSQL := MsSelect():New(_cMyAlias,"","",aCpoBrw,.F.,"",_aPosicoes)  	
		oBrowseSQL:oBrowse:Refresh()	
	else
		cResult := ""
		If Len(a_QryTxt) > 0
			//Tratativa para update e delete

			cResult := ""
			For _i = 1 to Len(a_QryTxt)
				nSqlError := TcSqlExec(a_QryTxt[_i])

				if nSqlError <> 0
					cResult += "Qry "+ StrZero(_i,5) +" Erro: " + TcSqlError() + chr(13) + chr(10)
				else
					GrvHst(a_QryTxt[_i])
					cResult += "Qry "+ StrZero(_i,5) +" executado com sucesso." + TcSqlError() + chr(13) + chr(10)
				endif
			Next
		Else
			//Tratativa para update e delete
			nSqlError := TcSqlExec(_cQueryTxt)

			if nSqlError <> 0
				cResult := TcSqlError()
			else
				GrvHst(_cQueryTxt)
				cResult := "Comando executado com sucesso."+chr(13)+chr(10)+TcSqlError()
			endif
		Endif

		oResult := TMultiget():Create(oDlg1,{|u|if(Pcount()>0,cResult:=u,cResult)},160,001,588,170,oFont2,,,,,.T.,,,,,,,,,,,.T.)

		_cQueryTxt := cBkpSql

	endif

RETURN

Static Function fAppend()
	Append from WORK1
Return nil

Static Function fExport()
	Local oExcel 
	Local j := 0
	Local k := 0

	if Empty(_cMyAlias)
		Alert("Tabela Vazia")
		Return nil
	EndIf
	  
	oExcel := FWMSEXCEL():New()
	oExcel:AddworkSheet("Dados")
	oExcel:AddTable ("Dados","Planilha")

	DbSelectArea(_cMyAlias)
	nFields := FCount()
	for j:=1 to nFields
		       oExcel:AddColumn("Dados","Planilha",FieldName(j),1,1)
	next

	DbSelectArea(_cMyAlias)
	DbGoTop()

	Do While !EOF()
		aLinha := {}
		For k:=1 To FCount()
			If ValType(FieldGet(k))=="C"
				AADD(aLinha,NoAcento(FieldGet(k)))
			Else
				AADD(aLinha,FieldGet(k))
			Endif
		Next
		oExcel:AddRow("Dados","Planilha",aLinha)
		DbSkip()
	EndDo

	DbGoTop()

	oExcel:Activate()

	_cArquivo := AllTrim(c_Dtmp+'exporta.xml')+Space(1)

	_cDestino := ""
	aPergs := {}
	aRet   := {}
	aAdd( aPergs ,{6,"Arquivo",_cArquivo,"",,"", 100 ,.T.,"Arquivos .XML |*.XML","C:\",GETF_LOCALHARD})

	If ParamBox(aPergs ,"Planilha",aRet,/*aButtons*/,/*lCentered*/,/*nPosX*/,/*nPosy*/,/*oDlgWizard*/,/*cLoad*/,.F./*lCanSave*/,.F./*lUserSave*/ )
		_cDestino := Substr(aRet[1],1,Len(aRet[1])-1)
		_cArquivo := AllTrim(Substr(_cDestino,RAT("\",_cDestino)+1,40))
		_cPasta   := Alltrim(Substr(_cDestino,1,RAT("\",_cDestino)-1))

		MsAguarde({|| oExcel:GetXMLFile(_cArquivo) },"Gerando Planilha","Aguarde...")

		MsAguarde({|| CpyS2T( _cArquivo, _cPasta, .F. ) },"Copiando Planilha","Aguarde...")

		MsgInfo("Planilha Exportada em "+_cPasta)
		nRet := ShellExecute("open", _cArquivo, "", _cPasta, 1)
		IF nRet <= 32
			Alert("Nao foi possivel abrir " +_cPasta+_cArquivo+ "!")
		EndIf
	EndIf
Return .t.


Static Function Open()
	aPergs := {}
	aRet   := {}
	cArquivo := padr("",150)
	aAdd( aPergs ,{6,"Arquivo",cArquivo,"",,"", 90 ,.T.,"Arquivos  |*.*","C:\",GETF_LOCALHARD})

	If ParamBox(aPergs ,"Abrir",aRet)
		_cQueryTxt := MemoRead(aRet[1]) 
	EndIf

Return nil

Static Function Save()
	aPergs := {}
	aRet   := {}
	cArquivo := padr("",150)

	aAdd( aPergs ,{6,"Arquivo",cArquivo,"",,"", 90 ,.T.,"Arquivos |*.*","C:\",GETF_LOCALHARD})

	If ParamBox(aPergs ,"Salvar",aRet)
		If MemoWrite(aRet[1],_cQueryTxt) 
			MsgInfo("Salvo com Sucesso.")
		Else
			Alert("Falha ao Criar "+aRet[1])
		EndIf
	EndIf

Return nil

Static FUNCTION LstCmp()
	Local n_Pos := oTMultiget2:nPos

	If Len(a_Cmps) <> 0
		DEFINE DIALOG oDlg TITLE "Campos" FROM 180,180 TO 380,380 PIXEL
		aItems := a_Cmps
		nList := 1

		oList2 := TListBox():Create(oDlg,001,001,{|u|if(Pcount()>0,nList:=u,nList)},aItems,100,100,,,,,.T.)
		ACTIVATE DIALOG oDlg CENTERED

		_cQueryTxt := SubStr(_cQueryTxt,1,n_Pos) + a_Cmps[nList] + SubStr(_cQueryTxt,n_Pos)

		oTMultiget2:nPos := Len(SubStr(_cQueryTxt,1,n_Pos) + a_Cmps[nList]) 

	Endif
RETURN



Static Function Terminal()
	Local oError := ErrorBlock({|e| MsgAlert("Mensagem de Erro: " +chr(10)+ e:Description, "ERRO")})

	IF !MsgYesNo("Confirma Execblock?")
		Return nil
	EndIf
	  
	    cExpr := _cQueryTxt
	 
	    If !Empty(cExpr)
	        Begin Sequence    
	        	nReturn := &cExpr
	        Return .T.
	        End Sequence
	    EndIf
	 
	    ErrorBlock(oError)

Return .F.


Static Function fPowerShell()
	Local oError := ErrorBlock({|e| MsgAlert("Mensagem de Erro: " +chr(10)+ e:Description, "ERRO")})

	IF !MsgYesNo("Confirma Execucao?")
		Return nil
	EndIf
	  
	    cExpr := _cQueryTxt
	 
	    If !Empty(cExpr)
	        Begin Sequence    

	lOk := .t.

	FWMsgRun(,{|| lOk := WaitRunSrv( cExpr , .T. , "C:\" )  },"Executando PowerShell","Aguarde... ")

	IF lOk
		MsgInfo("Executado com sucesso!")
	Else 
		Alert("Erro na Execução")
	EndIf


	        Return .T.
	        End Sequence
	    EndIf
	 
	    ErrorBlock(oError)

Return .F.

Static Function GrvHst(c_Qry)
	Local nHandle
	Local a_Aux := {}
	Local c_Aux := ""
	Local n_I := 0

	If File(c_Hst)
		nHandle := FT_FUse(AllTrim(c_Hst))

		If nHandle == -1
			MessageBox('Não foi possível ler o arquivo ' + c_Hst , 'AVISO', 16)
		Else

			FT_FGoTop()

			While ! FT_FEof()

				AADD(a_Aux, FT_FReadLn())
				FT_FSkip()

			EndDo
			FT_FUSE()
		EndIf
	EndIf
	AADD(a_Aux, DtoC(Date()) + "-" + Time() +": " + c_Qry)

	For n_I := Iif(Len(a_Aux) < 1000, 1, Len(a_Aux) - 1000) to Len(a_Aux)   
		c_Aux +=  a_Aux[n_I] + CRLF 
	Next

	MemoWrite(c_Hst,c_Aux)
Return

Static function ShwHst(nPar)
	Local nHandle
	Local c_Aux := ""

	If nPar == 1 .AND. MsgYesNo("Limpa Historico?")
		fErase(AllTrim(c_Pth))
		Alert("Histórico Excluído! "+c_Hst)
		Return Nil
	EndIF

	If File(c_Hst)
		nHandle := FT_FUse(AllTrim(c_Hst))

		If nHandle == -1
			MessageBox('Não foi possível ler o arquivo ' + c_Hst , 'AVISO', 16)
		Else

			FT_FGoTop()

			While ! FT_FEof()
				c_Aux += FT_FReadLn() + CRLF 
				FT_FSkip()

			EndDo
			FT_FUSE()

			oResult := TMultiget():Create(oDlg1,{|u|if(Pcount()>0,c_Aux:=u,c_Aux)},160,001,588,170,oFont2,,,,,.T.,,,,,,,,,,,.T.)

		EndIf
	EndIf
Return

/*/{Protheus.doc} MudaAmb
//TODO Rotina para alterar caminho do Ambiente
@author emebatista
@since 26/12/2018
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
User Function MudaAmb()
	Local cRpoOld := ""
	Local cRpoNew := ""
	Local i
	Local nPar
	Local k

	aParam := {}
	aadd(aParam,"")
	For i:= 1 to 20
		aadd(aParam,space(180))
	Next

	cPergArq  := "MudaAmb" //"mudaamb"
	cPergArq2 := "MudaAmb2" //"mudaamb"
	

	aPerg      := {}

	For nPar := 1 to 20
		cItem := StrZero(nPar,2)
		&("MV_PAR"+cItem) := aParam[nPar] := PadR(ParamLoad(cPergArq,aPerg,nPar,aParam[nPar]),180)
	Next

	aadd(aPerg,{1,"Ambiente"  ,aParam[01],"","","",".T.",90,.F.})

	For nPar := 1 to 20
		aadd(aPerg,{1,"bin "+StrZero(nPar,2),aParam[nPar+1],"","","",".T.",180,.F.}) 	//
	Next

	aResp := {}
	If ParamBox(aPerg,"Escolha o Ambiente",aResp,,,,,,,cPergArq,.T.,.T.)
		For k:= 1 to len(aResp)
			If k>1 .and. !Empty(aResp[k])
				cRpoOld := GetPvProfString(AllTrim(aResp[1]), 'SourcePath', 'NaoEncontrado', aResp[k])
				//Alert(aResp[k]+">"+cRpoOld)
				If cRpoOld == "NaoEncontrado"
					Alert("Ambinete Nao Encontrado em "+aResp[k] + chr(10) + chr(13) + "Processo Cancelado.")
					Return .f.
				EndIf
			EndIf
		Next
		cAmbiente := AllTrim(aResp[1])
	Else
		Alert("Processo Cancelado.")
		Return .f.
	EndIf

	aResp2 := {}

	aParam2 := {}

	cRpoAux      := Substr(cRpoOld,Rat("\",Substr(cRpoOld,1,Len(cRpoOld)-1))+1,200)
	cRpoAux      := AllTrim(StrTran(cRpoAux,"\",""))
    cRpoOldAux   := cRpoAux
    cRpoNew      := Soma1(cRpoAux)
    cRpoNew    := StrTran(cRpoOld,cRpoOldAux,cRpoNew)

	aadd(aParam2,Pad(cRpoOld,100))
	aadd(aParam2,Pad(cRpoNew,100))

	aPerg2      := {}
	aadd(aPerg2,{1,"Localizar     "    ,aParam2[01],"","","",".T.",90,.F.}) 	//
	aadd(aPerg2,{1,"Substituir por"    ,aParam2[02],"","","",".T.",90,.F.}) 	//

	If ParamBox(aPerg2,"Alterar SourcePath",aResp2) //,,,,,,,cPergArq2,.T.,.T.)

		cRpoOld    := StrTran(AllTrim(aResp2[1]),"\","\\")

		cRPONew    := AllTrim(aResp2[2])

		cLog := "Arquivos Processados: "+chr(10)+chr(13)

		For k:=1 to Len(aResp)

			If k>1 .AND. !Empty(AllTrim(aResp[k]))

				cArqIni      := AllTrim(aResp[k])

				xComando    := 'powershell -Command "(Get-Content '+cArqIni+") -replace '"+cRpoOld+"' ,'"+cRpoNew
				xComando    += "' | Set-Content "+cArqIni+'" -encoding ASCII '
				qout(time()+" "+xComando)

				FWMsgRun(,{|| lOk := WaitRunSrv( xComando , .T. , "C:\" )  },"Alterando SourcePath.","Aguarde "+AllTrim(aResp[k]))

				/*
				If !WritePProString(cAmbiente, 'SourcePath', cRPONew, cArqIni)
				MsgInfo("Falha ao Atualizar "+cArqIni)
				EndIf

				If GetPvProfString(cAmbiente, "SourcePath", "NaoAchou", cArqIni) <> cRPONew
				MsgInfo("Falhou em  "+cArqIni)
				EndIf
				*/

				cLog += cArqIni + chr(10)+chr(13)

			EndIf
		Next

		MsgInfo("Processado com Sucesso!"+CHR(10)+CHR(13)+StrTran(cRpoOld,"\\","\")+">>"+cRPONew+chr(10)+chr(13)+cLog)

	Else
		Alert("Processo Cancelado!")
	EndIf

Return nil

User Function Promove()
	xComando := Pad("xcopy C:\Totvs\Protheus\apo\*.* C:\Totvs\ /Y",250)

	aParam := {}

	aadd(aParam,Pad("C:\Totvs\Protheus\apo\" ,250))
	aadd(aParam,Pad("C:\Totvs\Protheus\apo2\",250))

	cPergArq := "PromoveRPO" 

	aPerg      := {}

	MV_PAR01 := aParam[1] := PadR(ParamLoad(cPergArq,aPerg,1,aParam[1]),250)

	aadd(aPerg,{1,"Copiar RPO Origem  "  ,aParam[01],"","","",".T.",90,.F.}) 
	aadd(aPerg,{1,"Copiar RPO Destino "  ,aParam[02],"","","",".T.",90,.F.}) 

	aResp := {}	
	If ParamBox(aPerg,"Comando no Servidor",aResp,,,,,,,cPergArq,.T.,.T.)

		aResp[1] := AllTrim(aResp[1])
		aResp[2] := AllTrim(aResp[2])

		If Right(aResp[1],1)<>"\"
			aResp[1]+="\"
		EndIF

		If Right(aResp[2],1)<>"\"
			aResp[2]+="\"
		EndIF

		xComando := "xcopy "+ aResp[1]+"*.* "+aResp[2]+" /S /Y"

		lOk := .F.

		WaitRunSrv( "MD "+aResp[2],.T., "C:\")

		FWMsgRun(,{|| lOk := WaitRunSrv( xComando , .T. , "C:\" )  },"Copia de RPO.","Copiando "+AllTrim(aResp[1])+" para "+AllTrim(aResp[2]))

		IF lOk
			MsgInfo("Executado com sucesso!")
		Else 
			Alert("Erro na Execução")
		EndIf
	EndIf

Return nil

Static Function fCopiar()

	_cOrigem  := Space(80)
	_cDestino := Space(80)

	aPergs := {}
	aRet   := {}
	//               1   2             3      4  5 6   7    8      9            10
	aAdd( aPergs ,{6,"Arq.Origem" ,_cOrigem ,"",,"", 80 ,.F.,"Arquivos  |*.*","C:\", GETF_LOCALHARD + GETF_NETWORKDRIVE})
	If ParamBox(aPergs ,"Escolha a Origem",aRet)
		_cOrigem := aRet[1]
	EndIf

	aPergs := {}
	aRet   := {}
	//               1   2             3      4  5 6   7    8      9            10
	aAdd( aPergs ,{6,"Arq.Destino",_cDestino,"",,"", 80 ,.T.,"Pastas|*.*","\", GETF_RETDIRECTORY + GETF_LOCALHARD + GETF_NETWORKDRIVE })
	If ParamBox(aPergs ,"Escolha o Destino",aRet)
		_cDestino := aRet[1]
	EndIf

	lResult := .F.

	If Substr(_cOrigem,2,1)==":" .AND. Substr(_cDestino,2,1)<> ":"
		lResult := CpyT2S(_cOrigem,_cDestino)
	EndIf

	If Substr(_cOrigem,2,1)<>":" .AND. Substr(_cDestino,2,1)== ":"
		lResult := CpyS2T(_cOrigem,_cDestino)
	EndIf

	If lResult
		MsgInfo("Executado Com Sucesso!")
	Else
		Alert("Falha de Execução!")
	EndIF

Return nil

// Montagem do Grid
Static Function fShowTrab(_cAlias)
	Local oBrow
	Local cPict  	
	Local cAlias
	Local nPx
	Local nI
	Local cAlign
	Private aEstrut := {}
	lShared := .T.
	lRead   := .F.


	DbSelectArea(_cAlias)


	nPx := 1

	lNewStru	:= .F.

	oBrow := MsBrGetDBase():New( 160, 001, 580, 120,,,, oDlg1,,,,,,,,,,,, .F., _cAlias, .T.,, .F.,,, )
	//oBrow:Align := CONTROL_ALIGN_ALLCLIENT
	oBrow:nAt := 1

	aEstrut := DbStruct()

	For nI:= 1 to Len(aEstrut)
		If aEstrut[nI,2] <> "M"
			cAlign := "LEFT"
			cPict := ""
			If aEstrut[nI,2] == "N"
				cAlign := "RIGHT"
				If aEstrut[nI,4] >0
					cPict := Replicate("9",aEstrut[nI,3]-(aEstrut[nI,4]+1)) + "." + Replicate("9",aEstrut[nI,4])
				Else
					cPict := Replicate("9",aEstrut[nI,3])
				EndIf
			EndIf
			oBrow:AddColumn( TCColumn():New( aEstrut[nI,1], &("{ || "+_cAlias+"->"+aEstrut[nI,1]+"}"),cPict,,,cAlign) )
		Else
			oBrow:AddColumn( TCColumn():New( OemToAnsi(aEstrut[nI,1]), { || "Memo" },,,,,.F.) )
		EndIf
	Next

	oBrow:lColDrag   := .T.
	oBrow:lLineDrag  := .T.
	oBrow:lJustific  := .T.                    //StaticCall(APSDU, SduExp)
	oBrow:blDblClick := {|| fSduEditCel(oBrow,oBrow:nColPos,.f.)} //'Read Only!'
	oBrow:Cargo		 := {|| fSduEditCel(oBrow,oBrow:nColPos,.f.)}
	oBrow:nColPos    := 1                                                                        
	//oBrow:bChange	 := {|| SduRefreshStatusBar() }
	//oBrow:bGotFocus	 := {|| SduRefreshStatusBar() }
	oBrow:bDelOk	 := {|| fSduDeleteRecno(),oBrow:Refresh(.f.)}
	oBrow:bSuperDel	 := {|| fSduDeleteRecno(.F.),oBrow:Refresh(.f.)}
	oBrow:bAdd		 := {|| iIf( ApMsgYesNo("Adicionar Registro","Confirma?"),dbAppend(),)} //
	oBrow:SetBlkColor({|| If(Deleted(),CLR_WHITE,CLR_BLACK)})
	oBrow:SetBlkBackColor({|| If(Deleted(),CLR_LIGHTGRAY,CLR_WHITE)})

	oBrow:Refresh()
Return nil


// --------------------------------------------------------------------------------
// Executada a partir da função lEditCol(MsGetDados), está função permite a edição
// do campos no Grid
STATIC Function fSduEditCel(oBrowse,nCol,lReadOnly,aStruct)
	Local oDlg
	Local oRect
	Local oGet
	Local oBtn
	Local cMacro	:= ''
	Local nRow   	:= oBrowse:nAt
	Local oOwner 	:= oBrowse:oWnd
	Local nLastKey
	Local cValType
	Local nX
	Local cPict		:= ''
	Local aItems	:= {'.T.','.F.'}
	Local cCbx		:= '.T.'
	//Local cBarMsg	:= "Altera"
	Local cField
	Local aColumns	:= oBrowse:GetBrwOrder()
	Local nField
	Local lFkInUse  := .f. //SDUFkInUse()
	Local cInfo 	:= ''

	Default nCol  := oBrowse:nColPos
	Default lReadOnly := .F.

	aStruct := DbStruct()

	If !DbRLock(recno())
		cInfo += 'Record locked by another user.'+CRLF
		IF "TOP"$RDDNAME()
			cInfo += TcInternal(53)
		Endif
		SduMsg( { cInfo } ,2)
		Return
	Endif

	cField := aColumns[nCol][1]
	nField := Len(cField)
	nField := Ascan(oBrowse:aColumns,{|x| AllTrim(x:cHeading) == cField})
	cField := oBrowse:aColumns[nField]:cHeading

	oRect	 := tRect():New(0,0,0,0) // obtem as coordenadas da celula (lugar onde
	oBrowse:GetCellRect(nCol,,oRect) // a janela de edicao deve ficar)
	aDim  	 := {oRect:nTop,oRect:nLeft,oRect:nBottom,oRect:nRight}

	cMacro 	 := "M->CELL"+StrZero(nRow,6)
	&cMacro	 := FieldGet(FieldPos(cField))

	nX		 := Ascan(aStruct,{|x| x[1]==cField})
	cValType := aStruct[nX,2]
	If ( cValType == "N" )
		If ( aStruct[nX,4] > 0 )
			cPict := Replicate("9",aStruct[nX,3]-(aStruct[nX,4]+1)) + "." + Replicate("9",aStruct[nX,4])
		Else
			cPict := Replicate("9",aStruct[nX,3])
		EndIf
	ElseIf ( cValType == "D" )
		cPict := "@D"
	EndIf

	If ( cValType == 'M' )
		oMainWnd:SetMsg('Para gravar, Ctrl+W',.T.) //
		SetKey(23,{|| oDlg:End(), nLastKey:=13 })
		DEFINE MSDIALOG oDlg OF oOwner FROM 000,000 TO 050,400 STYLE nOR( WS_VISIBLE, WS_POPUP ) PIXEL
		oGet := TMultiGet():New(0,0,bSetGet(&(cMacro)),oDlg,399,049,oOwner:oFont,.F.,,,,.T.,,,,,, lReadOnly,,,,.F.)
		oGet:Move(-2,-2, (aDim[ 4 ] - aDim[ 2 ]) + 4, 062  )
		oGet:cReadVar  := cMacro
	Else
		DEFINE MSDIALOG oDlg OF oOwner  FROM 000,000 TO 000,000 STYLE nOR( WS_VISIBLE, WS_POPUP ) PIXEL
		If ( cValType == 'L' )
			cCbx := If(&(cMacro),'.T.','.F.')
			oGet := TComboBox():New( 0, 0, bSetGet(cCbx),aItems, 10, 10, oDlg,,{|| If(cCbx=='.T.',&(cMacro):=.T.,&(cMacro):=.F.), oDlg:End(), nLastKey:=13  },,,,.T., oOwner:oFont)
			oGet:Move(-2,-2, (aDim[ 4 ] - aDim[ 2 ]) + 4, aDim[ 3 ] - aDim[ 1 ] + 4 )
		Else
			oGet := TGet():New(0,0,bSetGet(&(cMacro)),oDlg,0,0,cPict,,,,oOwner:oFont,,,.T.,,,,,,,lReadOnly,,,,,,,,.T.)
			oGet:Move(-2,-2, (aDim[ 4 ] - aDim[ 2 ]) + 4, aDim[ 3 ] - aDim[ 1 ] + 4 )
			oGet:cReadVar  := cMacro
		EndIf
	EndIf

	@ 0, 0 BUTTON oBtn PROMPT "ze" SIZE 0,0 OF oDlg
	oBtn:bGotFocus := {|| oDlg:nLastKey := VK_RETURN, oDlg:End()}

	If ( cValType == 'M' )
		ACTIVATE MSDIALOG oDlg CENTERED  ON INIT oDlg:Move(aDim[1],aDim[2],aDim[4]-aDim[2], 60)  VALID ( nLastKey := oDlg:nLastKey, .T. )
	Else
		ACTIVATE MSDIALOG oDlg ON INIT oDlg:Move(aDim[1],aDim[2],aDim[4]-aDim[2], aDim[3]-aDim[1])  VALID ( nLastKey := oDlg:nLastKey, .T. )
	EndIf

	If ( nLastKey <> 0 )
		FieldPut(FieldPos(cField),(&cMacro))
		DbUnLock()
		DbCommit()
		oBrowse:nAt := nRow
		SetFocus(oBrowse:hWnd)
		oBrowse:Refresh()
	Else
		DbUnLock()
	EndIf

Return


STATIC Function fSduDeleteRecno(lConfirm)
	Local lDeleted	:= Deleted()
	Local cText		:= If( lDeleted, 'Recuperar registro?', 'Deletar registro?' ) //###
	Local lFkInUse  := .f.
	Local cInfo := '' 

	Default	lConfirm := .T.

	If ( Empty(Alias()) )
		Return
	EndIf

	If ( EOF() )
		StaticCall(SduMsg,{ 'Arquivo vazio!' } ,2) //
		Return
	EndIf

	If ( lConFirm )
		If ( !APMsgNoYes(cText,'Confirmar') ) //
			Return
		EndIf
	EndIf

	If !DbRLock(recno())

		cInfo += 'Record locked by another user.'+CRLF
		IF "TOP"$RDDNAME()
			cInfo += TcInternal(53)
		Endif
		StaticCall(SduMsg, { cInfo } ,2)

	Else

		Begin Sequence

			If ( Deleted() )
				DbRecall()
			Else
				DbDelete()
			EndIf
			DbRUnlock()
			DbCommit()

		End Sequence

		NetErr(.f.)

	Endif

Return

// Mostra uma tela de help com as funcionalidades
static function fHelp()
	MSGInfo(/*"<h1>Help QSQL</h1>" +*/; 
	"<h2>Teclas rápidas do QSQL</h2>" +;
	"<b>F5:</b> Executa o comando SQL." +;
	"<br><b>CTRL + seta para baixo:</b> Abre a lista de campos." +;
	"<h2>Funções (botões) do QSQL</h2>" +;
	"<b>Executa:</b> Executa o comando SQL." +;
	"<br><b>Exporta XML:</b> Exporta o resultado da consulta no formato XML (pode ser importado no Excel)." +;
	"<br><b>Abrir:</b> Abre qualquer arquivo para edição (local ou remoto). Útil para editar arquivos de menus, além de scripts SQL." +;
	"<br><b>Salvar:</b> Salva o texto que está na tela em um arquivo. Pode ser qualquer extensão, inclusive menus." +;
	"<br><b>Exec. Fórmula:</b> Executa uma ou mais user functions ou scripts em ADVPL, em sequencia, separados por vígula(,)." +;
	"<br><b>Editar Tabela:</b> Permite editar (inc./alt./exc./recuperação) das linhas (registros) de uma tabela aberta (SX ou DB)." +;
	"<br><b>Histórico:</b> Carrega o histórico de comandos." +;
	"<br><b>Limpa Hist.:</b> Limpar o histórico, caso necessário." +;
	"<br><b>Mudar RPO:</b> Muda o caminho do RPO no .ini (appserver.ini), permitindo mudança a quente. Apenas em Windows." +;
	"<br><b>Copia RPO:</b> Faz uma cópia do RPO para outra pasta, facilitando a criação de cópias de segurança." +;
	"<br><b>Comando no Srv.:</b> Executa um comando no servidor. Exemplo: reiniciar TSS, executar .BAT, etc." +;
	"<br><b>Copia Arquvos:</b> Copia arquivos da pasta local para o servidor ou vice versa. Exemplo: cópia de patches ou substituição de menu." +;
	"<br><b>Help:</b> Mostra esta tela de help." +;
	"<br><b>Sair:</b> Fecha este utilitário." +;
	"";
	)
return

User function SqlFile()
	Local aRet := {Space(100)}
	Local aPergs := {}
	Local l_Ret := .F.
	Local c_Sql := ""
	Local c_Arq := ""
	Local c_Pst := "\sqlfile\"

	If ! FWMakeDir(c_Pst,.T.)
		Aviso("Atenção","Inconsistência ao criar diretorio " + c_Pst,{"Ok"})
		Return
	Endif
	//
	//6 - File
	//[2] : Descrição
	//[3] : String contendo o inicializador do campo
	//[4] : String contendo a Picture do campo
	//[5] : String contendo a validação
	//[6] : String contendo a validação When
	//[7] : Tamanho do MsGet
	//[8] : Flag .T./.F. Parâmetro Obrigatório ?
	//[9] : Texto contendo os tipos de arquivo
	//Ex.: &quot;Arquivos .CSV |*.CSV&quot;
	//[10]: Diretório inicial do CGETFILE()
	//[11]: Parâmetros do CGETFILE()

	If GetRemoteType() = 2
		aAdd( aPergs ,{6,"Arquivo"	,	aRet[1],"",'.T.','.F.',80,.T.,"Arquivos .TXT |*.TXT","SERVIDOR/sqlfile/",4})
	Else
		aAdd( aPergs ,{6,"Arquivo"	,	aRet[1],"",'.T.','.F.',80,.T.,"Arquivos .TXT |*.TXT","SERVIDOR\sqlfile\",4})
	Endif



	l_Ret := ParamBox(aPergs ,"Arquivo",@aRet,/*aButtons*/,/*lCentered*/,/*nPosX*/,/*nPosy*/,/*oDlgWizard*/,/*cLoad*/,.F./*lCanSave*/,.F./*lUserSave*/ )

	If l_Ret
		If GetRemoteType() = 2
			c_Arq := c_Pst + SubStr(aRet[1],3)
		Else
			c_Arq := c_Pst + SubStr(aRet[1],2)
		Endif

		If !Empty(c_Arq)
			If File(c_Arq)
				nHandle := FT_FUse(AllTrim(c_Arq))

				If nHandle == -1
					MessageBox('Não foi possível ler o arquivo ' + c_Arq , 'AVISO', 16)
				Else
					FT_FGoTop()
					While ! FT_FEof()
						c_Sql += Alltrim(FT_FReadLn()) + CRLF
						FT_FSkip()
					EndDo
					FT_FUSE()
				EndIf

				U_QSQL(c_Sql)
			Else
				MessageBox('O arquivo não foi encontrado: ' + c_Arq , 'AVISO', 16)
			Endif
		Endif
	Endif


Return l_Ret


static FUNCTION NoAcento(cString)
	Local cChar  := ""
	Local nX     := 0 
	Local nY     := 0
	Local cVogal := "aeiouAEIOU"
	Local cAgudo := "áéíóú"+"ÁÉÍÓÚ"
	Local cCircu := "âêîôû"+"ÂÊÎÔÛ"
	Local cTrema := "äëïöü"+"ÄËÏÖÜ"
	Local cCrase := "àèìòù"+"ÀÈÌÒÙ" 
	Local cTio   := "ãõÃÕ"
	Local cCecid := "çÇ"
	Local cMaior := "&lt;"
	Local cMenor := "&gt;"

	If !Empty(cString)
		For nX:= 1 To Len(cString)
			cChar:=SubStr(cString, nX, 1)
			IF cChar$cAgudo+cCircu+cTrema+cCecid+cTio+cCrase
				nY:= At(cChar,cAgudo)
				If nY > 0
					cString := StrTran(cString,cChar,SubStr(cVogal,nY,1))
				EndIf
				nY:= At(cChar,cCircu)
				If nY > 0
					cString := StrTran(cString,cChar,SubStr(cVogal,nY,1))
				EndIf
				nY:= At(cChar,cTrema)
				If nY > 0
					cString := StrTran(cString,cChar,SubStr(cVogal,nY,1))
				EndIf
				nY:= At(cChar,cCrase)
				If nY > 0
					cString := StrTran(cString,cChar,SubStr(cVogal,nY,1))
				EndIf		
				nY:= At(cChar,cTio)
				If nY > 0          
					cString := StrTran(cString,cChar,SubStr("aoAO",nY,1))
				EndIf		
				nY:= At(cChar,cCecid)
				If nY > 0
					cString := StrTran(cString,cChar,SubStr("cC",nY,1))
				EndIf
			Endif
		Next
	Endif

	If cMaior$ cString 
		cString := strTran( cString, cMaior, "" ) 
	EndIf
	If cMenor$ cString 
		cString := strTran( cString, cMenor, "" )
	EndIf

	If '>'$ cString 
		cString := strTran( cString, '>', "" ) 
	EndIf

	If '<'$ cString 
		cString := strTran( cString, '<', "" )
	EndIf

	If '&'$ cString 
		cString := strTran( cString, '&', " e " )
	EndIf

	cString := StrTran( cString, CRLF, " " )

Return cString



