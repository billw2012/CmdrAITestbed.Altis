/*
Adds two 2D arrays
input: [_gridArray0, _gridArray1]
return: [_gridArray] - the resulting array
*/

params ["_gridArray0", "_gridArray1", ["_destArray", []]];

if(_destArray isEqualTo []) then
{
	_destArray = call ws_fnc_newGridArray;
};

private _gridArray = call ws_fnc_newGridArray;

private _newValue = 0;
for "_i" from 0 to ws_gridSizeX - 1 do //_i is x-pos
{
	for "_j" from 0 to ws_gridSizeY - 1 do //_j is y-pos
	{
		_newValue = ([_gridArray0, _i, _j] call ws_fnc_getValueID) + ([_gridArray1, _i, _j] call ws_fnc_getValueID);
		[_gridArray, _i, _j, _newValue] call ws_fnc_setValueID;
	};
};

_gridArray;