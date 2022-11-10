FUNCTION_BLOCK CultureAlarm
VAR_INPUT
	currentTemp	: DINT;
	currentState	: INT;
END_VAR

VAR
	alarmSet	: BOOL := FALSE;
END_VAR

IF (alarmSet = FALSE AND currentState = HEATING AND currentTemp >= 25) THEN
	alarm := TRUE;
	alarmSet := TRUE;
END_IF

IF (alarmOff AND alarmSet) THEN
	alarm := FALSE;
END_IF

IF (currentState <> HEATING) THEN
	alarmSet := FALSE;
END_IF

END_FUNCTION_BLOCK