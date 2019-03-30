/*
Sets value to all elements
*/

params ["_gridArray", ["_value", 0]];

for "_i" from 0 to ws_gridSizeX - 1 do //_i is x-pos
{
	_column = _gridArray select _i;
	for "_j" from 0 to ws_gridSizeY - 1 do //_j is y-pos
	{
		_column set [_j, _value];
	};
};