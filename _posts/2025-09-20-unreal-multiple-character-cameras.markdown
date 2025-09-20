---
layout: post
title:  "Setting up multiple character cameras in Unreal Engine 5"
date:   2025-09-20 13:00:00 +0100
categories: software c++ unreal
---

This guide will show you how to add any number of cameras to a `ACharacter` derived class and switch between them.

The full code is found in the `MyCharacter` header and cpp files from [here](https://github.com/nukethebees/ue5_sandbox/tree/0032080ed8630835b34fac62e39ab54e575fd4fd/Source/Sandbox/characters) with `get_next` function defined [here](https://github.com/nukethebees/ue5_sandbox/blob/0032080ed8630835b34fac62e39ab54e575fd4fd/Source/Sandbox/utilities/enums.h).

## High level overview

* Derive a class from `ACharacter` to hold the cameras
* Define an active camera state enum and add it as a member variable
* Define a `constexpr` struct of camera properties
* Add a [TArray\<UCameraComponent\>](https://dev.epicgames.com/documentation/en-us/unreal-engine/API/Runtime/Engine/Camera/UCameraComponent) member for the cameras
* Add a [TArray\<USpringArmComponent\>](https://dev.epicgames.com/documentation/en-us/unreal-engine/API/Runtime/Engine/GameFramework/USpringArmComponent) member. Spring arms are used for third person cameras to prevent them from clipping through geometry.
* Add member functions for camera switching

## Step by step process

### Includes

The following headers are needed.
The stdlib headers provide enum manipulation functions.

{% highlight cpp %}
#include <utility>
#include <type_traits>

#include "Camera/CameraComponent.h" 
#include "CoreMinimal.h"
#include "GameFramework/Character.h"
#include "GameFramework/CharacterMovementComponent.h"
#include "GameFramework/SpringArmComponent.h"

#include "MyCharacter.generated.h"
{% endhighlight %}

### Creating the character class

{% highlight cpp %}
UCLASS()
class SANDBOX_API AMyCharacter
    : public ACharacter {
    GENERATED_BODY()
}
{% endhighlight %}

### The camera mode enum

Add an enumerator for each camera, plus a final `MAX` enumerator.

The `MAX` enumerator represents the number of cameras.
Access its value at compile or run time by casting to the underlying type with [`std::to_underlying`](https://en.cppreference.com/w/cpp/utility/to_underlying.html).

{% highlight cpp %}
UENUM(BlueprintType)
enum class ECharacterCameraMode : uint8 {
    FirstPerson UMETA(DisplayName = "First Person"),
    ThirdPerson UMETA(DisplayName = "Third Person"),
    MAX UMETA(Hidden)
};
{% endhighlight %}

To help cycle through the active camera, write a function to cycle through the enum values.

{% highlight cpp %}
template <typename Enum, auto MAX_VALUE = Enum::MAX>
Enum get_next(Enum current) {
    auto const next{std::to_underlying(current) + 1};
    static constexpr auto MAX{std::to_underlying(MAX_VALUE)};

    using Underlying = std::underlying_type_t<Enum>;
    return (next >= MAX) ? static_cast<Enum>(Underlying{0}) : static_cast<Enum>(next);
}
{% endhighlight %}

### Compile time camera configuration

Define a `constexpr` struct to create a compile time camera configuration.

{% highlight cpp %}
struct FCameraConfig {
    constexpr FCameraConfig(ECharacterCameraMode camera_mode,
                            char const* component_name,
                            bool needs_spring_arm,
                            bool use_pawn_control_rotation)
        : camera_mode(camera_mode)
        , camera_index(std::to_underlying(camera_mode))
        , component_name(component_name)
        , needs_spring_arm(needs_spring_arm)
        , use_pawn_control_rotation(use_pawn_control_rotation) {}

    ECharacterCameraMode camera_mode;
    std::underlying_type_t<ECharacterCameraMode> camera_index;
    char const* component_name;
    bool needs_spring_arm;
    bool use_pawn_control_rotation;
};
{% endhighlight %}

Create a `constexpr` array of `MAX` camera configurations.

{% highlight cpp %}

namespace ml::AMyCharacter {
inline static constexpr int32 camera_count{static_cast<int32>(ECharacterCameraMode::MAX)};
inline static constexpr FCameraConfig camera_configs[camera_count] = {
    {ECharacterCameraMode::FirstPerson, "Camera", false, true},
    {ECharacterCameraMode::ThirdPerson, "ThirdPersonCamera", true, true}};
}
{% endhighlight %}

Write a `consteval` function to calculate the required number of spring arms.

{% highlight cpp %}
namespace ml::AMyCharacter {
consteval int32 count_required_spring_arms() {
    int32 count{0};
    for (auto const& config : camera_configs) {
        if (config.needs_spring_arm) {
            ++count;
        }
    }
    return count;
}
}
{% endhighlight %}

### Class members

Add the camera class data members along with the member functions for changing camera.

Unreal component names require `FName` for their name however `FName` is not a `constexpr` type.
Use a `char const*` and convert it to `TCHAR*` later with Unreal's `ANSI_TO_TCHAR` macro.

{% highlight cpp %}
  public:
    static constexpr int32 camera_count{ml::AMyCharacter::camera_count};
    static constexpr int32 spring_arm_count{
        ml::AMyCharacter::count_required_spring_arms()};

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Camera")
    TArray<UCameraComponent*> cameras{};
    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Camera")
    TArray<USpringArmComponent*> spring_arms{};
    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Camera")
    ECharacterCameraMode camera_mode{ECharacterCameraMode::FirstPerson};

    UFUNCTION()
    void cycle_camera();
  private:
    virtual void handle_death();
    void disable_all_cameras();
    void change_camera_to(ECharacterCameraMode mode);
{% endhighlight %}

### Class implementation

#### Constructor

Initialise the camera and spring arm arrays to `nullptr`.

Loop through each camera config and initialise the `UCameraComponent` (and the `USpringArmComponent` if needed) and attach them to the character.
Other properties can be added by either adding data to `FCameraConfig` or creating a child Blueprint class and editing them in the class's viewport in the Unreal Editor.

{% highlight cpp %}
AMyCharacter::AMyCharacter() {
    PrimaryActorTick.bCanEverTick = true;

    // Initialise arrays
    cameras.Init(nullptr, camera_count);
    spring_arms.Init(nullptr, spring_arm_count);

    // Create cameras using configurations
    int32 spring_arm_index{0};
    for (auto const& config : ml::AMyCharacter::camera_configs) {
        auto& camera_component{cameras[config.camera_index]};
        camera_component = 
            CreateDefaultSubobject<UCameraComponent>(
                ANSI_TO_TCHAR(config.component_name));
        camera_component->bUsePawnControlRotation = 
            config.use_pawn_control_rotation;

        if (config.needs_spring_arm) {
            auto& spring_arm{spring_arms[spring_arm_index]};
            spring_arm = CreateDefaultSubobject<USpringArmComponent>(
                *FString::Printf(TEXT("SpringArm_%s"), *camera_component->GetName()));
            spring_arm->SetupAttachment(RootComponent);
            camera_component->SetupAttachment(spring_arm);

            ++spring_arm_index;
        } else {
            camera_component->SetupAttachment(RootComponent);
        }
    }
}
{% endhighlight %}

#### Disabling all cameras

{% highlight cpp %}
void AMyCharacter::disable_all_cameras() {
    for (auto* camera : cameras) {
        if (camera) {
            camera->SetActive(false);
        }
    }
}
{% endhighlight %}

#### Changing camera

To change the camera:

* Disable all cameras
* Get the desired camera index with `std::to_underlying(mode)`
* Enable the desired camera with `SetActive(true)` or enable a default camera if the index is out of range

{% highlight cpp %}
void AMyCharacter::change_camera_to(ECharacterCameraMode mode) {
    camera_mode = mode;

    disable_all_cameras();

    constexpr auto default_index{std::to_underlying(ECharacterCameraMode::FirstPerson)};
    auto const camera_index{std::to_underlying(camera_mode)};

    if (cameras.IsValidIndex(camera_index) && cameras[camera_index]) {
        cameras[camera_index]->SetActive(true);
    } else {
        if (cameras.IsValidIndex(default_index)) {
            cameras[default_index]->SetActive(true);
        }
    }
}
{% endhighlight %}

#### Cycling to the next camera state

Cycle to the next camera with:

{% highlight cpp %}
void AMyCharacter::cycle_camera() {
    change_camera_to(get_next(camera_mode));
}
{% endhighlight %}

## Conclusion

Setting up cameras requires initialising `UCameraComponent`s and using `SetActive` to toggle between them.
With some compile time code, we can easily handle any number of cameras.