// Copyright (c) 2017 Benjamin Moir. All rights reserved.
// This work is licensed under the terms of the MIT license.  
// To obtain a copy, visit <https://opensource.org/licenses/MIT>.

class TZK_ArrayI8
{
	Array<int8> Values;

	uint Size() { return Values.Size(); }
	void Copy(TZK_ArrayI8 other) { Values.Copy(other.Values); }
	void Move(TZK_ArrayI8 other) { Values.Move(other.Values); }
	uint Find(int item) { return Values.Find(item); }
	uint Push(int item) { return Values.Push(item); }
	bool Pop() { return Values.Pop(); }
	void Delete(uint index, int n = 1) { Values.Delete(index, n); }
	void Insert(uint index, int item) { Values.Insert(index, item); }
	void ShrinkToFit() { Values.ShrinkToFit(); }
	void Grow(uint amount) { Values.Grow(amount); }
	void Resize(uint amount) { Values.Resize(amount); }
	uint Reserve(uint amount) { return Values.Reserve(amount); }
	uint Max() { return Values.Max(); }
	void Clear() { Values.Clear(); }
}

class TZK_ArrayI16
{
	Array<int16> Values;

	uint Size() { return Values.Size(); }
	void Copy(TZK_ArrayI16 other) { Values.Copy(other.Values); }
	void Move(TZK_ArrayI16 other) { Values.Move(other.Values); }
	uint Find(int item) { return Values.Find(item); }
	uint Push(int item) { return Values.Push(item); }
	bool Pop() { return Values.Pop(); }
	void Delete(uint index, int n = 1) { Values.Delete(index, n); }
	void Insert(uint index, int item) { Values.Insert(index, item); }
	void ShrinkToFit() { Values.ShrinkToFit(); }
	void Grow(uint amount) { Values.Grow(amount); }
	void Resize(uint amount) { Values.Resize(amount); }
	uint Reserve(uint amount) { return Values.Reserve(amount); }
	uint Max() { return Values.Max(); }
	void Clear() { Values.Clear(); }
}

class TZK_ArrayI32
{
	Array<int> Values;

	uint Size() { return Values.Size(); }
	void Copy(TZK_ArrayI32 other) { Values.Copy(other.Values); }
	void Move(TZK_ArrayI32 other) { Values.Move(other.Values); }
	uint Find(int item) { return Values.Find(item); }
	uint Push(int item) { return Values.Push(item); }
	bool Pop() { return Values.Pop(); }
	void Delete(uint index, int n = 1) { Values.Delete(index, n); }
	void Insert(uint index, int item) { Values.Insert(index, item); }
	void ShrinkToFit() { Values.ShrinkToFit(); }
	void Grow(uint amount) { Values.Grow(amount); }
	void Resize(uint amount) { Values.Resize(amount); }
	uint Reserve(uint amount) { return Values.Reserve(amount); }
	uint Max() { return Values.Max(); }
	void Clear() { Values.Clear(); }
}

class TZK_ArrayF32
{
	Array<float> Values;

	uint Size() { return Values.Size(); }
	void Copy(TZK_ArrayF32 other) { Values.Copy(other.Values); }
	void Move(TZK_ArrayF32 other) { Values.Move(other.Values); }
	uint Find(float item) { return Values.Find(item); }
	uint Push(float item) { return Values.Push(item); }
	bool Pop() { return Values.Pop(); }
	void Delete(uint index, int n = 1) { Values.Delete(index, n); }
	void Insert(uint index, float item) { Values.Insert(index, item); }
	void ShrinkToFit() { Values.ShrinkToFit(); }
	void Grow(uint amount) { Values.Grow(amount); }
	void Resize(uint amount) { Values.Resize(amount); }
	uint Reserve(uint amount) { return Values.Reserve(amount); }
	uint Max() { return Values.Max(); }
	void Clear() { Values.Clear(); }
}

class TZK_ArrayF64
{
	Array<double> Values;

	uint Size() { return Values.Size(); }
	void Copy(TZK_ArrayF64 other) { Values.Copy(other.Values); }
	void Move(TZK_ArrayF64 other) { Values.Move(other.Values); }
	uint Find(double item) { return Values.Find(item); }
	uint Push(double item) { return Values.Push(item); }
	bool Pop() { return Values.Pop(); }
	void Delete(uint index, int n = 1) { Values.Delete(index, n); }
	void Insert(uint index, double item) { Values.Insert(index, item); }
	void ShrinkToFit() { Values.ShrinkToFit(); }
	void Grow(uint amount) { Values.Grow(amount); }
	void Resize(uint amount) { Values.Resize(amount); }
	uint Reserve(uint amount) { return Values.Reserve(amount); }
	uint Max() { return Values.Max(); }
	void Clear() { Values.Clear(); }
}

class TZK_ArrayStr
{
	Array<string> Values;

	uint Size() { return Values.Size(); }
	void Copy(TZK_ArrayStr other) { Values.Copy(other.Values); }
	void Move(TZK_ArrayStr other) { Values.Move(other.Values); }
	uint Find(string item) { return Values.Find(item); }
	uint Push(string item) { return Values.Push(item); }
	bool Pop() { return Values.Pop(); }
	void Delete(uint index, int n = 1) { Values.Delete(index, n); }
	void Insert(uint index, string item) { Values.Insert(index, item); }
	void ShrinkToFit() { Values.ShrinkToFit(); }
	void Grow(uint amount) { Values.Grow(amount); }
	void Resize(uint amount) { Values.Resize(amount); }
	uint Reserve(uint amount) { return Values.Reserve(amount); }
	uint Max() { return Values.Max(); }
	void Clear() { Values.Clear(); }
}

class TZK_ArrayPtr
{
	Array<voidptr> Values;
	
	uint Size() { return Values.Size(); }
	void Copy(TZK_ArrayPtr other) { Values.Copy(other.Values); }
	void Move(TZK_ArrayPtr other) { Values.Move(other.Values); }
	uint Find(voidptr item) { return Values.Find(item); }
	uint Push(voidptr item) { return Values.Push(item); }
	bool Pop() { return Values.Pop(); }
	void Delete(uint index, int n = 1) { Values.Delete(index, n); }
	void Insert(uint index, voidptr item) { Values.Insert(index, item); }
	void ShrinkToFit() { Values.ShrinkToFit(); }
	void Grow(uint amount) { Values.Grow(amount); }
	void Resize(uint amount) { Values.Resize(amount); }
	uint Reserve(uint amount) { return Values.Reserve(amount); }
	uint Max() { return Values.Max(); }
	void Clear() { Values.Clear(); }
}
