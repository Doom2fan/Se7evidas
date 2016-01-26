module stack;

public struct Stack (T) {
    private T [] _stackArray;
    private int _index = 0;
    private uint _max;
    @property int index  () { return _index; }
    @property int count  () { return _index + 1; }
    @property uint max    () { return max; }
    @property bool isFull () {
        if (_index == _max - 1)
            return true;
        else
            return false;
    }
    @property bool isEmpty () {
        if (_index == 0)
            return true;
        else
            return false;
    }

    this (uint max) {
        _stackArray.length = max;
        _max = max;
        _index = 0;
    }


    bool Push (T value) {
        if (_index < _max - 1) {
            _index++;
            _stackArray [_index] = value;
            return true;
        } else {
            return false;
        }
    }

    T Peek () {
        if (_index > 0)
            return _stackArray [_index];
        else
            return null;
    }

    T Pop () {
        if (_index > 0) {
            _index--;
            return _stackArray [_index + 1];
        } else {
            return null;
        }
    }
}
