#define OOP_DEBUG
#define OOP_INFO
#define OOP_WARNING
#define OOP_ERROR

#include "..\OOP_Light\OOP_Light.h"

#include "Constants.h"

CLASS("Outpost", "RefCounted")
	VARIABLE("id");
	VARIABLE("marker");
	VARIABLE("pos");
	VARIABLE("outpostSide");
	VARIABLE("garrisonId");

	METHOD("new") {
		params [P_THISOBJECT];
		T_SETV("id", -1);
		T_SETV("marker", objNull);
		T_SETV("pos", []);
		T_SETV("outpostSide", side_none);
		T_SETV("garrisonId", -1);
	} ENDMETHOD;

	METHOD("initFromMarker") {
		params [P_THISOBJECT, P_STRING("_marker")];
		OOP_INFO_1("Initializing Outpost from %1", _marker);
		T_SETV("marker", _marker);
		T_SETV("pos", markerPos _marker);
		T_SETV("outpostSide", markerColor _marker);
	} ENDMETHOD;

	METHOD("simCopy") {
		params [P_THISOBJECT, P_STRING("_state")];
		private _newOutpost = NEW("Outpost", []);
		SETV(_newOutpost, "id", T_GETV("id"));
		SETV(_newOutpost, "pos", +T_GETV("pos"));
		SETV(_newOutpost, "outpostSide", T_GETV("outpostSide"));
		SETV(_newOutpost, "garrisonId", T_GETV("garrisonId"));
		_newOutpost
	} ENDMETHOD;

	METHOD("setId") {
		params [P_THISOBJECT, P_NUMBER("_id")];
		T_SETV("id", _id);
		T_PRVAR(marker);
		if (_marker isEqualType "") then {
			_marker setMarkerText str(_id);
		};
	} ENDMETHOD;

	METHOD("getPos") {
		params [P_THISOBJECT];
		T_GETV("pos")
	} ENDMETHOD;

	METHOD("getSide") {
		params [P_THISOBJECT];
		T_GETV("outpostSide")
	} ENDMETHOD;

	METHOD("setSide") {
		params [P_THISOBJECT, P_STRING("_garrSide")];
		T_SETV("outpostSide", _garrSide);
		T_PRVAR(marker);
		if (_marker isEqualType "") then {
			_marker setMarkerColor _garrSide;
		};
	} ENDMETHOD;
ENDCLASS;