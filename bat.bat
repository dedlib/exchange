:COMMLOG
if not exist "CommLog.txt" (color 74 & echo:Не найден CommLog.txt в каталоге с LOG ANALYZER & TIMEOUT /T 5 & color 70 & goto MENU)
copy /Y CommLog.txt com_copy.txt>nul
set "c=com_copy.txt"
set "x=.\REPORT\REPORT_CommLog.txt"
set count=0

rem словарь ascii
set "ascii_table=   #$%%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~ АБВГДЕЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдежзийклмноп________________________________________________рстуфхцчшщъыьэюя"
set "ascii[33]=^!" & set "ascii[34]=""

rem отчищаем rep.txt
echo:>%x% & more +1 "%x%">"l" & move /Y "l" "%x%">nul
rem отчищаем hex.txt
echo:>hex.txt & more +1 "hex.txt">"l" & move /Y "l" "hex.txt">nul
rem отчищаем frame.txt
echo:>frame.txt & more +1 "frame.txt">"l" & move /Y "l" "frame.txt">nul
rem отчищаем flag.txt
echo:>flag.txt & more +1 "flag.txt">"l" & move /Y "l" "flag.txt">nul

rem анимация работы утилиты
for /f "usebackq" %%S in (`find /c /v ""^<%c%`) do (set NumStr=%%S)

:COMMLOG_START
for /f "usebackq" %%S in (`find /c /v ""^<%c%`) do (set NuStr=%%S)
set /a NStr = ((%NumStr%-%NuStr%)*100/%NumStr%)
set /a Str = %NStr%/2
cls
if !NuStr! EQU 0 goto :COMMLOG_END
echo:
echo:   -----------------------------------
echo:        Идёт анализ CommLOG, ждите. 
echo:   -----------------------------------
echo: 
set /p X=!loading:~0,%Str%!<Nul
echo: 
set /p Y= Выполнено !NStr! %%<Nul
echo: 
set /p Y= Всего !NumStr! строк. Осталось !NuStr! строк <Nul

rem разбор лога по строкам
for /f "tokens=* delims=//n" %%a in (%c%) do (
	more +1 %c%>"TEMP" & move "TEMP" %c%>nul
	set "str=%%a" & set /a count=!count!+1
	<nul set /p=!count!: >>%x%
	rem дата и время в отчет
	<nul set /p=!str:~0,14! >>%x%
	rem направление
	if "!str:~15,1!" == ">" (<nul set /p=^>от кассы^> >>%x%)
	if "!str:~15,1!" == "<" (<nul set /p=^<на кассу^< >>%x%)
	rem разбор признака
	if "!str:~15,1!" == "+" (<nul set /p=Подключение>>%x% & echo:>>%x% & goto COMMLOG_START)
	if "!str:~15,1!" == "-" (<nul set /p=Отключение>>%x% & echo:>>%x% & goto COMMLOG_START)
	if "!str:~17,1!" == "" (<nul set /p=Часть кадра успешно принята>>%x% & echo:>>%x% & goto COMMLOG_START)
	if "!str:~17,1!" == "" (<nul set /p=Часть кадра успешно принята>>%x% & echo:>>%x% & goto COMMLOG_START)
	if "!str:~17,1!" == "" (<nul set /p=Принятый кадр содержит ошибку>>%x% & echo:>>%x% & goto COMMLOG_START)
	if "!str:~17,1!" == "" (<nul set /p=Кадр принят>>%x% & echo:>>%x%
		echo:>frame.txt & more +1 "frame.txt">"l" & move /Y "l" "frame.txt">nul
		goto :COMMLOG_START)
	
	rem описание кадра	
	if "!str:~17,1!" == "" (		
		rem инфо кадр
		if "!str:~18,1!" NEQ "#" (
			<nul set /p"=Информационный кадр, ">>%x%
			<nul set /p"=^[!str:~18,-1!^]" >>%x%
			echo !str:~18,-1!>base
			.\tools\base64 -d base | .\tools\hexdump>hex
			rem обработка hex
			for /f "tokens=* delims=//n" %%s in (hex) do (
				set st=%%s
				rem удаляем пробелы
				set st=!st: =!
				rem удаляем переносы и переносим в hex.txt
				<nul set /p=!st:~6!>>hex.txt
				)			
			rem забираем hex значение
			for /f %%t in (hex.txt) do (set telo=%%t)
			rem очищаем hex.txt
			echo:>hex.txt & more +1 "hex.txt">"l" & move /Y "l" "hex.txt">nul
			rem собираем кадры из частей переносим frame.txt
			<nul set /p=!telo:~4,-4!>>frame.txt
			rem забираем текст кадра
			for /f %%f in (frame.txt) do (set frame=%%f)
			echo:>>%x%
			<nul set /p"=^.....[!frame!^]" >>%x%
			echo:>>%x%
			echo:>frame.txt
			echo:>>%x%
			goto :COMMLOG_START
			)
		rem обычный кадр
		rem "формат кадра" в отчет
		if "!str:~18,1!" == "#" (<nul set /p"=Обычный кадр, ">>%x%)
		rem проверка флага конец сообщения		
		rem если последний символ равен  переносим в base
		if "!str:~-1!" EQU "" (echo !str:~19,-1!>base)
		rem если нет признака конца кадра, собираем кадр пока его не будет
		rem последний символ не равен 
		if "!str:~-1!" NEQ "" (
			rem переносим сообщение в base
			<nul set /p"=!str:~19!">base
			rem берем следующую строку с лога
			for /f "tokens=* delims=//n" %%a in (%c%) do (
				more +1 %c% >"TEMP" & move "TEMP" %c% >nul
				set "str=%%a" & set /a "count=!count!+1"
				rem если последний символ равен 
				if "!str:~-1!" == "" (
					rem добавляем в base и переходим к метки ЕТХ
					<nul set /p"=!str:~17,-1!">>base & goto ETX
					rem иначе добавляем в base
					) else (<nul set /p"=!str:~17!">>base)
				)
			)
		
		
		:ETX
		rem декодируем из формата base64 кадра base, в формат hex и записываем в файл hex
		.\tools\base64 -d base | .\tools\hexdump>hex
		rem обработка hex
		for /f "tokens=* delims=//n" %%s in (hex) do (
			set st=%%s
			rem удаляем пробелы
			set st=!st: =!
			rem удаляем переносы и переносим в hex.txt
			<nul set /p=!st:~6!>>hex.txt
			)
		rem очищаем hex
		echo:>hex & more +1 "hex">"l" & move /Y "l" "hex">nul
		rem забираем hex значение
		for /f %%t in (hex.txt) do (set telo=%%t)
		rem очищаем hex.txt		
		echo:>hex.txt & more +1 "hex.txt">"l" & move /Y "l" "hex.txt">nul
		rem собираем кадры из частей переносим frame.txt
		<nul set /p=!telo:~4,-4!>>frame.txt
		set "frame=Не смог декодировать"
		rem забираем текст кадра
		for /f %%f in (frame.txt) do (set frame=%%f)		
		rem вычесляем длину кадра
		rem set "string=!telo:~4,-4!" 
		for /f %%i in ('">$ cmd /v /c echo.!frame!& echo $"') do (set/a l=%%~zi-2 & del $) 
		set /a len"=!l!/2"
		rem вывод информации в отчет		
		rem номер кадра		
		<nul set /p"=Кадр !telo:~1,1!, " >>%x%
		rem длина переданая в кадре
		set /A DEC"=0x!telo:~2,2!"
		set /a ADEC"=!DEC! %% !len!"
		rem сверяем длину кадра и передаваемую длину, если не совпадает выводим сообщение
		if !ADEC! NEQ 0 (if !ADEC! NEQ !DEC! (<nul set /p"=Длина !DEC! байт НЕ СОВПАДАЕТ, " >>%x%))
		rem контрольная сумма кадра
		rem <nul set /p"=CRC16-!telo:~-4!, " >>%x%
		
		rem сообщение кадра
		rem если часть кадра
		rem if "!DEC!" EQU "180" (<nul set /p"=[Есть продолжение кадра]" >>%x% & echo:>>%x% & goto COMMLOG_START)
		rem анализ полного кадра
		if "!DEC!" NEQ "1800" (
			echo:>frame.txt
			<nul set /p"=[!frame!]">>%x%
			echo:>>%x%
			
			rem флаг команды
			if "!frame:~0,2!" NEQ "00" (
				set "flag=!frame:~0,2!" & set "num_mes=!frame:~6,8!"
				echo:!num_mes!-!flag!>>flag.txt
				)
			
			rem коды команд CMD_PILOT_TRX
			if "!frame:~0,2!" == "6d" (
				if /i "!frame:~14,8!" EQU "fafaffff" (
					rem TLV структуры
					echo 	КОМАНДА - Проведение платежа и технологических операций (TLV^)>>%x%					
					set "TLV=!frame:~22!" & call :OPER_TLV & goto :COMMLOG_START
					) else (
					rem Cериализованные данные
					echo 	КОМАНДА - Проведение платежа и технологических операций >>%x%
					rem сумма
					set /A DEC"=0x!frame:~20,2!!frame:~18,2!!frame:~16,2!!frame:~14,2!"
					<nul set /p"=......Сумма операции: !DEC:~0,-2!.!DEC:~-2!; ">>%x%
					rem тип карты
					<nul set /p"=Тип карты: ">>%x%
					set /A DEC"=0x!frame:~22,2!"
					findstr /b "!DEC!" .\LIBRARY\card_type.txt>card
					for /f "tokens=1,2 delims=-" %%1 in (card) do (<nul set /p"=%%2; ">>%x%)					
					rem отдел
					set /A DEC"=0x!frame:~24,2!"
					<nul set /p"=Номер отдела в списке: !DEC!; ">>%x%
					echo:>>%x%
					rem тип операции
					<nul set /p"=......Тип операции: ">>%x%
					set /A DEC"=0x!frame:~26,2!"
					if "!DEC:~1,1!"=="" (set "DEC=0!DEC!")
					findstr /b "!DEC!" .\LIBRARY\oper_type.txt>oper
					for /f "tokens=1,2 delims=-" %%1 in (oper) do (<nul set /p"=%%2; ">>%x%)					
					rem Уникальный номер операции
					set /A DEC"=0x!frame:~114,2!!frame:~112,2!!frame:~110,2!!frame:~108,2!"
					<nul set /p"=RequestID: !DEC!; ">>%x%					
					rem Ссылочный номер транзакции
					<nul set /p"=RRN: ">>%x%
					set "hexus=!frame:~116,26!" & call :RRN1
					echo:>>%x% & goto :COMMLOG_START
					:RRN1
					if defined hexus (
						set /A "char=0x!hexus:~0,2!"
						call :hex_ascii
						set "hexus=!hexus:~2!"
						) else (exit /b 0)
					goto :RRN1
					)
				)
			
			rem CMD_MASTERCALL
			if "!frame:~0,2!" == "a0" (
				echo 	КОМАНДА - Управления пользовательским интерфейсом >>%x%
				if "!frame:~14,2!" == "01" (<nul set /p"=......Открыть -> ">>%x%)
				if "!frame:~14,2!" == "02" (<nul set /p"=......Читать данные -> ">>%x%)
				if "!frame:~14,2!" == "03" (<nul set /p"=......Писать данные -> ">>%x%)
				if "!frame:~14,2!" == "04" (<nul set /p"=......Закрыть -> ">>%x%)
				
				set /A DEC"=0x!frame:~16,2!"
				if "!DEC!" == "0" (<nul set /p"=не используется">>%x% & echo:>>%x% & goto :COMMLOG_START)
				
				if "!DEC!" == "3" (
					<nul set /p"=принтер">>%x% & echo:>>%x%
				
					if "!frame:~14,2!" == "01" (
						if "!frame:~24,2!" == "00" (<nul set /p"=......Нормальный режим открытия; ">>%x%)
						if "!frame:~24,2!" == "01" (<nul set /p"=......Повтор экземпляра последнего чека; ">>%x%)
						echo:>>%x%
						)						
					if "!frame:~14,2!" == "03" (
						if "!frame:~24,2!" == "00" (<nul set /p"=......Печатать обычным шрифтом;">>%x%)
						if "!frame:~24,2!" == "10" (<nul set /p"=......Печатать жирным шрифтом;">>%x%)
						if "!frame:~24,2!" == "20" (<nul set /p"=......Печатать шрифтом удвоенной высоты;">>%x%)
						if "!frame:~24,2!" == "30" (<nul set /p"=......Печатать жирным шрифтом удвоенной высоты;">>%x%)
						if "!frame:~24,2!" == "40" (<nul set /p"=......Печатать шрифтом удвоенной ширины;">>%x%)
						if "!frame:~24,2!" == "50" (<nul set /p"=......Печатать жирным шрифтом удвоенной ширины;">>%x%)
						if "!frame:~24,2!" == "60" (<nul set /p"=......Печатать шрифтом удвоенной высоты и ширины;">>%x%)
						if "!frame:~24,2!" == "70" (<nul set /p"=......Печатать жирным шрифтом удвоенной высоты и ширины;">>%x%)
						if "!frame:~24,2!" == "80" (<nul set /p"=......Печатать инверсным шрифтом;">>%x%)
						echo:>>%x% & <nul set /p"= [">>%x%
						set "hexus=!frame:~26,-2!" & call :031
						<nul set /p"=]">>%x% & echo:>>%x% & goto :COMMLOG_START
						:031
						if defined hexus (
							set /A "char=0x!hexus:~0,2!"
							call :hex_ascii
							set "hexus=!hexus:~2!"
							) else (exit /b 0)
						goto :031
						)
					)					

				if "!DEC!" == "5" (<nul set /p"=проверка связи">>%x% & echo:>>%x% & goto :COMMLOG_START)
				
				if "!DEC!" == "25" (
					<nul set /p"=сетевой интерфейс; ">>%x% & echo:>>%x%
					
					if "!frame:~14,2!" == "01" (
						rem скорость порта
						if "!frame:~24,2!" == "00" (<nul set /p"=......Скорость порта: 300; ">>%x%)
						if "!frame:~24,2!" == "01" (<nul set /p"=......Скорость порта: 1200; ">>%x%)
						if "!frame:~24,2!" == "02" (<nul set /p"=......Скорость порта: 2400; ">>%x%)
						if "!frame:~24,2!" == "03" (<nul set /p"=......Скорость порта: 4800; ">>%x%)
						if "!frame:~24,2!" == "04" (<nul set /p"=......Скорость порта: 9600; ">>%x%)
						if "!frame:~24,2!" == "05" (<nul set /p"=......Скорость порта: 14400; ">>%x%)
						if "!frame:~24,2!" == "06" (<nul set /p"=......Скорость порта: 19200; ">>%x%)
						if "!frame:~24,2!" == "07" (<nul set /p"=......Скорость порта: 38400; ">>%x%)
						if "!frame:~24,2!" == "08" (<nul set /p"=......Скорость порта: 57600; ">>%x%)
						if "!frame:~24,2!" == "09" (<nul set /p"=......Скорость порта: 115000; ">>%x%)
						if "!frame:~24,2!" == "ff" (<nul set /p"=......Скорость порта неизвестна; ">>%x%)
						rem режим работы порта
						if "!frame:~26,2!" == "80" (<nul set /p"=Режим работы порта: PULSE DIAL; ">>%x%)
						if "!frame:~26,2!" == "40" (<nul set /p"=Режим работы порта: PREDIAL; ">>%x%)
						if "!frame:~26,2!" == "20" (<nul set /p"=Режим работы порта: USE PPP; ">>%x%)
						if "!frame:~26,2!" == "10" (<nul set /p"=Режим работы порта: LISTEN; ">>%x%)
						if "!frame:~26,2!" == "08" (<nul set /p"=Режим работы порта: BREAK LINE; ">>%x%)
						if "!frame:~26,2!" == "04" (<nul set /p"=Режим работы порта: ODD PARITY; ">>%x%)
						if "!frame:~26,2!" == "02" (<nul set /p"=Режим работы порта: USE PARITY; ">>%x%)
						if "!frame:~26,2!" == "01" (<nul set /p"=Режим работы порта: 7BIT; ">>%x%)
						rem IP адрес
						set /A DEC"=0x!frame:~28,2!" & <nul set /p"=IP адрес: !DEC!.">>%x%
						set /A DEC"=0x!frame:~30,2!" & <nul set /p"=!DEC!.">>%x%
						set /A DEC"=0x!frame:~32,2!" & <nul set /p"=!DEC!.">>%x%
						set /A DEC"=0x!frame:~34,2!" & <nul set /p"=!DEC!; ">>%x%
						rem IP порт
						set /A DEC"=0x!frame:~38,2!!frame:~36,2!" & <nul set /p"=IP порт: !DEC!; ">>%x%
						rem таймаут
						set /A DEC"=0x!frame:~46,2!!frame:~44,2!!frame:~42,2!!frame:~40,2!" & <nul set /p"=Таймаут !DEC! мсек.">>%x%
						echo:>>%x%
						goto :COMMLOG_START
						)
						
					if "!frame:~14,2!" == "02" (
						rem Максимальная длина читаемых данных
						set /A DEC"=0x!frame:~26,2!!frame:~24,2!" & <nul set /p"=......Максимальная длина читаемых данных !DEC! байт; ">>%x%
						set /A DEC"=0x!frame:~30,2!!frame:~28,2!" & <nul set /p"=Таймаут ожидания данных на сокете !DEC! мсек; ">>%x%
						set /A DEC"=0x!frame:~32,2!"
						if "!DEC!" == "0" (<nul set /p"=Пинпад не будет ожидать уведомления">>%x%
							) else (
							<nul set /p"=Пинпад будет ожидать уведомления">>%x%
							)
						echo:>>%x%
						goto :COMMLOG_START
						)
						
					if "!frame:~14,2!" == "03" (
						<nul set /p"=......[">>%x%
						set "hexus=!frame:~24!" & call :251
						<nul set /p"=......]">>%x% & echo:>>%x% & goto COMMLOG_START
						:251
						if defined hexus (
							set /A "char=0x!hexus:~0,2!"
							call :hex_ascii
							set "hexus=!hexus:~2!"
							) else (exit /b 0)
						goto 251
						)
					)
					
				if "!DEC!" == "39" (
					<nul set /p"=обмен информацией о состоянии устройств">>%x% & echo:>>%x%
					
					if "!frame:~14,2!" == "03" (
						if "!frame:~24,2!" == "00" (<nul set /p"=......Текстовая строка описывает текущее состояние хоста; ">>%x%)
						if "!frame:~24,2!" == "01" (<nul set /p"=......Текстовая строка содержит сообщение для кассира; ">>%x%)
						if "!frame:~26,2!" == "00" (<nul set /p"=Состояние хоста - стабильное; ">>%x%)
						if "!frame:~26,2!" == "01" (<nul set /p"=Состояние хоста - предупреждение; ">>%x%)
						if "!frame:~26,2!" == "02" (<nul set /p"=Состояние хоста - ошибка; ">>%x%)
	
						set "hexus=!frame:~28!" & call :391 & echo:>>%x% & goto COMMLOG_START
						:391
						if defined hexus (
							set /A "char=0x!hexus:~0,2!"
							call :hex_ascii
							set "hexus=!hexus:~2!"
							) else (exit /b 0)
						goto 391						
						)
					)
						
				if "!DEC!" == "41" (<nul set /p"=уведомление о перезагрузке при обновлении ПО">>%x% & echo:>>%x% & goto :COMMLOG_START)
				
				if "!DEC!" == "45" (
					<nul set /p"=передачи статусных сообщений">>%x% & echo:>>%x%
					if "!frame:~14,2!" == "01" (
						set /A DEC"=0x!frame:~30,2!!frame:~28,2!!frame:~26,2!!frame:~24,2!" & <nul set /p"=......Таймаут !DEC! сек.; ">>%x%
						set /A DEC"=0x!frame:~32,2!"
						if "!DEC!" == "0" (<nul set /p"=Ввод карты">>%x%)
						if "!DEC!" == "4" (<nul set /p"=Ввод ПИНа">>%x%)
						if "!DEC!" == "5" (<nul set /p"=Выбор приложения">>%x%)
						if "!DEC!" == "6" (<nul set /p"=Авторизация">>%x%)
						if "!DEC!" == "7" (<nul set /p"=Ожидание какого-либо действия">>%x%)
						if "!DEC!" == "8" (<nul set /p"=Ожидание извлечения">>%x%)
						if "!DEC!" == "9" (<nul set /p"=Ожидание ввода">>%x%)
						if "!DEC!" == "10" (<nul set /p"=Перезагрузка">>%x%)
						if "!DEC!" == "11" (<nul set /p"=Ввод бесконтактной карты">>%x%)
						if "!DEC!" == "12" (<nul set /p"=CARD_MIFARE">>%x%)
						if "!DEC!" == "13" (<nul set /p"=Извлечение карты">>%x%)
						echo:>>%x%
						)
					goto :COMMLOG_START
					)
				)
			
			rem CMD_GETREADY
			if "!frame:~0,2!" == "50" (
				echo 	КОМАНДА - Опрос готовности терминала/прерывание текущей операции >>%x%
				set /A DEC"=0x!frame:~14,8!" & <nul set /p"=......№ экранной формы !DEC!; ">>%x%
				set /A DEC"=0x!frame:~22,2!" & <nul set /p"=№ элемента экранной формы !DEC!; ">>%x%
				set /A DEC"=0x!frame:~24,2!" & <nul set /p"=Признак расширенных данных !DEC!">>%x%
				echo:>>%x%				
				goto COMMLOG_START
				)
			
			rem Проверка наличия карты в ридере
			if "!frame:~0,2!" == "ef" (
				echo 	КОМАНДА - Проверка наличия карты в ридере >>%x%
				set /A DEC"=0x!frame:~14,2!"
				if !DEC! EQU 0 (<nul set /p"=......клиентский ридер смарт-карт; ">>%x% & echo:>>%x% & goto COMMLOG_START)
				<nul set /p"=......SAM!DEC!">>%x% & echo:>>%x% & goto COMMLOG_START				
				)
			
			rem CMD_EMV_CONF_GET
			if "!frame:~0,2!" == "a5" (
				echo 	КОМАНДА - Получить значение настроек терминала >>%x%
				if "!frame:~16,8!" EQU "00009F1C" (<nul set /p"=......номер терминала; ">>%x%)
				if "!frame:~16,8!" EQU "00009F16" (<nul set /p"=......номер мерчанта; ">>%x%)
				echo:>>%x%
				goto COMMLOG_START
				)
			
			rem CMD_EMV_CONFIG
			if "!frame:~0,2!" == "ea" (
				echo 	КОМАНДА - Установка значений настроек терминала >>%x%
				if "!frame:~14,4!" EQU "9f1c" (
					<nul set /p"=......номер терминала: ">>%x%
					set "hexus=!frame:~20!" & call :ea1c1 & echo:>>%x% & goto COMMLOG_START
						:ea1c1
						if defined hexus (
							set /A "char=0x!hexus:~0,2!"
							call :hex_ascii
							set "hexus=!hexus:~2!"
							) else (exit /b 0)
						goto ea1c1
					)
				if "!frame:~14,4!" EQU "9f16" (
					<nul set /p"=......номер мерчанта: ">>%x%
					set "hexus=!frame:~20!" & call :ea161 & echo:>>%x% & goto COMMLOG_START
						:ea161
						if defined hexus (
							set /A "char=0x!hexus:~0,2!"
							call :hex_ascii
							set "hexus=!hexus:~2!"
							) else (exit /b 0)
						goto ea161
					)
				if "!frame:~14,4!" EQU "df41" (
					<nul set /p"=......TCP-порта хоста: ">>%x%
					set /A DEC"=0x!frame:~22,2!!frame:~20,2!"
					<nul set /p"=!DEC!">>%x% & echo:>>%x% & goto COMMLOG_START
					)
				)
			
			rem CMD_SETCONST
			if "!frame:~0,2!" == "15" (
				echo 	КОМАНДА - Установить константы в пинпаде >>%x%
				set /A DEC"=0x!frame:~14,2!"
				<nul set /p"=......Время ожидания карты: !DEC!; ">>%x%
				set /A DEC"=0x!frame:~16,2!"
				<nul set /p"=Время ожидания ввода Pin кода: !DEC!; ">>%x%
				set /A DEC"=0x!frame:~18,2!"
				<nul set /p"=Минимальная длина Pin кода: !DEC!; ">>%x%
				set /A DEC"=0x!frame:~24,2!"
				if !DEC! == 0 (<nul set /p"=Скорость интерфейса с ПЭВМ: 300;">>%x%)
				if !DEC! == 1 (<nul set /p"=Скорость интерфейса с ПЭВМ: 1200;">>%x%)
				if !DEC! == 2 (<nul set /p"=Скорость интерфейса с ПЭВМ: 2400;">>%x%)
				if !DEC! == 3 (<nul set /p"=Скорость интерфейса с ПЭВМ: 4800;">>%x%)
				if !DEC! == 4 (<nul set /p"=Скорость интерфейса с ПЭВМ: 9600;">>%x%)
				if !DEC! == 5 (<nul set /p"=Скорость интерфейса с ПЭВМ: 14400;">>%x%)
				if !DEC! == 6 (<nul set /p"=Скорость интерфейса с ПЭВМ: 19200;">>%x%)
				if !DEC! == 7 (<nul set /p"=Скорость интерфейса с ПЭВМ: 38400;">>%x%)
				if !DEC! == 8 (<nul set /p"=Скорость интерфейса с ПЭВМ: 57600;">>%x%)
				if !DEC! == 9 (<nul set /p"=Скорость интерфейса с ПЭВМ: 115000;">>%x%)
				echo:>>%x%
				goto COMMLOG_START
				)
			
			rem CMD_RUNSCREEN
			if "!frame:~0,2!" == "c0" (
				echo 	КОМАНДА - Отобразить экранную форму на экране >>%x%
				<nul set /p"=[">>%x%
				set "hexus=!frame:~40!" & call :c01 & <nul set /p"=]">>%x% & echo:>>%x% & goto COMMLOG_START
				set "prov=!hexus:~0,2!"
						:c01
						if defined hexus (
							set /A "char=0x!hexus:~0,2!"
							rem равно
							if !char! EQU 0 (set "prov=!hexus:~0,2!" & set "hexus=!hexus:~2!" & goto :c01)
							rem меньше
							if !char! LSS 32 (<nul set /p "=_" >>%x% & set "prov=!hexus:~0,2!" & set "hexus=!hexus:~2!" & goto :c01)
							rem больше или равно
							if !char! GEQ 32 (
								set /A "char1=0x!hexus:~2,2!"
								rem равно
								if "!prov!" EQU "00" (
									rem меньше
									if !char1! LSS 32 (
										set "prov=!hexus:~0,2!" & set "hexus=!hexus:~2!" & goto :c01
										) else (
										call :c02 & set "prov=!hexus:~0,2!" & set "hexus=!hexus:~2!" & goto :c01
										)
									) else (
									call :c02 & set "prov=!hexus:~0,2!" & set "hexus=!hexus:~2!" & goto :c01
									)
								call :c02 & set "prov=!hexus:~0,2!" & set "hexus=!hexus:~2!" & goto :c01
								)
							) else (exit /b 0)
						goto :c01
						:c02
						if !char! LSS 32 (<nul set /p "=_" >>%x% & exit /b 0)
						if !char! EQU 33 (<nul set /p"=!ascii[33]!">>%x% & exit /b 0)
						if !char! EQU 34 (<nul set /p"=!ascii[34]!">>%x% & exit /b 0)
						if !char! EQU 61 (<nul set /p"=!ascii[29]!">>%x% & exit /b 0)
						set /a "h=!char!-32"
						if !h! EQU 0 (<nul set /p "=_" >>%x% & exit /b 0)
						for /l %%0 in (0, 1, 208) do (
							if "%%0" EQU "!h!" (
								<nul set /p"=!ascii_table:~%%0,1!">>%x%
								exit /b 0
								)
							)
						<nul set /p"=]">>%x%
						echo:>>%x%
				goto COMMLOG_START
				)
				
			rem ответ на команды
			if "!frame:~0,2!" == "00" (
				echo:	ОТВЕТ: >>%x%
				set "DEC=!frame:~6,6!"
				if defined DEC (
					findstr /b !DEC! flag.txt>num_mes
					for /f "tokens=1,2 delims=-" %%1 in (num_mes) do (set "flag=%%2")
					FINDSTR /V !DEC! flag.txt>flag1.txt
					move /Y "flag1.txt" "flag.txt">nul
					) else (
					set "DEC=_"
					findstr /b !DEC! flag.txt>num_mes
					for /f "tokens=1,2 delims=-" %%1 in (num_mes) do (set "flag=%%2")
					FINDSTR /V !DEC! flag.txt>flag1.txt
					move /Y "flag1.txt" "flag.txt">nul
					)
				del /Q num_mes
				
				if "!flag!" EQU "6d" (
					rem Cериализованные данные
					if /i "!frame:~14,4!" NEQ "fffe" (
						set "frame=!frame:~14!"
					rem Результат выполнения транзакции
						set /A DEC"=0x!frame:~2,2!!frame:~0,2!"
						if !DEC! EQU 0 (<nul set /p"=......Успешно; ">>%x%) else (<nul set /p"=......Ошибка: !DEC!; ">>%x%)
						echo:>>%x%						
					rem Код авторизации
						<nul set /p"=......Код авторизации: ">>%x%
						set "hexus=!frame:~4,14!"
						call :S11 & goto :S13
						:S11
						if defined hexus (
							set /A "char=0x!hexus:~0,2!"
							call :hex_ascii
							set "hexus=!hexus:~2!"
							) else (exit /b 0)
						goto :S11				
						:S13
						echo:>>%x%						
					rem Ссылочный номер RRN
						<nul set /p"=......Ссылочный номер RRN: ">>%x%
						set "hexus=!frame:~18,26!"
						call :S21 & goto :S23
						:S21
						if defined hexus (
							set /A "char=0x!hexus:~0,2!"
							call :hex_ascii						
							set "hexus=!hexus:~2!"
							) else (exit /b 0)
						goto :S21						
						:S23
						echo:>>%x%						
					rem Порядковый номер операции за день
						<nul set /p"=......Порядковый номер операции за день: ">>%x%
						set "hexus=!frame:~44,10!"
						call :S31 & goto :S33
						:S31
						if defined hexus (
							set /A "char=0x!hexus:~0,2!"
							call :hex_ascii						
							set "hexus=!hexus:~2!"
							) else (exit /b 0)
						goto :S31						
						:S33
						echo:>>%x%						
					rem Номер карты
						<nul set /p"=......Номер карты: ">>%x%
						set "hexus=!frame:~54,40!"
						call :S41 & goto :S43
						:S41
						if defined hexus (
							set /A "char=0x!hexus:~0,2!"
							call :hex_ascii						
							set "hexus=!hexus:~2!"
							) else (exit /b 0)
						goto :S41						
						:S43
						echo:>>%x%						
					rem Срок действия карты
						<nul set /p"=......Срок действия карты: ">>%x%
						set "hexus=!frame:~94,12!"
						call :S51 & goto :S53
						:S51
						if defined hexus (
							set /A "char=0x!hexus:~0,2!"
							call :hex_ascii						
							set "hexus=!hexus:~2!"
							) else (exit /b 0)
						goto :S51						
						:S53
						echo:>>%x%						
					rem Текстовое сообщение
						<nul set /p"=......Текстовое сообщение: ">>%x%
						set "hexus=!frame:~106,64!"
						call :S61 & goto :S63
						:S61
						if defined hexus (
							set /A "char=0x!hexus:~0,2!"
							call :hex_ascii						
							set "hexus=!hexus:~2!"
							) else (exit /b 0)
						goto :S61						
						:S63
						echo:>>%x%
					rem Номер терминала
						<nul set /p"=......Номер терминала: ">>%x%
						set "hexus=!frame:~188,18!"
						call :S71 & goto :S73
						:S71
						if defined hexus (
							set /A "char=0x!hexus:~0,2!"
							call :hex_ascii						
							set "hexus=!hexus:~2!"
							) else (exit /b 0)
						goto :S71						
						:S73
						echo:>>%x%
					rem Название карты
						<nul set /p"=......Название карты: ">>%x%
						set "hexus=!frame:~206,64!"
						call :S81 & goto :S83
						:S81
						if defined hexus (
							set /A "char=0x!hexus:~0,2!"
							call :hex_ascii						
							set "hexus=!hexus:~2!"
							) else (exit /b 0)
						goto :S81						
						:S83
						echo:>>%x%
						)
					rem TLV формате	
					if /i "!frame:~14,4!" EQU "fffe" (set "TLV=!frame:~18!" & call :OPER_TLV & goto :COMMLOG_START)
					goto COMMLOG_START
					)
				
				if "!flag!" EQU "50" (
					<nul set /p"=......[">>%x%
					set "hexus=!frame:~14!"
					call :G11 & goto :G13
					:G11
					if defined hexus (
						set /A "char=0x!hexus:~0,2!"
						call :hex_ascii
						set "hexus=!hexus:~2!"
						) else (exit /b 0)
					goto :G11				
					:G13
					<nul set /p"=]">>%x%
					echo:>>%x%
					goto COMMLOG_START
					)
						
				if "!flag!" EQU "c0" (				
					if "!frame:~14,8!" EQU "09200000" (<nul set /p"=......Успешно">>%x% & echo:>>%x% & goto COMMLOG_START)
					if "!frame:~14,8!" NEQ "09200000" (<nul set /p"=......[!frame:~14,8!]">>%x% & echo:>>%x% & goto COMMLOG_START)
					)
					
				if "!flag!" EQU "a0" (
					if "!frame:~16,2!" EQU "19" (
						if "!frame:~14,2!" EQU "01" (
							set /a "L=0x!frame:~24,2!"
							if !L! == 0 (<nul set /p"=......ошибка соединения">>%x% & echo:>>%x% & goto COMMLOG_START)
							if !L! == 2 (<nul set /p"=......соединение устанавливается">>%x% & echo:>>%x% & goto COMMLOG_START)
							if !L! == 3 (<nul set /p"=......соединение установлено">>%x% & echo:>>%x% & goto COMMLOG_START)
							<nul set /p"=......ошибка !L!">>%x% & echo:>>%x% & goto COMMLOG_START
							)						
						if "!frame:~14,2!" EQU "02" (
							set /a "L=0x!frame:~22,2!!frame:~20,2!*2"
							for /L %%a in (0,1,!L!) do set "d=!frame:~24,%%a!"							
							<nul set /p"=......Полученные данные [">>%x%
							call :a021 & <nul set /p"=......]">>%x% & echo:>>%x% & goto COMMLOG_START
							:a021
							if defined d (
								set /A "char=0x!d:~0,2!"
								call :hex_ascii
								set "d=!d:~2!"
								) else (exit /b 0)
							goto a021							
							)
						if "!frame:~14,2!" EQU "03" (
							set /a "L=0x!frame:~26,2!!frame:~24,2!"
							<nul set /p"=......Размер данных [!L! байт]">>%x% & echo:>>%x% & goto COMMLOG_START
							)						
						if "!frame:~14,2!" EQU "04" (
							set /a "L=0x!frame:~22,2!!frame:~20,2!"
							if !L! == 0 (<nul set /p"=......Успешно">>%x% & echo:>>%x% & goto COMMLOG_START)
							<nul set /p"=......Ошибка">>%x% & echo:>>%x% & goto COMMLOG_START
							)
						)						
					if "!frame:~16,2!" EQU "03" (
						if "!frame:~14,2!" EQU "01" (
							set /a "L=0x!frame:~22,2!!frame:~20,2!"
							if !L! == 0 (<nul set /p"=......Успешно">>%x% & echo:>>%x% & goto COMMLOG_START)
							<nul set /p"=......Ошибка">>%x% & echo:>>%x% & goto COMMLOG_START
							)						
						if "!frame:~14,2!" EQU "03" (
							set /a "L=0x!frame:~22,2!!frame:~20,2!"
							if !L! == 0 (<nul set /p"=......Успешно">>%x% & echo:>>%x% & goto COMMLOG_START)
							<nul set /p"=......Ошибка">>%x% & echo:>>%x% & goto COMMLOG_START
							)
						if "!frame:~14,2!" EQU "04" (
							set /a "L=0x!frame:~22,2!!frame:~20,2!"
							if !L! == 0 (<nul set /p"=......Успешно">>%x% & echo:>>%x% & goto COMMLOG_START)
							<nul set /p"=......Ошибка">>%x% & echo:>>%x% & goto COMMLOG_START
							)
						)					
					if "!frame:~16,2!" EQU "05" (
						set /a "d=0x!frame:~30,2!!frame:~28,2!!frame:~26,2!!frame:~24,2!"
						set /a "t=0x!frame:~38,2!!frame:~36,2!!frame:~34,2!!frame:~32,2!"
						<nul set /p"=......!d:~6,2!.!d:~4,2!.!d:~0,! !t:~0,2!:!t:~2,2!:!t:~4,2!">>%x% & echo:>>%x% & goto COMMLOG_START
						)					
					if "!frame:~16,2!" EQU "27" (
						if "!frame:~14,2!" EQU "02" (
							set /a "L=0x!frame:~22,2!!frame:~20,2!*2"
							for /L %%a in (0,1,!L!) do set "hexus=!frame:~24,%%a!"
							<nul set /p"=......[">>%x%
							call :27021 & <nul set /p"=]">>%x% & goto COMMLOG_START
							:27021
							if defined hexus (
								set /A "char=0x!hexus:~0,2!"
								call :hex_ascii
								set "hexus=!hexus:~2!"
								) else (exit /b 0)
							goto :27021						
							)
						if "!frame:~14,2!" EQU "03" (
							set /a "L=0x!frame:~22,2!!frame:~20,2!"
							if !L! == 0 (<nul set /p"=......Успешно">>%x% & echo:>>%x% & goto COMMLOG_START)
							<nul set /p"=......Ошибка">>%x% & echo:>>%x% & goto COMMLOG_START
							)
						)						
					if "!frame:~16,2!" EQU "29" (
						if "!frame:~14,2!" EQU "01" (
							set /a "L=0x!frame:~22,2!!frame:~20,2!"
							if !L! == 0 (<nul set /p"=......Успешно">>%x% & echo:>>%x% & goto COMMLOG_START)
							<nul set /p"=......Ошибка">>%x% & echo:>>%x% & goto COMMLOG_START
							)
						)					
					)				
				if "!flag!" EQU "ef" (
					if "!frame:~14,2!" EQU "00" (<nul set /p"=......Успешно">>%x% & echo:>>%x% & goto COMMLOG_START)
					<nul set /p"=......Ошибка">>%x% & echo:>>%x% & goto COMMLOG_START
					)
				if "!flag!" EQU "a5" (
					if "!frame:~14,4!" EQU "9F1C" (<nul set /p"=......номер терминала: ">>%x%)
					if "!frame:~14,4!" EQU "9F16" (<nul set /p"=......номер мерчанта: ">>%x%)
					set /a "L=0x!frame:~18,2!*2"
					for /L %%a in (0,1,!L!) do set "hexus=!frame:~20,%%a!"
					<nul set /p"=!hexus!">>%x% & echo:>>%x% & goto COMMLOG_START
					)
				)
			)		
		)
	)
goto COMMLOG_START
	

:OPER_TLV
if defined TLV (
	
	rem TAG_TTK_TRACK2
	if "!TLV:~0,2!" == "17" (
		rem описание тега 
		findstr /b "!TLV:~0,2!" .\LIBRARY\tags.txt>tags
		for /f "tokens=1,2 delims=-" %%1 in (tags) do (<nul set /p"=......%%2 ">>%x%)
		
		rem длина данных
		set /a "L=0x!TLV:~2,2!*2"
		rem перевод данных в ASCII
		for /L %%a in (0,1,!L!) do set "hexus=!TLV:~4,%%a!"
		call :171 & goto :173
		:171
		if defined hexus (
			set /A "char=0x!hexus:~0,2!"
			call :hex_ascii
			set "hexus=!hexus:~2!"
			) else (exit /b 0)
		goto :171	
		:173
		set /a "L=!L!+4"
		for /L %%a in (0,1,!L!) do (set "T=!TLV:~%%a!")
		set "TLV=!T!"
		echo:>>%x%
		goto :OPER_TLV
		)
		
	rem TAG_TTK_CLIENT_RRN
	if "!TLV:~0,2!" == "18" (
		rem описание тега 
		findstr /b "!TLV:~0,2!" .\LIBRARY\tags.txt>tags
		for /f "tokens=1,2 delims=-" %%1 in (tags) do (<nul set /p"=......%%2 ">>%x%)
		
		rem длина данных
		set /a "L=0x!TLV:~2,2!*2"
		rem перевод данных в ASCII
		for /L %%a in (0,1,!L!) do set "hexus=!TLV:~4,%%a!"
		call :181 & goto :183
		:181
		if defined hexus (
			set /A "char=0x!hexus:~0,2!"
			call :hex_ascii
			set "hexus=!hexus:~2!"
			) else (exit /b 0)
		goto :181	
		:183
		set /a "L=!L!+4"
		for /L %%a in (0,1,!L!) do (set "T=!TLV:~%%a!")
		set "TLV=!T!"
		echo:>>%x%
		goto :OPER_TLV
		)
		
	rem TAG_TTK_EXTRA_DATA
	if "!TLV:~0,2!" == "19" (
		rem описание тега 
		rem findstr /b "!TLV:~0,2!" .\LIBRARY\tags.txt>tags
		rem for /f "tokens=1,2 delims=-" %%1 in (tags) do (<nul set /p"=......%%2 ">>%x%)
		rem длина данных
		set /a "L=0x!TLV:~2,2!*2"
		rem for /L %%a in (0,1,!L!) do set "hexus=!TLV:~4,%%a!"
		rem <nul set /p"=!hexus!; ">>%x%
		set /a "L=!L!+4"
		for /L %%a in (0,1,!L!) do (set "T=!TLV:~%%a!")
		set "TLV=!T!"
		goto :OPER_TLV
		)
		
	rem TAG_TTK_PAN
	if "!TLV:~0,2!" == "89" (
		rem описание тега 
		findstr /b "!TLV:~0,2!" .\LIBRARY\tags.txt>tags
		for /f "tokens=1,2 delims=-" %%1 in (tags) do (<nul set /p"=......%%2 ">>%x%)
		
		rem длина данных
		set /a "L=0x!TLV:~2,2!*2"
		rem перевод данных в ASCII
		for /L %%a in (0,1,!L!) do set "hexus=!TLV:~4,%%a!"
		call :891 & goto :893
		:891
		if defined hexus (
			set /A "char=0x!hexus:~0,2!"
			call :hex_ascii
			set "hexus=!hexus:~2!"
			) else (exit /b 0)
		goto :891
		:893
		set /a "L=!L!+4"
		for /L %%a in (0,1,!L!) do (set "T=!TLV:~%%a!")
		set "TLV=!T!"
		echo:>>%x%
		goto :OPER_TLV
		)
	
	rem TAG_TTK_MERCHANT_ID
	if "!TLV:~0,2!" == "90" (
		rem описание тега 
		findstr /b "!TLV:~0,2!" .\LIBRARY\tags.txt>tags
		for /f "tokens=1,2 delims=-" %%1 in (tags) do (<nul set /p"=......%%2 ">>%x%)
		
		rem длина данных
		set /a "L=0x!TLV:~2,2!*2"
		rem перевод данных в ASCII
		for /L %%a in (0,1,!L!) do set "hexus=!TLV:~4,%%a!"
		call :901 & goto :903
		:901
		if defined hexus (
			set /A "char=0x!hexus:~0,2!"
			call :hex_ascii
			set "hexus=!hexus:~2!"
			) else (exit /b 0)
		goto :901	
		:903
		set /a "L=!L!+4"
		for /L %%a in (0,1,!L!) do (set "T=!TLV:~%%a!")
		set "TLV=!T!"
		echo:>>%x%
		goto :OPER_TLV
		)
	
	rem TAG_TTK_SERVER_RRN
	if "!TLV:~0,2!" == "98" (
		rem описание тега 
		findstr /b "!TLV:~0,2!" .\LIBRARY\tags.txt>tags
		for /f "tokens=1,2 delims=-" %%1 in (tags) do (<nul set /p"=......%%2 ">>%x%)
		
		rem длина данных
		set /a "L=0x!TLV:~2,2!*2"
		rem перевод данных в ASCII
		for /L %%a in (0,1,!L!) do set "hexus=!TLV:~4,%%a!"
		call :981 & goto :983
		:981
		if defined hexus (
			set /A "char=0x!hexus:~0,2!"
			call :hex_ascii
			set "hexus=!hexus:~2!"
			) else (exit /b 0)
		goto :981		
		:983
		set /a "L=!L!+4"
		for /L %%a in (0,1,!L!) do (set "T=!TLV:~%%a!")
		set "TLV=!T!"
		echo:>>%x%
		goto :OPER_TLV
		)
	
	rem TAG_TTK_SERVER_TSN
	if "!TLV:~0,2!" == "8b" (
		rem описание тега 
		findstr /b "!TLV:~0,2!" .\LIBRARY\tags.txt>tags
		for /f "tokens=1,2 delims=-" %%1 in (tags) do (<nul set /p"=......%%2 ">>%x%)
		
		rem длина данных
		set /a "L=0x!TLV:~2,2!*2"
		rem перевод данных в ASCII
		for /L %%a in (0,1,!L!) do set "hexus=!TLV:~4,%%a!"
		call :8b1 & goto :8b3
		:8b1
		if defined hexus (
			set /A "char=0x!hexus:~0,2!"
			call :hex_ascii
			set "hexus=!hexus:~2!"
			) else (exit /b 0)
		goto :8b1
		:8b3
		set /a "L=!L!+4"
		for /L %%a in (0,1,!L!) do (set "T=!TLV:~%%a!")
		set "TLV=!T!"
		echo:>>%x%
		goto :OPER_TLV
		)
	
	rem TAG_TTK_SERVER_AUT_CODE
	if "!TLV:~0,2!" == "8c" (
		rem описание тега 
		findstr /b "!TLV:~0,2!" .\LIBRARY\tags.txt>tags
		for /f "tokens=1,2 delims=-" %%1 in (tags) do (<nul set /p"=......%%2 ">>%x%)
		
		rem длина данных
		set /a "L=0x!TLV:~2,2!*2"
		rem перевод данных в ASCII
		for /L %%a in (0,1,!L!) do set "hexus=!TLV:~4,%%a!"
		call :8c1 & goto :8c3
		:8c1
		if defined hexus (
			set /A "char=0x!hexus:~0,2!"
			call :hex_ascii
			set "hexus=!hexus:~2!"
			) else (exit /b 0)
		goto :8c1
		:8c3
		set /a "L=!L!+4"
		for /L %%a in (0,1,!L!) do (set "T=!TLV:~%%a!")
		set "TLV=!T!"
		echo:>>%x%
		goto :OPER_TLV
		)
	
	rem TAG_TTK_ISSUER_NAME
	if "!TLV:~0,2!" == "8f" (
		rem описание тега 
		findstr /b "!TLV:~0,2!" .\LIBRARY\tags.txt>tags
		for /f "tokens=1,2 delims=-" %%1 in (tags) do (<nul set /p"=......%%2 ">>%x%)
		
		rem длина данных
		set /a "L=0x!TLV:~2,2!*2"
		rem перевод данных в ASCII
		for /L %%a in (0,1,!L!) do set "hexus=!TLV:~4,%%a!"
		call :8f1 & goto :8f3
		:8f1
		if defined hexus (
			set /A "char=0x!hexus:~0,2!"
			call :hex_ascii
			set "hexus=!hexus:~2!"
			) else (exit /b 0)
		goto :8f1
		:8f3
		set /a "L=!L!+4"
		for /L %%a in (0,1,!L!) do (set "T=!TLV:~%%a!")
		set "TLV=!T!"
		echo:>>%x%
		goto :OPER_TLV
		)
	
	rem TAG_TTK_TERMINAL_ID
	if "!TLV:~0,2!" == "9d" (		
		rem описание тега 
		findstr /b "!TLV:~0,2!" .\LIBRARY\tags.txt>tags
		for /f "tokens=1,2 delims=-" %%1 in (tags) do (<nul set /p"=......%%2 ">>%x%)
		
		rem длина данных
		set /a "L=0x!TLV:~2,2!*2"
		for /L %%a in (0,1,!L!) do (set "hexus=!TLV:~4,%%a!")
		call :9d1 & goto :9d3
		:9d1
		if defined hexus (
			set /A "char=0x!hexus:~0,2!"
			call :hex_ascii
			set "hexus=!hexus:~2!"
			) else (exit /b 0)
		goto :9d1
		:9d3
		set /a "L=!L!+4"
		for /L %%a in (0,1,!L!) do (set "T=!TLV:~%%a!")
		set "TLV=!T!"
		echo:>>%x%
		goto :OPER_TLV
		)
	
	rem TAG_TTK_IS_OWN
	if "!TLV:~0,2!" == "a4" (
		rem описание тега 
		findstr /b "!TLV:~0,2!" .\LIBRARY\tags.txt>tags
		for /f "tokens=1,2 delims=-" %%1 in (tags) do (<nul set /p"=......%%2 ">>%x%)
		
		rem длина данных
		set /a "L=0x!TLV:~2,2!*2"
		for /L %%a in (0,1,!L!) do set "hexus=!TLV:~4,%%a!"
		if !hexus! == 0 (
			<nul set /p"= нет">>%x%
			set /a "L=!L!+4"
			for /L %%a in (0,1,!L!) do set "TLV=!TLV:~%%a!"
			echo:>>%x%
			goto :OPER_TLV
			) else (
			<nul set /p"= да">>%x%
			set /a "L=!L!+4"
			for /L %%a in (0,1,!L!) do (set "T=!TLV:~%%a!")
			set "TLV=!T!"
			echo:>>%x%
			goto :OPER_TLV
			)
		)
		
	rem TAG_TTK_ERROR_CODE
	if "!TLV:~0,2!" == "a5" (
		rem описание тега 
		findstr /b "!TLV:~0,2!" .\LIBRARY\tags.txt>tags
		for /f "tokens=1,2 delims=-" %%1 in (tags) do (<nul set /p"=......%%2 ">>%x%)
		
		rem длина данных
		set /a "L=0x!TLV:~2,2!*2"
		rem перевод данных в ASCII
		for /L %%a in (0,1,!L!) do set "hexus=!TLV:~4,%%a!"
		call :a51 & goto :a53
		:a51
		if defined hexus (
			set /A "char=0x!hexus:~0,2!"
			call :hex_ascii
			set "hexus=!hexus:~2!"
			) else (exit /b 0)
		goto :a51
		:a53
		set /a "L=!L!+4"
		for /L %%a in (0,1,!L!) do (set "T=!TLV:~%%a!")
		set "TLV=!T!"
		echo:>>%x%
		goto :OPER_TLV
		)
	
	rem TAG_TTK_DEPARTMENT_INDEX
	if "!TLV:~0,4!" == "5f02" (
		rem описание тега 
		findstr /b "!TLV:~0,4!" .\LIBRARY\tags.txt>tags
		for /f "tokens=1,2 delims=-" %%1 in (tags) do (<nul set /p"=......%%2 ">>%x%)
		
		rem длина данных
		set /a "L=0x!TLV:~4,2!*2"
		rem перевод данных в ASCII
		for /L %%a in (0,1,!L!) do set "hexus=!TLV:~6,%%a!"
		<nul set /p"=!hexus!; ">>%x%
		set /a "L=!L!+6"
		for /L %%a in (0,1,!L!) do (set "T=!TLV:~%%a!")
		set "TLV=!T!"
		echo:>>%x%
		goto :OPER_TLV
		)
	
	rem TAG_TTK_LLT_ID
	if "!TLV:~0,4!" == "5f03" (
		rem описание тега 
		findstr /b "!TLV:~0,4!" .\LIBRARY\tags.txt>tags
		for /f "tokens=1,2 delims=-" %%1 in (tags) do (<nul set /p"=......%%2 ">>%x%)
		
		rem длина данных
		set /a "L=0x!TLV:~4,2!*2"
		rem перевод данных в ASCII
		for /L %%a in (0,1,!L!) do set "hexus=!TLV:~6,%%a!"
		call :5f031 & goto :5f033
		:5f031
		if defined hexus (
			set /A "char=0x!hexus:~0,2!"
			call :hex_ascii
			set "hexus=!hexus:~2!"
			) else (exit /b 0)
		goto :5f031
		:5f033
		set /a "L=!L!+6"
		for /L %%a in (0,1,!L!) do (set "T=!TLV:~%%a!")
		set "TLV=!T!"
		echo:>>%x%
		goto :OPER_TLV
		)
		
	rem TAG_TTK_CLIENT_NAME
	if "!TLV:~0,4!" == "5f04" (
		rem описание тега 
		findstr /b "!TLV:~0,4!" .\LIBRARY\tags.txt>tags
		for /f "tokens=1,2 delims=-" %%1 in (tags) do (<nul set /p"=......%%2 ">>%x%)
		
		rem длина данных
		set /a "L=0x!TLV:~4,2!*2"
		rem перевод данных в ASCII
		for /L %%a in (0,1,!L!) do set "hexus=!TLV:~6,%%a!"
		call :5f041 & goto :5f043
		:5f041
		if defined hexus (
			set /A "char=0x!hexus:~0,2!"
			call :hex_ascii
			set "hexus=!hexus:~2!"
			) else (exit /b 0)
		goto :5f041
		:5f043
		set /a "L=!L!+6"
		for /L %%a in (0,1,!L!) do (set "T=!TLV:~%%a!")
		set "TLV=!T!"
		echo:>>%x%
		goto :OPER_TLV
		)
	
	rem TAG_TTK_UPOS_MESSAGE
	if "!TLV:~0,4!" == "5f05" (
		rem описание тега 
		findstr /b "!TLV:~0,4!" .\LIBRARY\tags.txt>tags
		for /f "tokens=1,2 delims=-" %%1 in (tags) do (<nul set /p"=......%%2 ">>%x%)
		
		rem длина данных
		set /a "L=0x!TLV:~4,2!*2"
		rem перевод данных в ASCII
		for /L %%a in (0,1,!L!) do set "hexus=!TLV:~6,%%a!"
		call :5f051 & goto :5f053
		:5f051
		if defined hexus (
			set /A "char=0x!hexus:~0,2!"
			call :hex_ascii
			set "hexus=!hexus:~2!"
			) else (exit /b 0)
		goto :5f051
		:5f053
		set /a "L=!L!+6"
		for /L %%a in (0,1,!L!) do (set "T=!TLV:~%%a!")
		set "TLV=!T!"
		echo:>>%x%
		goto :OPER_TLV
		)
		
	rem TAG_TTK_CARD_EXPDATE
	if "!TLV:~0,4!" == "5f06" (
		rem описание тега 
		findstr /b "!TLV:~0,4!" .\LIBRARY\tags.txt>tags
		for /f "tokens=1,2 delims=-" %%1 in (tags) do (<nul set /p"=......%%2 ">>%x%)
		
		rem длина данных
		set /a "L=0x!TLV:~4,2!*2"
		rem перевод данных в ASCII
		for /L %%a in (0,1,!L!) do set "hexus=!TLV:~6,%%a!"
		call :5f061 & goto :5f063
		:5f061
		if defined hexus (
			set /A "char=0x!hexus:~0,2!"
			call :hex_ascii
			set "hexus=!hexus:~2!"
			) else (exit /b 0)
		goto :5f061
		:5f063
		set /a "L=!L!+6"
		for /L %%a in (0,1,!L!) do (set "T=!TLV:~%%a!")
		set "TLV=!T!"
		echo:>>%x%
		goto :OPER_TLV
		)
		
	rem TAG_TTK_PILOT_OPER_TYPE
	if "!TLV:~0,4!" == "5f07" (
		rem описание тега 
		findstr /b "!TLV:~0,4!" .\LIBRARY\tags.txt>tags
		for /f "tokens=1,2 delims=-" %%1 in (tags) do (<nul set /p"=......%%2 ">>%x%)
		
		rem длина данных
		set /a "L=0x!TLV:~4,2!*2"
		for /L %%a in (0,1,!L!) do set "hexus=!TLV:~6,%%a!"
		rem hex to dec
		set /a DEC"=0x!hexus!"
		rem добавляем 0 если однозначное число
		if "!DEC:~1,1!"=="" (set "DEC=0!DEC!")
		rem поиск номера операции
		findstr /b "!DEC!" .\LIBRARY\oper_type.txt>oper
		for /f "tokens=1,2 delims=-" %%1 in (oper) do (<nul set /p"=%%2; ">>%x%)
		set /a "L=!L!+6"
		for /L %%a in (0,1,!L!) do (set "T=!TLV:~%%a!")
		set "TLV=!T!"
		echo:>>%x%
		goto :OPER_TLV
		)
	
	rem TAG_TTK_CARDHOLDER_ANSWER
	if "!TLV:~0,4!" == "5f09" (
		rem описание тега 
		findstr /b "!TLV:~0,4!" .\LIBRARY\tags.txt>tags
		for /f "tokens=1,2 delims=-" %%1 in (tags) do (<nul set /p"=......%%2 ">>%x%)
		
		rem длина данных
		set /a "L=0x!TLV:~4,2!*2"
		rem перевод данных в ASCII
		for /L %%a in (0,1,!L!) do set "hexus=!TLV:~6,%%a!"
		call :5f091 & goto :5f093
		:5f091
		if defined hexus (
			set /A "char=0x!hexus:~0,2!"
			call :hex_ascii
			set "hexus=!hexus:~2!"
			) else (exit /b 0)
		goto :5f091
		:5f093
		set /a "L=!L!+6"
		for /L %%a in (0,1,!L!) do (set "T=!TLV:~%%a!")
		set "TLV=!T!"
		echo:>>%x%
		goto :OPER_TLV
		)
		
	rem TAG_TTK_REQUEST_ID
	if "!TLV:~0,4!" == "5f0a" (
		rem описание тега 
		findstr /b "!TLV:~0,4!" .\LIBRARY\tags.txt>tags
		for /f "tokens=1,2 delims=-" %%1 in (tags) do (<nul set /p"=......%%2 ">>%x%)
		
		rem длина данных
		set /a "L=0x!TLV:~4,2!*2"
		rem hex to dec
		for /L %%a in (0,1,!L!) do set "hexus=!TLV:~6,%%a!"
		set /a DEC"=0x!hexus!"
		<nul set /p"=!DEC!; ">>%x%
		set /a "L=!L!+6"
		for /L %%a in (0,1,!L!) do (set "T=!TLV:~%%a!")
		set "TLV=!T!"
		echo:>>%x%
		goto :OPER_TLV
		)
		
	rem TAG_TTK_TRX_FLAGS
	if "!TLV:~0,4!" == "5f0c" (
		rem описание тега 
		findstr /b "!TLV:~0,4!" .\LIBRARY\tags.txt>tags
		for /f "tokens=1,2 delims=-" %%1 in (tags) do (<nul set /p"=......%%2 ">>%x%)
		
		rem длина данных
		set /a "L=0x!TLV:~4,2!*2"
		if "!TLV:~6,2!" == "00" (<nul set /p"=Магнитный ридер; ">>%x%)
		if "!TLV:~6,2!" == "01" (<nul set /p"=Ручной ввод номера карты; ">>%x%)
		if "!TLV:~6,2!" == "02" (<nul set /p"=Чиповый ридер; ">>%x%)
		if "!TLV:~6,2!" == "03" (<nul set /p"=На карте есть чип, но она считана через магнитный ридер; ">>%x%)
		if "!TLV:~6,2!" == "04" (<nul set /p"=Бесконтактная карта с эмуляцией магнитной полосы; ">>%x%)
		if "!TLV:~6,2!" == "05" (<nul set /p"=Бесконтактная карта с эмуляцией чипа; ">>%x%)
		if "!TLV:~6,2!" == "06" (<nul set /p"=Введен идентификатор клиента Другие флаги; ">>%x%)
		if "!TLV:~8,2!" == "80" (<nul set /p"=Биоверификация держателя карты; ">>%x%)
		if "!TLV:~10,2!" == "01" (<nul set /p"=Введен online pin; ">>%x%)
		if "!TLV:~10,2!" == "02" (<nul set /p"=Введен offline pin; ">>%x%)
		if "!TLV:~10,2!" == "04" (<nul set /p"=Операция без верификации держателя; ">>%x%)
		set /a "L=!L!+6"
		for /L %%a in (0,1,!L!) do (set "T=!TLV:~%%a!")
		set "TLV=!T!"
		echo:>>%x%
		goto :OPER_TLV
		)
		
	rem TAG_TTK_CARD_TYPE
	if "!TLV:~0,4!" == "5f0d" (
		rem описание тега 
		findstr /b "!TLV:~0,4!" .\LIBRARY\tags.txt>tags
		
		for /f "tokens=1,2 delims=-" %%1 in (tags) do (<nul set /p"=......%%2 ">>%x%)
		rem длина данных
		set /a "L=0x!TLV:~4,2!*2"
		for /L %%a in (0,1,!L!) do set "TL=!TLV:~6,%%a!"
		rem наименование карты
		findstr /b "!TL!" .\LIBRARY\card_type_TLV.txt>card
		for /f "tokens=1,2 delims=-" %%1 in (card) do (<nul set /p"=%%2; ">>%x%)		
		set /a "L=!L!+6"
		for /L %%a in (0,1,!L!) do (set "T=!TLV:~%%a!")
		set "TLV=!T!"
		echo:>>%x%		
		goto :OPER_TLV
		)
	
	rem TAG_TTK_CARD_UID
	if "!TLV:~0,4!" == "5f0e" (
		rem описание тега 
		findstr /b "!TLV:~0,4!" .\LIBRARY\tags.txt>tags
		
		for /f "tokens=1,2 delims=-" %%1 in (tags) do (<nul set /p"=......%%2 ">>%x%)
		rem длина данных
		set /a "L=0x!TLV:~4,2!*2"
		for /L %%a in (0,1,!L!) do set "TL=!TLV:~6,%%a!"
		<nul set /p"=[!TL!]; ">>%x%
		set /a "L=!L!+6"
		for /L %%a in (0,1,!L!) do (set "T=!TLV:~%%a!")
		set "TLV=!T!"
		echo:>>%x%
		goto :OPER_TLV
		)
	
	rem TAG_TTK_SMARTTAP_DATA
	if "!TLV:~0,4!" == "5f10" (
		rem rem описание тега 
		rem findstr /b "!TLV:~0,4!" .\LIBRARY\tags.txt>tags
		rem for /f "tokens=1,2 delims=-" %%1 in (tags) do (<nul set /p"=......%%2 ">>%x%)
		rem длина данных
		set /a "L=0x!TLV:~4,2!*2"
		set /a "L=!L!+6"
		for /L %%a in (0,1,!L!) do (set "T=!TLV:~%%a!")
		set "TLV=!T!"
		goto :OPER_TLV
		)
	
	rem TAG_CUR_ID
	if "!TLV:~0,4!" == "5f2a" (
		rem описание тега 
		findstr /b "!TLV:~0,4!" .\LIBRARY\tags.txt>tags
		for /f "tokens=1,2 delims=-" %%1 in (tags) do (<nul set /p"=......%%2 ">>%x%)
		
		rem длина данных
		set /a "L=0x!TLV:~4,2!*2"
		for /L %%a in (0,1,!L!) do set "TL=!TLV:~6,%%a!"
		set /a DEC"=0x!TL!"
		if "!DEC!" == "0" (<nul set /p"=автомат; ">>%x%)
		if "!DEC!" == "643" (<nul set /p"=рубли; ">>%x%)
		if "!DEC!" == "840" (<nul set /p"=доллар; ">>%x%)
		if "!DEC!" == "978" (<nul set /p"=евро; ">>%x%)
		set /a "L=!L!+6"
		for /L %%a in (0,1,!L!) do (set "T=!TLV:~%%a!")
		set "TLV=!T!"
		echo:>>%x%
		goto :OPER_TLV
		)
		
	rem TAG_TTK_LOYALTY_DATA
		if "!TLV:~0,4!" == "5f32" (
		rem описание тега 
		findstr /b "!TLV:~0,4!" .\LIBRARY\tags.txt>tags
		for /f "tokens=1,2 delims=-" %%1 in (tags) do (<nul set /p"=......%%2 ">>%x%)
		
		rem длина данных
		set /a "L=0x!TLV:~4,2!*2"
		rem перевод данных в ASCII
		for /L %%a in (0,1,!L!) do set "hexus=!TLV:~6,%%a!"
		call :5f321
		goto :5f323
		:5f321
		if defined hexus (
			set /A "char=0x!hexus:~0,2!"
			call :hex_ascii
			set "hexus=!hexus:~2!"
			) else (exit /b 0)
		goto :5f321
		:5f323
		set /a "L=!L!+6"
		for /L %%a in (0,1,!L!) do (set "T=!TLV:~%%a!")
		set "TLV=!T!"
		echo:>>%x%
		goto :OPER_TLV
		)

	rem TAG_MSB_SERVER_AMT
	if "!TLV:~0,4!" == "5f34" (
		rem описание тега 
		findstr /b "!TLV:~0,4!" .\LIBRARY\tags.txt>tags
		for /f "tokens=1,2 delims=-" %%1 in (tags) do (<nul set /p"=......%%2 ">>%x%)
		
		rem длина данных
		set /a "L=0x!TLV:~4,2!*2"
		for /L %%a in (0,1,!L!) do set "summ=!TLV:~6,%%a!"
		set "summ=!summ:~6,2!!summ:~4,2!!summ:~2,2!!summ:~0,2!"
		set /a DEC"=0x!summ!" & <nul set /p"=!DEC:~0,-2!,!DEC:~-2!; ">>%x%
		set /a "L=!L!+6"
		for /L %%a in (0,1,!L!) do (set "T=!TLV:~%%a!")
		set "TLV=!T!"
		echo:>>%x%
		goto :OPER_TLV
		)
		
	rem TAG_MSB_SERVER_AMT_C
	if "!TLV:~0,4!" == "5f35" (
		rem описание тега 
		findstr /b "!TLV:~0,4!" .\LIBRARY\tags.txt>tags
		for /f "tokens=1,2 delims=-" %%1 in (tags) do (<nul set /p"=......%%2 ">>%x%)
		
		rem длина данных
		set /a "L=0x!TLV:~4,2!*2"
		for /L %%a in (0,1,!L!) do set "summ=!TLV:~6,%%a!"
		set "summ=!summ:~6,2!!summ:~4,2!!summ:~2,2!!summ:~0,2!"
		set /a DEC"=0x!summ!" & <nul set /p"=!DEC:~0,-2!,!DEC:~-2!; ">>%x%
		set /a "L=!L!+6"
		for /L %%a in (0,1,!L!) do (set "T=!TLV:~%%a!")
		set "TLV=!T!"
		echo:>>%x%
		goto :OPER_TLV
		)
		
	rem TAG_MSB_HASH
	if "!TLV:~0,4!" == "5f36" (
		rem описание тега 
		findstr /b "!TLV:~0,4!" .\LIBRARY\tags.txt>tags
		for /f "tokens=1,2 delims=-" %%1 in (tags) do (<nul set /p"=......%%2 ">>%x%)
		
		rem длина данных
		set /a "L=0x!TLV:~4,2!*2"
		for /L %%a in (0,1,!L!) do set "TL=!TLV:~6,%%a!"
		<nul set /p"=[!TL!]; ">>%x%
		set /a "L=!L!+6"
		for /L %%a in (0,1,!L!) do (set "T=!TLV:~%%a!")
		set "TLV=!T!"
		echo:>>%x%
		goto :OPER_TLV
		)
									
	rem TAG_MSB_DATE
	if "!TLV:~0,4!" == "5f37" (
		rem описание тега 
		findstr /b "!TLV:~0,4!" .\LIBRARY\tags.txt>tags
		for /f "tokens=1,2 delims=-" %%1 in (tags) do (<nul set /p"=......%%2 ">>%x%)
		
		rem длина данных
		set /a "L=0x!TLV:~4,2!*2"
		for /L %%a in (0,1,!L!) do set "date=!TLV:~6,%%a!"
		set "date=!date:~6,2!!date:~4,2!!date:~2,2!!date:~0,2!"
		set /a DEC"=0x!date!" & <nul set /p"=!DEC:~6,2!.!DEC:~4,2!.!DEC:~0,4!; ">>%x%
		set /a "L=!L!+6"
		for /L %%a in (0,1,!L!) do (set "T=!TLV:~%%a!")
		set "TLV=!T!"
		echo:>>%x%
		goto :OPER_TLV
		)
		
	rem TAG_MSB_TIME
	if "!TLV:~0,4!" == "5f38" (
		rem описание тега 
		findstr /b "!TLV:~0,4!" .\LIBRARY\tags.txt>tags
		for /f "tokens=1,2 delims=-" %%1 in (tags) do (<nul set /p"=......%%2 ">>%x%)
		
		rem длина данных
		set /a "L=0x!TLV:~4,2!*2"
		for /L %%a in (0,1,!L!) do set "time=!TLV:~6,%%a!"
		set "time=!time:~6,2!!time:~4,2!!time:~2,2!!time:~0,2!"
		set /a DEC"=0x!time!" & <nul set /p"=!DEC:~0,2!:!DEC:~2,2!:!DEC:~4,2!; ">>%x%
		set /a "L=!L!+6"
		for /L %%a in (0,1,!L!) do (set "T=!TLV:~%%a!")
		set "TLV=!T!"
		echo:>>%x%
		goto :OPER_TLV
		)
	
	rem TAG_TTK_ENCDATA
	if "!TLV:~0,4!" == "5f39" (
		rem описание тега 
		findstr /b "!TLV:~0,4!" .\LIBRARY\tags.txt>tags
		for /f "tokens=1,2 delims=-" %%1 in (tags) do (<nul set /p"=......%%2 ">>%x%)
		
		rem длина данных
		set /a "L=0x!TLV:~4,2!*2"
		for /L %%a in (0,1,!L!) do set "TL=!TLV:~6,%%a!"
		<nul set /p"=[!TL!]; ">>%x%
		set /a "L=!L!+6"
		for /L %%a in (0,1,!L!) do (set "T=!TLV:~%%a!")
		set "TLV=!T!"
		echo:>>%x%
		goto :OPER_TLV
		)
		
	rem TAG_TTK_ENCDATA
	if "!TLV:~0,4!" == "5f3b" (
		rem описание тега 
		findstr /b "!TLV:~0,4!" .\LIBRARY\tags.txt>tags
		for /f "tokens=1,2 delims=-" %%1 in (tags) do (<nul set /p"=......%%2 ">>%x%)
		
		rem длина данных
		set /a "L=0x!TLV:~4,2!*2"
		for /L %%a in (0,1,!L!) do set "TL=!TLV:~6,%%a!"
		<nul set /p"=[!TL!]; ">>%x%
		set /a "L=!L!+6"
		for /L %%a in (0,1,!L!) do (set "T=!TLV:~%%a!")
		set "TLV=!T!"
		echo:>>%x%
		goto :OPER_TLV
		)
	
	rem TAG_TTK_ENCDATA
	if "!TLV:~0,4!" == "5f40" (
		rem описание тега 
		findstr /b "!TLV:~0,4!" .\LIBRARY\tags.txt>tags
		for /f "tokens=1,2 delims=-" %%1 in (tags) do (<nul set /p"=......%%2 ">>%x%)
		
		rem длина данных
		set /a "L=0x!TLV:~4,2!*2"
		for /L %%a in (0,1,!L!) do set "TL=!TLV:~6,%%a!"
		set "TL=!TL:~2,2!!TL:~0,2!"
		set /a DEC"=0x!TL!" & <nul set /p"=!DEC!; ">>%x%
		set /a "L=!L!+6"
		for /L %%a in (0,1,!L!) do (set "T=!TLV:~%%a!")
		set "TLV=!T!"
		echo:>>%x%
		goto :OPER_TLV
		)
		
	rem TAG_TTK_REALPAN
		if "!TLV:~0,4!" == "5f42" (
		rem описание тега 
		findstr /b "!TLV:~0,4!" .\LIBRARY\tags.txt>tags
		for /f "tokens=1,2 delims=-" %%1 in (tags) do (<nul set /p"=......%%2 ">>%x%)
		
		rem длина данных
		set /a "L=0x!TLV:~4,2!*2"
		rem перевод данных в ASCII
		for /L %%a in (0,1,!L!) do set "hexus=!TLV:~6,%%a!"
		call :5f421
		goto :5f423
		:5f421
		if defined hexus (
			set /A "char=0x!hexus:~0,2!"
			call :hex_ascii
			set "hexus=!hexus:~2!"
			) else (exit /b 0)
		goto :5f421
		:5f423
		set /a "L=!L!+6"
		for /L %%a in (0,1,!L!) do (set "T=!TLV:~%%a!")
		set "TLV=!T!"
		echo:>>%x%
		goto :OPER_TLV
		)
		
	rem TAG_TTK_RECVCARD
		if "!TLV:~0,4!" == "5f43" (
		rem описание тега 
		findstr /b "!TLV:~0,4!" .\LIBRARY\tags.txt>tags
		for /f "tokens=1,2 delims=-" %%1 in (tags) do (<nul set /p"=......%%2 ">>%x%)
		
		rem длина данных
		set /a "L=0x!TLV:~4,2!*2"
		rem перевод данных в ASCII
		for /L %%a in (0,1,!L!) do set "hexus=!TLV:~6,%%a!"
		call :5f431
		goto :5f433
		:5f431
		if defined hexus (
			set /A "char=0x!hexus:~0,2!"
			call :hex_ascii
			set "hexus=!hexus:~2!"
			) else (exit /b 0)
		goto :5f431
		:5f433
		set /a "L=!L!+6"
		for /L %%a in (0,1,!L!) do (set "T=!TLV:~%%a!")
		set "TLV=!T!"
		echo:>>%x%
		goto :OPER_TLV
		)
		
	rem TAG_TTK_FFI
	if "!TLV:~0,4!" == "5f45" (
		rem описание тега 
		findstr /b "!TLV:~0,4!" .\LIBRARY\tags.txt>tags
		for /f "tokens=1,2 delims=-" %%1 in (tags) do (<nul set /p"=......%%2 ">>%x%)
		
		rem длина данных
		set /a "L=0x!TLV:~4,2!*2"
		for /L %%a in (0,1,!L!) do set "TL=!TLV:~6,%%a!"
		set /a DEC"=0x!TL!"
		if !DEC! EQU 0 (<nul set /p"=тег ffi отсутствует на карте; ">>%x%)
		if !DEC! EQU 1 (<nul set /p"=Стандартная карта; ">>%x%)
		if !DEC! EQU 2 (<nul set /p"=Карта в мини формате; ">>%x%)
		if !DEC! EQU 3 (<nul set /p"=Брелок для ключей, часы, браслет, кольцо, наклейка/этикетка; ">>%x%)
		if !DEC! EQU 4 (<nul set /p"=Сотовый телефон; ">>%x%)
		if !DEC! EQU 5 (<nul set /p"=Планшет; ">>%x%)
		if !DEC! EQU 6 (<nul set /p"=Форм фактор не карты; ">>%x%)
		if !DEC! EQU 7 (<nul set /p"=Значение ffi считано с карты, но не распознано; ">>%x%)
		set /a "L=!L!+6"
		for /L %%a in (0,1,!L!) do (set "T=!TLV:~%%a!")
		set "TLV=!T!"
		echo:>>%x%
		goto :OPER_TLV
		)
		
	rem TAG_TTK_SCREEN_TEXT_MODE
	if "!TLV:~0,4!" == "5f46" (
		rem описание тега 
		findstr /b "!TLV:~0,4!" .\LIBRARY\tags.txt>tags
		for /f "tokens=1,2 delims=-" %%1 in (tags) do (<nul set /p"=......%%2 ">>%x%)
		
		rem длина данных
		set /a "L=0x!TLV:~4,2!*2"
		for /L %%a in (0,1,!L!) do set "TL=!TLV:~6,%%a!"
		if "!TL!" == "00" (<nul set /p"=Значение не задано; ">>%x%)
		if "!TL!" == "01" (<nul set /p"=Показать текст полностью; ">>%x%)
		if "!TL!" == "02" (<nul set /p"=Показать кнопку пролистывания текста Вперед; ">>%x%)
		if "!TL!" == "04" (<nul set /p"=Показать кнопку пролистывания текста Назад; ">>%x%)
		if "!TL!" == "08" (<nul set /p"=Проверка наличия Track1 и отключение проверки наличия чипа на карте при чтении карты через магнитный ридер; ">>%x%)
		if "!TL!" == "10" (<nul set /p"=Ввод телефонного номера; ">>%x%)
		if "!TL!" == "20" (<nul set /p"=Ввод адреса электронной почты; ">>%x%)
		if "!TL!" == "40" (<nul set /p"=Не требовать изъятия карты; ">>%x%)
		set /a "L=!L!+6"
		for /L %%a in (0,1,!L!) do (set "T=!TLV:~%%a!")
		set "TLV=!T!"
		echo:>>%x%
		goto :OPER_TLV
		)
		
	rem TAG_TTK_SCREEN_TEXT
	if "!TLV:~0,4!" == "5f47" (
		rem описание тега 
		findstr /b "!TLV:~0,4!" .\LIBRARY\tags.txt>tags
		for /f "tokens=1,2 delims=-" %%1 in (tags) do (<nul set /p"=......%%2 ">>%x%)
		
		rem длина данных
		set /a "L=0x!TLV:~4,2!*2"
		rem перевод данных в ASCII
		for /L %%a in (0,1,!L!) do set "hexus=!TLV:~6,%%a!"
		echo:>>%x%
		call :5f471
		goto :5f473
		:5f471
		if defined hexus (
			set /A "char=0x!hexus:~0,2!"
			call :hex_ascii
			set "hexus=!hexus:~2!"
			) else (exit /b 0)
		goto :5f471
		:5f473
		set /a "L=!L!+6"
		for /L %%a in (0,1,!L!) do (set "T=!TLV:~%%a!")
		set "TLV=!T!"
		echo:>>%x%
		goto :OPER_TLV
		)
		
	rem TAG_TTK_AID
	if "!TLV:~0,4!" == "5f48" (
		rem описание тега 
		findstr /b "!TLV:~0,4!" .\LIBRARY\tags.txt>tags
		for /f "tokens=1,2 delims=-" %%1 in (tags) do (<nul set /p"=......%%2 ">>%x%)
		
		rem длина данных
		set /a "L=0x!TLV:~4,2!*2"
		rem перевод данных в ASCII
		for /L %%a in (0,1,!L!) do set "hexus=!TLV:~6,%%a!"
		call :5f481
		goto :5f483
		:5f481
		if defined hexus (
			set /A "char=0x!hexus:~0,2!"
			call :hex_ascii
			set "hexus=!hexus:~2!"
			) else (exit /b 0)
		goto :5f481
		:5f483
		set /a "L=!L!+6"
		for /L %%a in (0,1,!L!) do (set "T=!TLV:~%%a!")
		set "TLV=!T!"
		echo:>>%x%
		goto :OPER_TLV
		)
		
	rem TAG_TTK_PASSPORT_DATA
	if "!TLV:~0,4!" == "5f49" (
		rem описание тега 
		findstr /b "!TLV:~0,4!" .\LIBRARY\tags.txt>tags
		for /f "tokens=1,2 delims=-" %%1 in (tags) do (<nul set /p"=......%%2 ">>%x%)
		
		rem длина данных
		set /a "L=0x!TLV:~4,2!*2"
		rem перевод данных в ASCII
		for /L %%a in (0,1,!L!) do set "hexus=!TLV:~6,%%a!"
		call :5f491
		goto :5f493
		:5f491
		if defined hexus (
			set /A "char=0x!hexus:~0,2!"
			call :hex_ascii
			set "hexus=!hexus:~2!"
			) else (exit /b 0)
		goto :5f491
		:5f493
		set /a "L=!L!+6"
		for /L %%a in (0,1,!L!) do (set "T=!TLV:~%%a!")
		set "TLV=!T!"
		echo:>>%x%
		goto :OPER_TLV
		)
						
	rem TAG_MSB_CHEQUE_FLAGS						
	if "!TLV:~0,4!" == "5f4a" (
		rem описание тега 
		findstr /b "!TLV:~0,4!" .\LIBRARY\tags.txt>tags
		for /f "tokens=1,2 delims=-" %%1 in (tags) do (<nul set /p"=......%%2 ">>%x%)
		
		rem длина данных
		set /a "L=0x!TLV:~4,2!*2"
		for /L %%a in (0,1,!L!) do set "TL=!TLV:~6,%%a!"
		set /a DEC"=0x!TL!"
		if "!DEC!" == "0" (<nul set /p"=2; ">>%x%) else (<nul set /p"=1; ">>%x%)
		set /a "L=!L!+6"
		for /L %%a in (0,1,!L!) do (set "T=!TLV:~%%a!")
		set "TLV=!T!"
		echo:>>%x%
		goto :OPER_TLV
		)
		
	rem TAG_MSB_PIN_FLAGS						
	if "!TLV:~0,4!" == "5f4b" (
		rem описание тега 
		findstr /b "!TLV:~0,4!" .\LIBRARY\tags.txt>tags
		for /f "tokens=1,2 delims=-" %%1 in (tags) do (<nul set /p"=......%%2 ">>%x%)
		
		rem длина данных
		set /a "L=0x!TLV:~4,2!*2"
		for /L %%a in (0,1,!L!) do set "TL=!TLV:~6,%%a!"
		set /a DEC"=0x!TL!"
		if "!DEC!" == "0" (<nul set /p"=None; ">>%x%)
		if "!DEC!" == "1" (<nul set /p"=NoPinBypass; ">>%x%)
		if "!DEC!" == "2" (<nul set /p"=ClientSkippedPin; ">>%x%)
		set /a "L=!L!+6"
		for /L %%a in (0,1,!L!) do (set "T=!TLV:~%%a!")
		set "TLV=!T!"
		echo:>>%x%
		goto :OPER_TLV
		)
		
	rem TAG_MSB_OWN_CARD_FLAGS
	if "!TLV:~0,4!" == "5f4c" (
		rem rem описание тега 
		rem findstr /b "!TLV:~0,4!" .\LIBRARY\tags.txt>tags
		rem for /f "tokens=1,2 delims=-" %%1 in (tags) do (<nul set /p"=......%%2 ">>%x%)
		rem длина данных
		set /a "L=0x!TLV:~4,2!*2"
		set /a "L=!L!+6"
		for /L %%a in (0,1,!L!) do (set "T=!TLV:~%%a!")
		set "TLV=!T!"
		goto :OPER_TLV
		)
		
	rem TAG_MSB_CASHIER_NAME
	if "!TLV:~0,4!" == "5f4d" (
		rem описание тега 
		findstr /b "!TLV:~0,4!" .\LIBRARY\tags.txt>tags
		for /f "tokens=1,2 delims=-" %%1 in (tags) do (<nul set /p"=......%%2 ">>%x%)
		
		rem длина данных
		set /a "L=0x!TLV:~4,2!*2"
		rem перевод данных в ASCII
		for /L %%a in (0,1,!L!) do set "hexus=!TLV:~6,%%a!"
		call :5f4d1
		goto :5f4d3
		:5f4d1
		if defined hexus (
			set /A "char=0x!hexus:~0,2!"
			call :hex_ascii
			set "hexus=!hexus:~2!"
			) else (exit /b 0)
		goto :5f4d1
		:5f4d3
		set /a "L=!L!+6"
		for /L %%a in (0,1,!L!) do (set "T=!TLV:~%%a!")
		set "TLV=!T!"
		echo:>>%x%
		goto :OPER_TLV
		)
		
	rem TAG_TTK_CARD_DATA
	if "!TLV:~0,4!" == "5f4e" (
		rem описание тега 
		findstr /b "!TLV:~0,4!" .\LIBRARY\tags.txt>tags
		for /f "tokens=1,2 delims=-" %%1 in (tags) do (<nul set /p"=......%%2 ">>%x%)
		
		rem длина данных
		set /a "L=0x!TLV:~4,2!*2"
		rem перевод данных в ASCII
		for /L %%a in (0,1,!L!) do set "hexus=!TLV:~6,%%a!"
		call :5f4e1
		goto :5f4e3
		:5f4e1
		if defined hexus (
			set /A "char=0x!hexus:~0,2!"
			call :hex_ascii
			set "hexus=!hexus:~2!"
			) else (exit /b 0)
		goto :5f4e1
		:5f4e3
		set /a "L=!L!+6"
		for /L %%a in (0,1,!L!) do (set "T=!TLV:~%%a!")
		set "TLV=!T!"
		echo:>>%x%
		goto :OPER_TLV
		)
		
	rem TAG_MSB_REAL_EXP_DATE						
	if "!TLV:~0,4!" == "5f51" (
		rem описание тега 
		findstr /b "!TLV:~0,4!" .\LIBRARY\tags.txt>tags
		for /f "tokens=1,2 delims=-" %%1 in (tags) do (<nul set /p"=......%%2 ">>%x%)
		
		rem длина данных
		set /a "L=0x!TLV:~4,2!*2"
		for /L %%a in (0,1,!L!) do set "TL=!TLV:~6,%%a!"
		<nul set /p"=!TL:~0,2! месяц !TL:~2,2! год; ">>%x%
		set /a "L=!L!+6"
		for /L %%a in (0,1,!L!) do (set "T=!TLV:~%%a!")
		set "TLV=!T!"
		echo:>>%x%
		goto :OPER_TLV
		)
		
	rem TAG_MSB_HOST_FLAGS
	if "!TLV:~0,4!" == "5f52" (
		rem rem описание тега 
		rem findstr /b "!TLV:~0,4!" .\LIBRARY\tags.txt>tags
		rem for /f "tokens=1,2 delims=-" %%1 in (tags) do (<nul set /p"=......%%2 ">>%x%)
		rem длина данных
		set /a "L=0x!TLV:~4,2!*2"
		set /a "L=!L!+6"
		for /L %%a in (0,1,!L!) do (set "T=!TLV:~%%a!")
		set "TLV=!T!"
		goto :OPER_TLV
		)
		
	rem TAG_TTK_EXTRAHASH
	if "!TLV:~0,4!" == "5f55" (
		rem rem описание тега 
		rem findstr /b "!TLV:~0,4!" .\LIBRARY\tags.txt>tags
		rem for /f "tokens=1,2 delims=-" %%1 in (tags) do (<nul set /p"=......%%2 ">>%x%)
		rem длина данных
		set /a "L=0x!TLV:~4,2!*2"
		set /a "L=!L!+6"
		for /L %%a in (0,1,!L!) do (set "T=!TLV:~%%a!")
		set "TLV=!T!"
		goto :OPER_TLV
		)
	
	rem TAG_TTK_EXTRAHASH
	if "!TLV:~0,4!" == "5f56" (
		rem описание тега 
		findstr /b "!TLV:~0,4!" .\LIBRARY\tags.txt>tags
		for /f "tokens=1,2 delims=-" %%1 in (tags) do (<nul set /p"=......%%2 ">>%x%)
		
		rem длина данных
		set /a "L=0x!TLV:~4,2!*2"
		rem перевод данных в ASCII
		for /L %%a in (0,1,!L!) do set "hexus=!TLV:~6,%%a!"
		call :5f561
		goto :5f563
		:5f561
		if defined hexus (
			set /A "char=0x!hexus:~0,2!"
			call :hex_ascii
			set "hexus=!hexus:~2!"
			) else (exit /b 0)
		goto :5f561
		:5f563
		set /a "L=!L!+6"
		for /L %%a in (0,1,!L!) do (set "T=!TLV:~%%a!")
		set "TLV=!T!"
		echo:>>%x%
		goto :OPER_TLV
		)
		
	rem TAG_PAR
	if "!TLV:~0,4!" == "9f24" (
		rem описание тега 
		findstr /b "!TLV:~0,4!" .\LIBRARY\tags.txt>tags
		for /f "tokens=1,2 delims=-" %%1 in (tags) do (<nul set /p"=......%%2 ">>%x%)
		
		rem длина данных
		set /a "L=0x!TLV:~4,2!*2"
		rem перевод данных в ASCII
		for /L %%a in (0,1,!L!) do set "hexus=!TLV:~6,%%a!"
		call :9f241
		goto :9f243
		:9f241
		if defined hexus (
			set /A "char=0x!hexus:~0,2!"
			call :hex_ascii
			set "hexus=!hexus:~2!"
			) else (exit /b 0)
		goto :9f241
		:9f243
		set /a "L=!L!+6"
		for /L %%a in (0,1,!L!) do (set "T=!TLV:~%%a!")
		set "TLV=!T!"
		echo:>>%x%
		goto :OPER_TLV
		)
		
	rem TAG_CASHOUT
	if "!TLV:~0,4!" == "df50" (
		rem описание тега 
		findstr /b "!TLV:~0,4!" .\LIBRARY\tags.txt>tags
		for /f "tokens=1,2 delims=-" %%1 in (tags) do (<nul set /p"=......%%2 ">>%x%)
		
		rem длина данных
		set /a "L=0x!TLV:~4,2!*2"
		rem перевод данных в ASCII
		for /L %%a in (0,1,!L!) do set "hexus=!TLV:~6,%%a!"
		call :df501
		goto :df503
		:df501
		if defined hexus (
			set /A "char=0x!hexus:~0,2!"
			call :hex_ascii
			set "hexus=!hexus:~2!"
			) else (exit /b 0)
		goto :df50
		:df503
		set /a "L=!L!+6"
		for /L %%a in (0,1,!L!) do (set "T=!TLV:~%%a!")
		set "TLV=!T!"
		echo:>>%x%
		goto :OPER_TLV
		)
	goto :COMMLOG_START
	)

:hex_ascii
if !char! LSS 32 (<nul set /p "=_" >>%x% & exit /b 0)
if !char! EQU 33 (<nul set /p"=!ascii[33]!">>%x% & exit /b 0)
if !char! EQU 34 (<nul set /p"=!ascii[34]!">>%x% & exit /b 0)
if !char! EQU 61 (<nul set /p"=!ascii[29]!">>%x% & exit /b 0)
set /a "h=!char!-32"
if !h! EQU 0 (<nul set /p "=_" >>%x% & exit /b 0)
for /l %%0 in (0, 1, 208) do (if "%%0"=="!h!" (<nul set /p"=!ascii_table:~%%0,1!">>%x% & exit /b 0))
exit /b 0

:COMMLOG_END

del /Q tags
del /Q hex
del /Q hex.txt
del /Q base
del /Q flag.txt
del /Q frame.txt
del /Q card
del /Q oper
del /Q com_copy.txt
call %x%
