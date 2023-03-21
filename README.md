### AHK-Sequence
Register a command for a sequence of keypresses

#### Usage example
```
#Include sequence.ahk

SetCapsLockState("AlwaysOff")

CapsLock & f::{
	MakeSequence := SequenceRegister()

	MakeSequence("hello", (*) => MsbBox("hello"))
	MakeSequence("world", (*) => 0)
	MakeSequence("42", (*) =>  0)
	MakeSequence("test", (*) => 0)
	MakeSequence("testtt", (*) => 0)
}
```
