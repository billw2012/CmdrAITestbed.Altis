#define OOP_DEBUG
#define OOP_INFO
#define OOP_WARNING
#define OOP_ERROR

#include "..\OOP_Light\OOP_Light.h"

#include "Constants.h"

CLASS("State", "")
	VARIABLE("garrisons");
	VARIABLE("outposts");

	METHOD("new") {
		params [P_THISOBJECT];

		T_SETV("garrisons", []);
		T_SETV("outposts", []);
	} ENDMETHOD;

	METHOD("initFromMarkers") {
		params [P_THISOBJECT, P_ARRAY("_markers")];

		// find all intesting markers
		private _garrisons = (_markers select { markerType _x == type_garrison }) apply { NEW("Garrison", [_x]) };
		private _outposts = _markers select { markerType _x == type_outpost };
		private _garrisonedOutposts = _outposts select { count (markerText _x) > 0 };
		private _outpostGarrs = _garrisonedOutposts apply {
			private _outpostMkr = _x;
			private _newGarrMkr = createMarker [ _outpostMkr + "_garr", markerPos _outpostMkr ];
			OOP_INFO_2("Adding garrison %1 for outpost %2...", _newGarrMkr, _outpostMkr);
			_newGarrMkr setMarkerShape "ICON";
			_newGarrMkr setMarkerType type_garrison;
			_newGarrMkr setMarkerColor (markerColor _outpostMkr);
			_newGarrMkr setMarkerText (markerText _outpostMkr);
			_outpostMkr setMarkerText "";
			NEW("Garrison", [_newGarrMkr])
		};
		_garrisons = _garrisons + _outpostGarrs;

		OOP_INFO_2("Found %1 garrisons and %2 outposts...", count _garrisons, count _outposts);
		T_SETV("garrisons", _garrisons);
		T_SETV("outposts", _outposts);
	} ENDMETHOD;

	METHOD("getGarrisonById") {
		params [P_THISOBJECT, P_NUMBER("_id")];
		T_PRVAR(garrisons);
		_garrisons select _id
	} ENDMETHOD;

	METHOD("getOutpostById") {
		params [P_THISOBJECT, P_NUMBER("_id")];
		T_PRVAR(outposts);
		_outposts select _id
	} ENDMETHOD;

	METHOD("simCopy") {
		params [P_THISOBJECT];
		
		T_PRVAR(garrisons);
		T_PRVAR(outposts);
		
		private _simState = NEW("State", []);
		private _simGarrisons = _garrisons apply { CALLM0(_x, "simCopy") };
		SETV(_simState, "garrisons", _simGarrisons);

		// TODO: encapsulate outposts? Maybe they don't really have owners, just occupiers
		SETV(_simState, "outposts", _outposts);

		_simState
	} ENDMETHOD;

	METHOD("update") {
		params [P_THISOBJECT];
		T_PRVAR(garrisons);

		// Update garrisons
		{
			CALLM0(_x, "update");
		} forEach _garrisons;

		// Perform combat
		private _calcedGarrisons = [];
		{
			private _curr = _x;
			if !(_x in _calcedGarrisons) then {
				_calcedGarrisons pushBack _x;
				private _otherGarrisons = (_garrisons - _calcedGarrisons) select { (CALLM0(_curr, "getPos") distance CALLM0(_x, "getPos")) < 500 };
				{
					CALLM1(_curr, "fightUpdate", _x);
				} forEach _otherGarrisons;
				_calcedGarrisons = _calcedGarrisons + _otherGarrisons;
			};
		} forEach _garrisons;

	} ENDMETHOD;
	
ENDCLASS;