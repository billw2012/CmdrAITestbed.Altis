#define OOP_DEBUG
#define OOP_INFO
#define OOP_WARNING
#define OOP_ERROR

#include "..\OOP_Light\OOP_Light.h"

#include "Constants.h"

// Base class for orders
CLASS("Order", "")
	VARIABLE("orderName");
	VARIABLE("complete");

	METHOD("new") {
		params [P_THISOBJECT, P_STRING("_orderName")];
		T_SETV("orderName", _orderName);
		T_SETV("complete", false);
	} ENDMETHOD;
ENDCLASS;

// Move garrison to position
CLASS("MoveOrder", "Order")
	VARIABLE("garrisonId");
	VARIABLE("targetPos");
	VARIABLE("lastT");

	METHOD("new") {
		params [P_THISOBJECT, P_STRING("_orderName"), P_NUMBER("_garrisonId"), P_ARRAY("_targetPos")];
		T_SETV("garrisonId", _garrisonId);
		T_SETV("targetPos", _targetPos);
		T_SETV("lastT", time);
		OOP_INFO_3("MoveOrder %1 %2->%3 created", _orderName, _garrisonId, _targetPos);
	} ENDMETHOD;

	METHOD("update") {
		params [P_THISOBJECT, P_STRING("_state")];
		T_PRVAR(garrisonId);
		T_PRVAR(targetPos);
		T_PRVAR(lastT);
		T_PRVAR(complete);

		if(_complete) exitWith { true };

		private _garrison = CALLM1(_state, "getGarrisonById", _garrisonId);
		private _speed = CALLM0(_garrison, "getSpeed");
		private _garrisonPos = CALLM0(_garrison, "getPos");
		private _dist = _targetPos distance _garrisonPos;
		private _dt = time - _lastT;
		T_SETV("lastT", time);

		if(_dist > 10) then {
			private _travel = _dist min (_speed * _dt);
			private _vec = _garrisonPos vectorFromTo _targetPos;
			_garrisonPos = _garrisonPos vectorAdd (_vec vectorMultiply _travel);
			CALLM1(_garrison, "setPos", _garrisonPos);
			false
		} else {
			T_PRVAR(orderName);
			OOP_INFO_3("MoveOrder %1 %2->%3 completed", _orderName, _garrisonId, _targetPos);
			T_SETV("complete", true);
			true
		};
	} ENDMETHOD;
ENDCLASS;
