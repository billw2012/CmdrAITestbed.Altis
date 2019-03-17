#define OOP_DEBUG
#define OOP_INFO
#define OOP_WARNING
#define OOP_ERROR

#include "..\OOP_Light\OOP_Light.h"

#include "Constants.h"

CLASS("Action", "")
	VARIABLE("scoreThreat");
	VARIABLE("scoreResource");
	VARIABLE("scoreStrategy");
	VARIABLE("scoreCompleteness");
	VARIABLE("complete");

	METHOD("new") {
		params [P_THISOBJECT];
		T_SETV("scoreThreat", 1);
		T_SETV("scoreResource", 1);
		T_SETV("scoreStrategy", 1);
		T_SETV("scoreCompleteness", 1);
		T_SETV("complete", false);
	} ENDMETHOD;

	METHOD("updateScore") {
		params [P_THISOBJECT, P_STRING("_state")];
	} ENDMETHOD;

	METHOD("getFinalScore") {
		params [P_THISOBJECT];
		T_PRVAR(scoreThreat);
		T_PRVAR(scoreResource);
		T_PRVAR(scoreStrategy);
		T_PRVAR(scoreCompleteness);
		_scoreThreat * _scoreResource * _scoreStrategy * _scoreCompleteness
	} ENDMETHOD;

	METHOD("applyToSim") {
		params [P_THISOBJECT, P_STRING("_state")];
		
	} ENDMETHOD;

	METHOD("update") {
		params [P_THISOBJECT, P_STRING("_state")];
		
	} ENDMETHOD;
ENDCLASS;
