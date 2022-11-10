PROGRAM PLC_PRG
VAR

	(* PID constants *)
	kp	: INT := 90;
	ki	: INT := 30;
	kd	: INT := 80;

	PIDp	: REAL := 0;
	PIDi	: REAL := 0;
	PIDd	: REAL := 0;

	lastKp	: REAL := 0;
	lastKi	: REAL := 0;
	lastKd	: REAL := 0;

	PIDValuesFixed	: INT := 0;
	PIDError	: REAL := 0;
	previousError	: REAL := 0;

	elapsedTime	: UDINT;
	currentTime	: UDINT;
	timePrev	: UDINT;
	PIDValue	: REAL := 0;

	startTime	: UDINT;
	tmpTime	: UDINT;
	tmpSec	: UDINT;

	state	: STATE := NOT_INITIALIZED;

	heatingDuration	: UINT := 1800; (* 30min *)
	endTempHeating	: REAL := 32.0;

	keepWarmDuration	: UINT := 1200; (* 20 min *)

	burningDuration	: UINT := 1200; (* 20min *)
	endTempBurning	: REAL := 43.0;

	stearingOutDuration	: UINT := 1200; (* 20 min *)

	tmp	: DINT;

	cultureAlarm	: CultureAlarm;
	rennetAlarm	: RennetAlarm;
	gutAlarm	: GutAlarm;

END_VAR

(* Init Stuff *)
IF (state = NOT_INITIALIZED) THEN
	pf_GetInt('', 'Heating', 'EndTemperature', 32, ADR(tmp), 0, '');
	endTempHeating := DINT_TO_REAL(tmp);
	pf_GetInt('', 'Heating', 'Duration', 30, ADR(tmp), 0, '');
	heatingDuration := DINT_TO_UINT(tmp) * 60; (* min to sec *)
	pf_GetInt('', 'KeepWarm', 'Duration', 20, ADR(tmp), 0, '');
	keepWarmDuration := DINT_TO_UINT(tmp) * 60; (* min to sec *)
	pf_GetInt('', 'Burning', 'EndTemperature', 43, ADR(tmp), 0, '');
	endTempBurning := DINT_TO_REAL(tmp);
	pf_GetInt('', 'Burning', 'Duration', 20, ADR(tmp), 0, '');
	burningDuration := DINT_TO_UINT(tmp) * 60; (* min to sec *)
	pf_GetInt('', 'StearingOut', 'Duration', 20, ADR(tmp), 0, '');
	stearingOutDuration := DINT_TO_UINT(tmp) * 60; (* min to sec *)
	state := READY_FOR_START;
END_IF

IF (startProcess = 1 AND state = READY_FOR_START) THEN
	state := HEATING;
	startTime := Util_GetProcTime(0);
END_IF

(* Heating stuff *)
cultureAlarm(currentTemp := currentTemperature, currentState := state);
IF (state = HEATING) THEN
	tmpTime := Util_GetProcTime(0);
	tmpSec := ABS(tmpTime - startTime) / 1000 / 1000;
	IF (currentTemperature < endTempHeating) THEN
		desiredTemperatur := (endTempHeating / heatingDuration * tmpSec) + 20;
	ELSE
		state := KEEP_WARM;
		startTime := Util_GetProcTime(0);
		valueValue := 0; (* close heating ventil *)
	END_IF
END_IF

(* Keep Warm Stuff *)
rennetAlarm(currentState := state);
IF (state = KEEP_WARM) THEN
	tmpTime := Util_GetProcTime(0);
	tmpSec := ABS(tmpTime - startTime) / 1000 / 1000;
	IF (tmpSec >= keepWarmDuration) THEN
		state := READY_FOR_RENNET;
	END_IF
END_IF

(* Burning *)
IF (state = READY_FOR_RENNET AND continueProcess) THEN
	state := BURNING;
	startTime := Util_GetProcTime(0);
END_IF
IF (state = BURNING) THEN
	tmpTime := Util_GetProcTime(0);
	tmpSec := ABS(tmpTime - startTime) / 1000 / 1000;
	IF (currentTemperature < endTempBurning) THEN
		desiredTemperatur := (endTempBurning / burningDuration * tmpSec) + 32;
	ELSE
		state := STIRING_OUT;
		startTime := Util_GetProcTime(0);
		valueValue := 0; (* close heating ventil *)
	END_IF
END_IF

(* Stearing OutStuff *)
IF (state = STIRING_OUT) THEN
	tmpTime := Util_GetProcTime(0);
	tmpSec := ABS(tmpTime - startTime) / 1000 / 1000;
	IF (tmpSec >= stearingOutDuration) THEN
		state := READY_FOR_GUT;
	END_IF
END_IF

(* Gut Stuff *)
gutAlarm(currentState := state);
IF (state = READY_FOR_GUT AND continueProcess) THEN
	state := READY_FOR_START;
END_IF

(* PID stuff *)
IF (state = HEATING OR state = BURNING) THEN
	PIDError := desiredTemperatur - currentTemperature;
	PIDp := 0.01*kp * PIDError;
	PIDi := 0.01*PIDi + (ki * PIDError);

	timePrev := currentTime;
	currentTime := Tcs_RTC_GetTime(0);

	elapsedTime := ABS(currentTime - timePrev) / 1000;
	PIDd := 0.01*kd*((PIDError - previousError)/elapsedTime);

	PIDValue := PIDp + PIDi + PIDd;

	IF (PIDValue < 0) THEN
		PIDValue := 0;
	END_IF
	IF (PIDValue > 255) THEN
		PIDValue := 255;
	END_IF
	valueValue := PIDValue; (* write out the desired value value*)

	previousError := PIDError;

END_IF

(* Cancel Process *)
IF (cancelProcess) THEN
	state := READY_FOR_START;
	alarm := FALSE;
	valueValue := 0;
END_IF

END_PROGRAM

ACTIONS
END_ACTIONS