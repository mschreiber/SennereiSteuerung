FUNCTION_BLOCK GutAlarm
VAR_INPUT
	currentState	: INT;
END_VAR

VAR
	alarmSet	: BOOL := FALSE;
END_VAR

IF (NOT alarmSet AND currentState = READY_FOR_GUT) THEN
	alarm := TRUE;
	alarmSet := TRUE;
END_IF

IF (alarmOff AND alarmSet) THEN
	alarm := FALSE;
END_IF

IF (currentState <> READY_FOR_GUT) THEN
	alarmSet := FALSE;
END_IF

END_FUNCTION_BLOCK