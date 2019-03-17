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

	METHOD("new") {
		params [P_THISOBJECT];
		T_SETV("scoreThreat", -1);
		T_SETV("scoreResource", -1);
		T_SETV("scoreStrategy", -1);
		T_SETV("scoreCompleteness", -1);
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

	METHOD("applyInstant") {
		params [P_THISOBJECT, P_STRING("_state")];
		
	} ENDMETHOD;

	METHOD("update") {
		params [P_THISOBJECT, P_STRING("_state")];
		
	} ENDMETHOD;
ENDCLASS;

CLASS("AttackAction", "Action")
	VARIABLE("ourGarrId");
	VARIABLE("theirGarrId");

	METHOD("new") {
		params [P_THISOBJECT, P_STRING("_ourGarrId"), P_STRING("_theirGarrId")];
		OOP_INFO_2("New AttackAction created %1->%2", _ourGarrId, _theirGarrId);
		T_SETV("ourGarrId", _ourGarrId);
		T_SETV("theirGarrId", _theirGarrId);
	} ENDMETHOD;

	METHOD("updateScore") {
		params [P_THISOBJECT, P_STRING("_state")];
		T_PRVAR(ourGarrId);
		T_PRVAR(theirGarrId);
		// TODO actual score

	} ENDMETHOD;

	METHOD("getFinalScore") {
		params [P_THISOBJECT];
		T_PRVAR(scoreThreat);
		T_PRVAR(scoreResource);
		T_PRVAR(scoreStrategy);
		T_PRVAR(scoreCompleteness);
		_scoreThreat * _scoreResource * _scoreStrategy * _scoreCompleteness
	} ENDMETHOD;

	METHOD("applyInstant") {
		params [P_THISOBJECT, P_STRING("_state")];
		T_PRVAR(ourGarrId);
		T_PRVAR(theirGarrId);
		private _ourGarr = CALLM1(_state, "getGarrisonById", _ourGarrId);
		private _theirGarr = CALLM1(_state, "getGarrisonById", _theirGarrId);

		while { !CALLM0(_ourGarr, "isDead") and !CALLM0(_theirGarr, "isDead") } do {
			CALLM1(_ourGarr, "fightUpdate", _theirGarr);
		};

	} ENDMETHOD;

	METHOD("update") {
		params [P_THISOBJECT, P_STRING("_state")];
		T_PRVAR(ourGarrId);
		T_PRVAR(theirGarrId);
		private _ourGarr = CALLM1(_state, "getGarrisonById", _ourGarrId);
		private _theirGarr = CALLM1(_state, "getGarrisonById", _theirGarrId);

		if(_ourGarr)
	} ENDMETHOD;
ENDCLASS;

CLASS("ReinforceAction", "Action")
	VARIABLE("ourGarrId");
	VARIABLE("theirGarrId");

	METHOD("new") {
		params [P_THISOBJECT, P_STRING("_ourGarrId"), P_STRING("_theirGarrId")];
		OOP_INFO_2("New ReinforceAction created %1->%2", _ourGarrId, _theirGarrId);
		T_SETV("ourGarrId", _ourGarrId);
		T_SETV("theirGarrId", _theirGarrId);
	} ENDMETHOD;

	METHOD("updateScore") {
		params [P_THISOBJECT, P_STRING("_state")];
		T_PRVAR(ourGarrId);
		T_PRVAR(theirGarrId);
		// TODO actual score
		1
	} ENDMETHOD;
	
	METHOD("apply") {
		params [P_THISOBJECT, P_STRING("_state")];
		T_PRVAR(ourGarrId);
		T_PRVAR(theirGarrId);
		// TODO actually apply
	} ENDMETHOD;
ENDCLASS;
