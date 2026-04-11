---
layout: post
title:  "Unreal Engine 5 Simplified Mass Entity Query API Quickstart"
date:   2025-10-13 13:50:00 +0100
categories: software cpp unreal
---

# Introduction

Unreal Engine 5 (UE5) features an entity component system (ECS) for high efficiency batch processing called Mass Entity.
Epic developed a simplified Mass Entity API but I feel [the documentation](https://dev.epicgames.com/documentation/en-us/unreal-engine/simplified-mass-processor) is sparse.

This post provides a full example to show its use.

[The code for this example can be found here.](https://github.com/nukethebees/ue5_examples/tree/master/mass_simplified_api)

If you’re new to Mass Entity, check out these resources first:

* [MassEntity Overview](https://dev.epicgames.com/documentation/en-us/unreal-engine/overview-of-mass-entity-in-unreal-engine)
* [Your First 60 Minutes with Mass](https://dev.epicgames.com/community/learning/tutorials/JXMl/unreal-engine-your-first-60-minutes-with-mass)
* [Large Numbers of Entities with Mass in UE5 (YouTube)](https://www.youtube.com/watch?v=f9q8A-9DvPo)

# Example Overview

In this example we'll:
* Create entities with a transform fragment and a shared const velocity fragment
* Make a processor to manipulate our entities using the simplified API
* Define an actor to spawn entities
* Run a level with our entities and view them in the Mass debugger.

# Required setup
Add the `MassGameplay` plugin to your project's `.uproject` file.

```json
{
    "Name": "MassGameplay",
    "Enabled": true
}
```

Add `MassEntity` and `MassCommon` to your `.Build.cs` file.

```c#
PublicDependencyModuleNames.AddRange(new string[] {
    "Core", "CoreUObject", "Engine", "InputCore", "EnhancedInput",
    "MassEntity", "MassCommon"
});
```

# Fragment Setup
Our entity data is stored in Mass fragments which are just normal C++ structs.

Include these headers.

```cpp
#include "CoreMinimal.h"
#include "MassEntityTypes.h"

#include "MassFragments.generated.h"
```

Define the transform fragment inheriting from `FMassFragment`.

```cpp
USTRUCT()
struct FMassTransformFragment : public FMassFragment {
    GENERATED_BODY()

    FMassTransformFragment() = default;
    FMassTransformFragment(FTransform Transform)
        : Transform(Transform) {}

    UPROPERTY()
    FTransform Transform{};
};
```


Define the velocity fragment inheriting from `FMassConstSharedFragment`.

```cpp
USTRUCT()
struct FMassVelocityConstSharedFragment : public FMassConstSharedFragment {
    GENERATED_BODY()

    FMassVelocityConstSharedFragment() = default;
    FMassVelocityConstSharedFragment(FVector Velocity)
        : Velocity(Velocity) {}

    UPROPERTY()
    FVector Velocity{FVector::ZeroVector};
};
```

Now we need to implement our fragment processing.

With the simplified Mass Entity API, processing is performed in a struct inheriting from `UE::Mass::FQueryExecutor` which is wrapped in a `UMassProcessor` class.

In this example, the query and wrapper will coexist in the same file: `MassVelocityProcessor.(h/cpp)`.

# Query Design

## Header File

Add these includes:

```cpp
#include "CoreMinimal.h"
#include "MassProcessor.h"
#include "MassQueryExecutor.h"

#include "MassFragments.h"

#include "MassVelocityProcessor.generated.h"
```

The query class:

```cpp
struct FMassVelocityExecutor : public UE::Mass::FQueryExecutor {
    FMassVelocityExecutor() = default;

    // Define which fragments we need and how we access them
    using Query = UE::Mass::FQueryDefinition<
        UE::Mass::FMutableFragmentAccess<FMassTransformFragment>,
        UE::Mass::FConstSharedFragmentAccess<FMassVelocityConstSharedFragment>>;

    Query Accessors{*this};

    virtual void Execute(FMassExecutionContext& Context) override;
};
```

`Query`'s template parameters specify the required data and its access modes.
We need mutable access to `FMassTransformFragment` and access to the const shared `FMassVelocityConstSharedFragment`.

`Execute` performs the fragment processing.

## Source File

Add the following include:

```cpp
#include "MassExecutionContext.h"
```

The execution function:

```cpp
void FMassVelocityExecutor::Execute(FMassExecutionContext& Context) {
    constexpr auto Executor{[](FMassExecutionContext& context, Query& query) {
        auto const N{context.GetNumEntities()};
        auto const DeltaTime{context.GetDeltaTimeSeconds()};
        auto const Transforms{context.GetMutableFragmentView<FMassTransformFragment>()};
        auto const& Velocity{context.GetConstSharedFragment<FMassVelocityConstSharedFragment>()};

        auto const displacement{Velocity.Velocity * DeltaTime};
        for (int32 i{0}; i < N; ++i) {
            Transforms[i].Transform.AddToTranslation(displacement);
        }
    }};

    ForEachEntityChunk(Context, Accessors, std::move(Executor));
}
```

The processing is carried out in a lambda which is passed to `ForEachEntityChunk`.
Chunks are groups of entities that are processed in bulk by a single lambda call.
The following `ForEach` functions are available:

* `ForEachEntity`
* `ForEachEntityChunk`
* `ParallelForEachEntity`
* `ParallelForEachEntityChunk`

The non-`Chunk` functions can introduce a large overhead as the `GetFragment` functions must be called once per entity instead of just once per chunk.
The parallel versions distribute the processing over multiple threads.

Our lambda accesses the entities passed to it by `ForEachEntityChunk` and updates the fragment's transform based on the velocity and delta time.

# Processor

The processor just wraps the Query class into the main `UMassProcessor` type used by Mass Entity.

## Header File

It contains a constructor and member variables for the query.

```cpp
UCLASS()
class MASS_SIMPLIFIED_API_API UMassVelocityProcessor : public UMassProcessor {
    GENERATED_BODY()
  public:
    UMassVelocityProcessor();
  private:
    FMassEntityQuery EntityQuery;
    TSharedPtr<FMassVelocityExecutor> Executor;
};
```

Note: The macro `MASS_SIMPLIFIED_API_API` comes from Unreal's use of `<module>_API` and I named the project `mass_simplified_api`.

## Source File

Add the following include for the `ProcessorGroupNames` to be used later.

```cpp
#include "MassCommonTypes.h"
```

Implement the constructor like so:

```cpp
UMassVelocityProcessor::UMassVelocityProcessor()
    : EntityQuery(*this)
    , Executor(UE::Mass::FQueryExecutor::CreateQuery<FMassVelocityExecutor>(EntityQuery, this)) {
    AutoExecuteQuery = Executor;

    ExecutionOrder.ExecuteInGroup = UE::Mass::ProcessorGroupNames::Movement;
    SetProcessingPhase(EMassProcessingPhase::PrePhysics);
    ExecutionFlags = static_cast<int32>(EProcessorExecutionFlags::AllWorldModes);
    bAutoRegisterWithProcessingPhases = true;
}
```

You must initialise `EntityQuery` with `*this` or it won't be registered with the processor and thus won't run.

Create the executor object to process the fragments.

* `AutoExecuteQuery` should be self-explanatory
* `ExecutionOrder` tells Mass when to run the processor relative to other processors
* The Processing Phase is Mass's version of [tick groups](https://dev.epicgames.com/documentation/en-us/unreal-engine/actor-ticking-in-unreal-engine) which denote what part of the frame the processor runs in
* `ExecutionFlags` say what game context the Processor should run in
* `bAutoRegisterWithProcessingPhases` tells the system to automatically register our processor with the Mass system

# Spawner Actor

We'll make a simple actor to spawn our entities.
It defines an entity archetype and spawns an entity each tick.

Batch spawning is more efficient but I want to keep things simple here.
For reference, batch spawning is performed using `FMassEntityManager::BatchCreateEntities` (potentially with `FMassEntityManager::BatchReserveEntities` to pre-allocate entities if many are expected).


## Header File

Add these includes.

```cpp
#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "MassArchetypeTypes.h"
#include "MassEntityTypes.h"

#include "MassEntitySpawner.generated.h"
```

Create a forward declaration for the Mass Entity subsystem.

```cpp
class UMassEntitySubsystem;
```

Our class consists of entity information variables and member functions to define and spawn entities.

```cpp
UCLASS()
class AMassEntitySpawner : public AActor {
    GENERATED_BODY()
  public:
    AMassEntitySpawner();

    // Shared velocity for all spawned entities
    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mass Entity")
    FVector EntityVelocity{100.0f, 0.0f, 0.0f};
  protected:
    virtual void BeginPlay() override;
    virtual void Tick(float DeltaTime) override;
  private:
    void CreateArchetype(UMassEntitySubsystem& MassEntitySubsystem,
                         FMassEntityManager& EntityManager);
    void CreateSharedValues(FMassEntityManager& EntityManager);
    void SpawnEntity(UMassEntitySubsystem& MassEntitySubsystem, FMassEntityManager& EntityManager);

    FMassArchetypeHandle Archetype{};
    FMassArchetypeSharedFragmentValues SharedValues{};
};
```

## Source File

Add the following includes.

```cpp
#include "MassEntitySpawner.h"

#include "MassArchetypeTypes.h"
#include "MassEntitySubsystem.h"
#include "MassFragments.h"
```

In the constructor I set the ticking to 20 Hz to reduce the number of entities spawned per second.

```cpp
AMassEntitySpawner::AMassEntitySpawner() {
    PrimaryActorTick.bCanEverTick = true;
    PrimaryActorTick.TickInterval = 0.05f;
}
```

In `BeginPlay`, create our archetype and its shared values.

```cpp
void AMassEntitySpawner::BeginPlay() {
    Super::BeginPlay();

    auto MassEntitySubsystem{GetWorld()->GetSubsystem<UMassEntitySubsystem>()};
    if (!MassEntitySubsystem) {
        UE_LOG(LogTemp, Error, TEXT("MassEntitySubsystem not found!"));
        return;
    }
    auto& EntityManager{MassEntitySubsystem->GetMutableEntityManager()};

    CreateArchetype(*MassEntitySubsystem, EntityManager);
    CreateSharedValues(EntityManager);
}
```

Archetypes are created with `EntityManager::CreateArchetype`.
Specify the required data in `FMassArchetypeCompositionDescriptor` and some additional data such as the debug name in `FMassArchetypeCreationParams`.

```cpp
void AMassEntitySpawner::CreateArchetype(UMassEntitySubsystem& MassEntitySubsystem,
                                         FMassEntityManager& EntityManager) {
    auto Descriptor{FMassArchetypeCompositionDescriptor{}};
    Descriptor.Fragments.Add(*FMassTransformFragment::StaticStruct());

    Descriptor.ConstSharedFragments.Add(*FMassVelocityConstSharedFragment::StaticStruct());

    auto CreationParams{FMassArchetypeCreationParams{}};
    CreationParams.DebugName = FName(TEXT("ExampleArchetype"));

    Archetype = EntityManager.CreateArchetype(Descriptor, CreationParams);
}
```

`CreateSharedValues` adds the shared fragment data to our `SharedValues` data.
The `EntityManager` caches the shared values so subsequent calls just return a handle to the existing value.
The shared fragments need to be sorted relative to their definition in the Archetype so be sure to call `.Sort()` after creating them.

```cpp
void AMassEntitySpawner::CreateSharedValues(FMassEntityManager& EntityManager) {
    auto const VelocityHandle{
        EntityManager.GetOrCreateConstSharedFragment<FMassVelocityConstSharedFragment>(
            EntityVelocity)};

    SharedValues.Add(VelocityHandle);
    SharedValues.Sort();
}
```

Within the tick we just call `SpawnEntity`.

```cpp
void AMassEntitySpawner::Tick(float DeltaTime) {
    Super::Tick(DeltaTime);

    auto MassEntitySubsystem{GetWorld()->GetSubsystem<UMassEntitySubsystem>()};
    if (!MassEntitySubsystem) {
        UE_LOG(LogTemp, Error, TEXT("MassEntitySubsystem not found!"));
        return;
    }
    auto& EntityManager{MassEntitySubsystem->GetMutableEntityManager()};

    SpawnEntity(*MassEntitySubsystem, EntityManager);
}
```

`SpawnEntity` creates a new entity handle using `EntityManager.CreateEntity` and configures the initial transform.

```cpp
void AMassEntitySpawner::SpawnEntity(UMassEntitySubsystem& MassEntitySubsystem,
                                     FMassEntityManager& EntityManager) {
    FMassEntityHandle EntityHandle{EntityManager.CreateEntity(Archetype, SharedValues)};
    {
        auto& TransformFragment{
            EntityManager.GetFragmentDataChecked<FMassTransformFragment>(EntityHandle)};
        TransformFragment.Transform = GetActorTransform();
    }
}

```

# Simulation

Now we'll use our entity spawner and view the fragment data in the Mass debugger ([see overview](https://dev.epicgames.com/documentation/en-us/unreal-engine/mass-debugger-overview)).

Load the Unreal editor and create an instance of `AMassEntitySpawner`.

<figure class="post-figure">
  <img src="/images/2025-10-13-unreal-mass-entity-simplified-query-api/actors.PNG" alt="Actors list"  />
  <figcaption>
    The actors list in the world outliner. The MassEntitySpawner is visible.
  </figcaption>
</figure>

Run the game and load the Mass debugger.

<figure class="post-figure">
  <img src="/images/2025-10-13-unreal-mass-entity-simplified-query-api/menu.png"   />
  <figcaption>
    The button to load the Mass Entity debugger
  </figcaption>
</figure>

In the top right of the debugger window, set the environment to our active level.

<figure class="post-figure">
  <img src="/images/2025-10-13-unreal-mass-entity-simplified-query-api/env.png"   />
  <figcaption>
    The dropdown menu to choose the environment to debug
  </figcaption>
</figure>

You should be able to see the processor in the processor list.

<figure class="post-figure">
  <img src="/images/2025-10-13-unreal-mass-entity-simplified-query-api/proc.PNG"   />
  <figcaption>
    Our Mass processor in the debug menu
  </figcaption>
</figure>

You should also see the archetype and the number of entities.

<figure class="post-figure">
  <img src="/images/2025-10-13-unreal-mass-entity-simplified-query-api/archetype.PNG"   />
  <figcaption>
    Our archetype in the archetype subwindow with related statistics
  </figcaption>
</figure>

Use the `Select Fragments` dropdown box and check all the fragments.

<figure class="post-figure">
  <img src="/images/2025-10-13-unreal-mass-entity-simplified-query-api/tickbox.png"   />
  <figcaption>
    The tickbox for viewing entity values
  </figcaption>
</figure>

You should now see the fragments and their values.

<figure class="post-figure">
  <img src="/images/2025-10-13-unreal-mass-entity-simplified-query-api/values.PNG"   />
  <figcaption>
    Some fragment values for our active entities
  </figcaption>
</figure>

# Conclusion

This article has shown how to use the simplified Mass Entity API.
In summary:

* Define fragment structs
* Create a query executor inheriting from `UE::Mass::FQueryExecutor`
* Wrap the executor in a `UMassProcessor`
* Define an archetype using `FMassEntityManager::CreateArchetype`
* Spawn entities using `FMassEntityManager::CreateEntity`
