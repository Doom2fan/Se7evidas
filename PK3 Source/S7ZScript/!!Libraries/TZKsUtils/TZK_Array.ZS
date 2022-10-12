// Copyright (c) 2017 Benjamin Moir. All rights reserved.
// This work is licensed under the terms of the MIT license.
// To obtain a copy, visit <https://opensource.org/licenses/MIT>.

class S7_TZK_ArrayI8
{
	Array<int8> Values;

	uint Size() { return Values.Size(); }
	void Copy(S7_TZK_ArrayI8 other) { Values.Copy(other.Values); }
	void Move(S7_TZK_ArrayI8 other) { Values.Move(other.Values); }
	int  Find(int item) { return Values.Find(item); }
	int  Push(int item) { return Values.Push(item); }
	bool Pop() { return Values.Pop(); }
	void Delete(uint index, int n = 1) { Values.Delete(index, n); }
	void Insert(uint index, int item) { Values.Insert(index, item); }
	void ShrinkToFit() { Values.ShrinkToFit(); }
	void Grow(uint amount) { Values.Grow(amount); }
	void Resize(uint amount) { Values.Resize(amount); }
	int  Reserve(uint amount) { return Values.Reserve(amount); }
	int  Max() { return Values.Max(); }
	void Clear() { Values.Clear(); }
}

class S7_TZK_ArrayI16
{
	Array<int16> Values;

	uint Size() { return Values.Size(); }
	void Copy(S7_TZK_ArrayI16 other) { Values.Copy(other.Values); }
	void Move(S7_TZK_ArrayI16 other) { Values.Move(other.Values); }
	int  Find(int item) { return Values.Find(item); }
	int  Push(int item) { return Values.Push(item); }
	bool Pop() { return Values.Pop(); }
	void Delete(uint index, int n = 1) { Values.Delete(index, n); }
	void Insert(uint index, int item) { Values.Insert(index, item); }
	void ShrinkToFit() { Values.ShrinkToFit(); }
	void Grow(uint amount) { Values.Grow(amount); }
	void Resize(uint amount) { Values.Resize(amount); }
	int  Reserve(uint amount) { return Values.Reserve(amount); }
	int  Max() { return Values.Max(); }
	void Clear() { Values.Clear(); }
}

class S7_TZK_ArrayI32
{
	Array<int> Values;

	uint Size() { return Values.Size(); }
	void Copy(S7_TZK_ArrayI32 other) { Values.Copy(other.Values); }
	void Move(S7_TZK_ArrayI32 other) { Values.Move(other.Values); }
	int  Find(int item) { return Values.Find(item); }
	int  Push(int item) { return Values.Push(item); }
	bool Pop() { return Values.Pop(); }
	void Delete(uint index, int n = 1) { Values.Delete(index, n); }
	void Insert(uint index, int item) { Values.Insert(index, item); }
	void ShrinkToFit() { Values.ShrinkToFit(); }
	void Grow(uint amount) { Values.Grow(amount); }
	void Resize(uint amount) { Values.Resize(amount); }
	int  Reserve(uint amount) { return Values.Reserve(amount); }
	int  Max() { return Values.Max(); }
	void Clear() { Values.Clear(); }
}

class S7_TZK_ArrayF32
{
	Array<float> Values;

	uint Size() { return Values.Size(); }
	void Copy(S7_TZK_ArrayF32 other) { Values.Copy(other.Values); }
	void Move(S7_TZK_ArrayF32 other) { Values.Move(other.Values); }
	int  Find(float item) { return Values.Find(item); }
	int  Push(float item) { return Values.Push(item); }
	bool Pop() { return Values.Pop(); }
	void Delete(uint index, int n = 1) { Values.Delete(index, n); }
	void Insert(uint index, float item) { Values.Insert(index, item); }
	void ShrinkToFit() { Values.ShrinkToFit(); }
	void Grow(uint amount) { Values.Grow(amount); }
	void Resize(uint amount) { Values.Resize(amount); }
	int  Reserve(uint amount) { return Values.Reserve(amount); }
	int  Max() { return Values.Max(); }
	void Clear() { Values.Clear(); }
}

class S7_TZK_ArrayF64
{
	Array<double> Values;

	uint Size() { return Values.Size(); }
	void Copy(S7_TZK_ArrayF64 other) { Values.Copy(other.Values); }
	void Move(S7_TZK_ArrayF64 other) { Values.Move(other.Values); }
	int  Find(double item) { return Values.Find(item); }
	int  Push(double item) { return Values.Push(item); }
	bool Pop() { return Values.Pop(); }
	void Delete(uint index, int n = 1) { Values.Delete(index, n); }
	void Insert(uint index, double item) { Values.Insert(index, item); }
	void ShrinkToFit() { Values.ShrinkToFit(); }
	void Grow(uint amount) { Values.Grow(amount); }
	void Resize(uint amount) { Values.Resize(amount); }
	int  Reserve(uint amount) { return Values.Reserve(amount); }
	int  Max() { return Values.Max(); }
	void Clear() { Values.Clear(); }
}

class S7_TZK_ArrayStr
{
	Array<string> Values;

	uint Size() { return Values.Size(); }
	void Copy(S7_TZK_ArrayStr other) { Values.Copy(other.Values); }
	void Move(S7_TZK_ArrayStr other) { Values.Move(other.Values); }
	int  Find(string item) { return Values.Find(item); }
	int  Push(string item) { return Values.Push(item); }
	bool Pop() { return Values.Pop(); }
	void Delete(uint index, int n = 1) { Values.Delete(index, n); }
	void Insert(uint index, string item) { Values.Insert(index, item); }
	void ShrinkToFit() { Values.ShrinkToFit(); }
	void Grow(uint amount) { Values.Grow(amount); }
	void Resize(uint amount) { Values.Resize(amount); }
	int  Reserve(uint amount) { return Values.Reserve(amount); }
	int  Max() { return Values.Max(); }
	void Clear() { Values.Clear(); }
}

class S7_TZK_ArrayPtr
{
	Array<voidptr> Values;

	uint Size() { return Values.Size(); }
	void Copy(S7_TZK_ArrayPtr other) { Values.Copy(other.Values); }
	void Move(S7_TZK_ArrayPtr other) { Values.Move(other.Values); }
	int  Find(voidptr item) { return Values.Find(item); }
	int  Push(voidptr item) { return Values.Push(item); }
	bool Pop() { return Values.Pop(); }
	void Delete(uint index, int n = 1) { Values.Delete(index, n); }
	void Insert(uint index, voidptr item) { Values.Insert(index, item); }
	void ShrinkToFit() { Values.ShrinkToFit(); }
	void Grow(uint amount) { Values.Grow(amount); }
	void Resize(uint amount) { Values.Resize(amount); }
	int  Reserve(uint amount) { return Values.Reserve(amount); }
	int  Max() { return Values.Max(); }
	void Clear() { Values.Clear(); }
}

class S7_TZK_ArrayObj
{
	Array<Object> Values;

	uint Size() { return Values.Size(); }
	void Copy(S7_TZK_ArrayObj other) { Values.Copy(other.Values); }
	void Move(S7_TZK_ArrayObj other) { Values.Move(other.Values); }
	int  Find(Object item) { return Values.Find(item); }
	int  Push(Object item) { return Values.Push(item); }
	bool Pop() { return Values.Pop(); }
	void Delete(uint index, int n = 1) { Values.Delete(index, n); }
	void Insert(uint index, Object item) { Values.Insert(index, item); }
	void ShrinkToFit() { Values.ShrinkToFit(); }
	void Grow(uint amount) { Values.Grow(amount); }
	void Resize(uint amount) { Values.Resize(amount); }
	int  Reserve(uint amount) { return Values.Reserve(amount); }
	int  Max() { return Values.Max(); }
	void Clear() { Values.Clear(); }
}
