#define OOP_DEBUG
#define OOP_INFO
#define OOP_WARNING
#define OOP_ERROR

#include "..\OOP_Light\OOP_Light.h"

#include "Constants.h"

CLASS("AttackAction", "Action")
	VARIABLE("ourGarrId");
	VARIABLE("theirGarrId");

	METHOD("new") {
		params [P_THISOBJECT, P_NUMBER("_ourGarrId"), P_NUMBER("_theirGarrId")];
		OOP_INFO_2("New AttackAction created %1->%2", _ourGarrId, _theirGarrId);
		T_SETV("ourGarrId", _ourGarrId);
		T_SETV("theirGarrId", _theirGarrId);
	} ENDMETHOD;

	METHOD("updateScore") {
		params [P_THISOBJECT, P_STRING("_state")];
		T_PRVAR(ourGarrId);
		T_PRVAR(theirGarrId);

		// TODO better score
		private _ourGarr = CALLM1(_state, "getGarrisonById", _ourGarrId);
		private _theirGarr = CALLM1(_state, "getGarrisonById", _theirGarrId);

		private _scoreThreat = CALLM0(_theirGarr, "getStrength");
		private _scoreResource = 0 max (CALLM0(_ourGarr, "getStrength") - _scoreThreat);

		T_SETV("scoreThreat", _scoreThreat);
		T_SETV("scoreResource", _scoreResource);
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

		// TODO: more interesting behaviour.
		// State machine/steps:
		//   Split garrison at the start and only send what is needed.
		//   Send to last known location.
		//   Once there investigate.
		//   Respond to updated position of target, or abort and come home if we can't find them.

		// If we are dead or the enemy are then this action is complete.
		// TODO: use actual intel to determine if/when target is dead.
		if(CALLM0(_ourGarr, "isDead")) exitWith {
			T_SETV("complete", true);
			OOP_INFO_2("AttackAction %1->%2 completed: %1 died", _ourGarrId, _theirGarrId);
		};

		if(CALLM0(_theirGarr, "isDead")) exitWith {
			T_SETV("complete", true);
			OOP_INFO_2("AttackAction %1->%2 completed: %2 died", _ourGarrId, _theirGarrId);
		};

		// For now just add move orders to target until we catch them, they die or we die.
		if(CALLM0(_ourGarr, "isOrderComplete")) then {
			OOP_INFO_2("AttackAction %1->%2 updating move order of %1", _ourGarrId, _theirGarrId);

			// Give our garrison move order to target garrison position
			SETV(_ourGarr, "action", _thisObject);

			private _targetPos = CALLM0(_theirGarr, "getPos");
			private _args = [_ourGarr + " attacking " + _targetPos, _ourGarrId, _targetPos];
			private _moveOrder = NEW("MoveOrder", _args);
			CALLM1(_ourGarr, "giveOrder", _moveOrder);
		};

	} ENDMETHOD;
ENDCLASS;
