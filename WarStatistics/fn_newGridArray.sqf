//Initialize the array
private _gridArray = [];
for "_i" from 0 to ws_gridSizeX - 1 do //_i is x-pos
{
	_column = [];
	for "_j" from 0 to ws_gridSizeY - 1 do //_j is y-pos
	{
		_column pushBack 0;
	};
	_gridArray pushback _column;
};
_gridArray