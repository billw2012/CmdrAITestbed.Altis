#define OOP_DEBUG
#define OOP_INFO
#define OOP_WARNING
#define OOP_ERROR

#include "..\OOP_Light\OOP_Light.h"

#include "Constants.h"

CLASS("Outpost", "RefCounted")
	VARIABLE("marker");
	VARIABLE("pos");
	VARIABLE("outpostSide");

	METHOD("new") {
		params [P_THISOBJECT];
		T_SETV("marker", objNull);
		T_SETV("pos", []);
		T_SETV("outpostSide", side_none);
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
		SETV(_newOutpost, "pos", +T_GETV("pos"));
		SETV(_newOutpost, "outpostSide", T_GETV("outpostSide"));
		_newOutpost
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