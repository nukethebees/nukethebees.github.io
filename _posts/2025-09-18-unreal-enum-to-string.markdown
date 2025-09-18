---
layout: post
title:  "Enum to string in Unreal 5"
date:   2025-09-18 11:15:00 +0100
categories: software c++ unreal
---

In Unreal 5 you can convert enums to their string representation using [`UEnum::GetValueAsString`](<https://dev.epicgames.com/documentation/en-us/unreal-engine/API/Runtime/CoreUObject/UObject/UEnum/GetValueAsString/1?application_version=5.3>).
This helps with printing readable log messages.

{% highlight cpp %}
UENUM(BlueprintType)
enum class ECharacterCameraMode : uint8 {
    FirstPerson UMETA(DisplayName = "First Person"),
    ThirdPerson UMETA(DisplayName = "Third Person"),
    MAX UMETA(Hidden)
};

void SomeActor::ChangeCameraMode(ECharacterCameraMode camera_mode) {
    UE_LOGFMT(LogTemp,
              Verbose,
              "Changing camera mode to {enum_value}.",
              ("enum_value", *UEnum::GetValueAsString(camera_mode)));
    // Rest of code...
}
{% endhighlight %}

and our output is then:

{% highlight text%}
LogTemp: Verbose: Changing camera mode to ECharacterCameraMode::FirstPerson.
{% endhighlight %}

