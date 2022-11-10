FUNCTION_BLOCK RennetAlarm
VAR_INPUT
	currentState	: INT;
END_VAR

VAR
	alarmSet	: BOOL := FALSE;
END_VAR

IF (NOT alarmSet AND currentState = READY_FOR_RENNET) THEN
	alarm := TRUE;
	alarmSet := TRUE;
END_IF

IF (alarmOff AND alarmSet) THEN
	alarm := FALSE;
END_IF

IF (currentState <> READY_FOR_RENNET) THEN
	alarmSet := FALSE;
END_IF

END_FUNCTION_BLOCK