/*
Calculates edge directions in input array
Input: [_sourceArray, [_destArray]]
Return: a new array with detected edges
*/

params ["_gridArray", ["_destArray", []]];

if(_destArray isEqualTo []) then
{
	_destArray = call ws_fnc_newGridArray;
};

if(!isNil "_gridArray") then
{
	for "_i" from 0 to ws_gridSizeX - 1 do //_i is x-pos
	{
		for "_j" from 0 to ws_gridSizeY - 1 do //_j is y-pos
		{
			private _newValue = [_gridArray, _i, _j] call ws_fnc_getEdgeDirID;
			[_destArray, _i, _j, _newValue] call ws_fnc_setValueID;
		};
	};
};

_destArray