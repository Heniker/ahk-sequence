### AHK-Sequence
Register a command for a sequence of keypresses

#### Usage example
```
#Include sequence.ahk

SetCapsLockState("AlwaysOff")

CapsLock & s::{
	MakeSequence := SequenceRegister()

	MakeSequence("hello", (*) => MsgBox("hello"))
	MakeSequence("world", (*) => 0)
	MakeSequence("42", (*) =>  0)
	MakeSequence("test", (*) => 0)
	MakeSequence("testtt", (*) => 0)
}
```
