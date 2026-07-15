---
layout: post
title:  "Enum to string in Unreal 5"
date:   2025-09-18 11:15:00 +0100
last_updated: 2026-07-15 09:02:00 +0100
categories: software cpp unreal
redirect_from:
    - /software/cpp/unreal/2025/09/18/unreal-enum-to-string
    - /software/c++/unreal/2025/09/18/unreal-enum-to-string
---

In Unreal 5 you can convert enums to their string representation using [`UEnum::GetValueAsString`](<https://dev.epicgames.com/documentation/unreal-engine/API/Runtime/CoreUObject/UEnum/GetValueAsString>) and `UEnum::GetNameStringByValue`.
These help with printing readable log messages.

We will use the following enum as an example:

```cpp
UENUM()
enum class ECharacterCameraMode : uint8 {
    FirstPerson UMETA(DisplayName = "First Person"),
    ThirdPerson UMETA(DisplayName = "Third Person"),
    MAX UMETA(Hidden)
};
```

`UEnum::GetValueAsString` includes the enumerator type in the output whereas `UEnum::GetNameStringByValue` doesn't.
For `ECharacterCameraMode::FirstPerson`, they would return `"ECharacterCameraMode::FirstPerson"` and `"FirstPerson"` respectively.


# UEnum::GetValueAsString

`UEnum::GetValueAsString` is a simple static member function.

```cpp
void SomeActor::ChangeCameraMode(ECharacterCameraMode camera_mode) {
    UE_LOGFMT(LogTemp,
              Verbose,
              "Changing camera mode to {enum_value}.",
              ("enum_value", *UEnum::GetValueAsString(camera_mode)));
    // Rest of code...
}
```

Our output from this code is:

```text
LogTemp: Verbose: Changing camera mode to ECharacterCameraMode::FirstPerson.
```

# UEnum::GetNameStringByValue

`UEnum::GetNameStringByValue` is a little more awkward to use as you have to retrieve the enum's `UEnum` reflection object using `StaticEnum` first.
`UEnum::GetValueAsString` does the same thing internally.

```cpp
auto const* const enum_ptr{StaticEnum<ECharacterCameraMode>()};

FString const enum_name{
    enum_ptr->GetNameStringByValue(
        static_cast<int64>(ECharacterCameraMode::FirstPerson)
    )
};

// enum_name = "FirstPerson"
```
