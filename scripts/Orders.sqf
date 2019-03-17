#define OOP_DEBUG
#define OOP_INFO
#define OOP_WARNING
#define OOP_ERROR

#include "..\OOP_Light\OOP_Light.h"

#include "Constants.h"

// Base class for orders
CLASS("Order", "")
	VARIABLE("name");
	VARIABLE("complete");

	METHOD("new") {
		params [P_THISOBJECT, P_STRING("_name")];
		T_SETV("name", _name);
		T_SETV("complete", false);
	} ENDMETHOD;
ENDCLASS;

// Move garrison to position
CLASS("MoveOrder", "Order")
	VARIABLE("targetId");
	VARIABLE("garrisonId");
	VARIABLE("lastT");

	METHOD("new") {
		params [P_THISOBJECT, P_STRING("_name"), P_STRING("_targetId"), P_STRING("_garrisonId")];
		T_SETV("targetId", _target);
		T_SETV("garrisonId", _garrison);
		T_SETV("lastT", time);
	} ENDMETHOD;

	METHOD("update") {
		params [P_THISOBJECT, P_STRING("_state")];
		T_PRVAR(target);
		T_PRVAR(garrison);
		T_PRVAR(lastT);

		private _speed = CALLM0(_garrison, "getSpeed");
		private _targetPos = markerPos _target;
		private _garrisonPos = CALLM0(_garrison, "getPos");
		private _dist = _targetPos distance _garrisonPos;
		private _dt = time - _lastT;
		T_SETV("lastT", time);

		if(_dist > 0) then {
			private _travel = _dist min (_speed * _dt);
			private _vec = _garrisonPos vectorFromTo _targetPos;
			_garrisonPos = _garrisonPos vectorAdd (_vec vectorMultiply _travel);
			CALLM1(_garrison, "setPos", _garrisonPos);
		} else {
			T_SETV("complete", true);
		};
	} ENDMETHOD;
ENDCLASS;
