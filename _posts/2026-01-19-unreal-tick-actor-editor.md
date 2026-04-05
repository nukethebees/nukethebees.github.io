---
layout: post
title:  "UE5: Ticking actors in the editor"
date:   2026-01-19 21:28:00 +0100
categories: software c++ unreal
---

Unreal Engine actors typically don't tick in the editor; however, this can be changed.
My use-case for this was to draw debug lines between waypoint actors in the editor.
[An example project can be found here.](https://github.com/nukethebees/ue5_examples/tree/master/ticking_actor_editor)

To enable actor editor ticking, override `AActor::ShouldTickIfViewportsOnly` and return `true`.
To ensure ticking only happens in the editor, surround the function definition with the `WITH_EDITOR` macro.

```cpp
#if WITH_EDITOR
virtual bool ShouldTickIfViewportsOnly() const { return true; }
#endif
```

A complete example is shown below.

## Header file

```cpp
#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"

#include "EditorTickingActor.generated.h"

UCLASS()
class AEditorTickingActor : public AActor {
    GENERATED_BODY()
  public:
    AEditorTickingActor();

    virtual void Tick(float delta_time) override;

#if WITH_EDITOR
    virtual bool ShouldTickIfViewportsOnly() const override { return true; }
#endif
};
```

## Source file

```cpp
#include "ticking_actor_editor/EditorTickingActor.h"

#include "Components/SceneComponent.h"

AEditorTickingActor::AEditorTickingActor() {
#if WITH_EDITOR
    PrimaryActorTick.bCanEverTick = true;
    PrimaryActorTick.bStartWithTickEnabled = true;
#else
    PrimaryActorTick.bCanEverTick = false;
#endif

    RootComponent = CreateDefaultSubobject<USceneComponent>(TEXT("Root"));
}

void AEditorTickingActor::Tick(float delta_time) {
    Super::Tick(delta_time);

#if WITH_EDITOR
    UE_LOG(LogTemp, Warning, TEXT("I'm ticking in the editor!"));
#endif
}
```