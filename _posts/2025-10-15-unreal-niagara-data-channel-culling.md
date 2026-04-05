---
layout: post
title:  "UE5 Niagara Data Channels: Preventing Particle Culling Away from Origin"
date:   2025-10-15 19:26:00 +0100
categories: software c++ unreal
---

I recently had an issue where my Niagara systems seemingly wouldn't spawn occasionally in Unreal Engine 5.
I noticed that the particles were visible only when I was close to or looking towards the origin.
It turned out that the systems were fine but the particles were being culled.

My systems were being spawned by a Niagara Data Channel using the "Niagara Data Channel Islands" type.

<figure style="text-align: center;">
  <img src="/images/2025-10-15-unreal-niagara-data-channel-culling/niagara_data_channel.PNG"  style="max-width: 100%; height: auto; display: inline-block;" />
  <figcaption style="margin-top: 8px; font-style: italic; color: #555;">
    The data channel configuration
  </figcaption>
</figure>

The solution lay with the `FNiagaraDataChannelSearchParameters` object that you pass to `UNiagaraDataChannelLibrary::WriteToNiagaraDataChannel` when creating a channel writing. You must either set the `Location` or `OwningComponent` member variables so the emitter is spawned in the correct island.

To learn more about Niagara Data Channels, I recommend viewing the following:

* [Niagara Data Channels Overview](https://dev.epicgames.com/documentation/en-us/unreal-engine/niagara-data-channels-overview)
* [Niagara Data Channels Intro](https://dev.epicgames.com/community/learning/tutorials/RJbm/unreal-engine-niagara-data-channels-intro)
* [Niagara Data Channels 5.4 Update](https://dev.epicgames.com/community/learning/tutorials/OpJ8/unreal-engine-niagara-data-channels-5-4-update)

# Full Explanation

Niagara Data Channels let you efficiently spawn systems throughout your world.
They're especially useful for effects such as spark from bullet collisions.

Epic recommends using the "Islands" data channel type as opposed to the "Global" type.
The islands type breaks the world up into adjacent cubes.
The idea is that systems spawned in islands far from the player won't be rendered and thus their cost is significantly reduced.

As in the figure above, you specify the data the channel accepts.
There is also a field for the emitter systems that the channel supports.

To write data to a channel you must create a writer using `UNiagaraDataChannelLibrary::WriteToNiagaraDataChannel` from `NiagaraDataChannel.h`.
I've included the signature below with the important parameters annotated.

{% highlight cpp %}
static UNiagaraDataChannelWriter * CreateDataChannelWriter ( 
    // The world to spawn the systems in
    const UObject* WorldContextObject,
    // The data channel asset to write to
    const UNiagaraDataChannelAsset* Channel,
    // To be explained
    FNiagaraDataChannelSearchParameters SearchParams,
    // The number of systems to spawn
    int32 Count,
    bool bVisibleToGame,
    bool bVisibleToCPU,
    bool bVisibleToGPU,
    const FString& DebugSource
);
{% endhighlight %}

The default constructed search parameters uses `FVector::ZeroVector` for `Location`, meaning your Niagara system will be spawned in the island there.
Once leave this island, your particles will be culled unless you have line of sight to this island.

The `FNiagaraDataChannelSearchParameters` struct has three member variables:
* `bool bOverrideLocation`
* `FVector Location`
* `TObjectPtr<USceneComponent> OwningComponent`

By setting `OwningComponent` or `Location` with `bOverrideLocation`, we can tell the writer what island to spawn the system in.
In most cases I recommend setting the owning component to the player as it's what will be viewing the particles.

# Creating and using a Niagara Data Channel writer

The following is a short example of using the writer with my `UNiagaraNdcWriterSubsystem` class. [The full source code can be found here.](https://github.com/nukethebees/ue5_sandbox/blob/1a6a1a97c4895a09064fe7e8f9b52a35228fdcbb/Source/Sandbox/subsystems/world/NiagaraNdcWriterSubsystem.cpp)

The subsystem stores a `FNiagaraDataChannelSearchParameters` member variable called `search_parameters_`. When the world begins (`OnWorldBeginPlay()`), I set the  `search_parameters_` owning component to the player's root component.

{% highlight cpp %}
void UNiagaraNdcWriterSubsystem::OnWorldBeginPlay(UWorld& world) {
    Super::OnWorldBeginPlay(world);
    FCoreDelegates::OnEndFrame.AddUObject(this, &UNiagaraNdcWriterSubsystem::flush_ndc_writes);
    update_owning_component(world);
}
{% endhighlight %}

You can get the active player with `UGameplayStatics::GetPlayerCharacter` from `Kismet/GameplayStatics.h`.

{% highlight cpp %}
void UNiagaraNdcWriterSubsystem::update_owning_component(UWorld& world) {
    if (auto* character{UGameplayStatics::GetPlayerCharacter(&world, 0)}) {
        search_parameters_.OwningComponent = character->GetRootComponent();
    }
}
{% endhighlight %}

I wrote a small helper function to create the writer.

{% highlight cpp %}
auto UNiagaraNdcWriterSubsystem::create_data_channel_writer(UWorld& world, NdcAsset& asset, int32 n)
    -> NdcWriter* {
    constexpr bool visible_to_game{false};
    constexpr bool visible_to_cpu{true};
    constexpr bool visible_to_gpu{true};

    auto* writer{UNiagaraDataChannelLibrary::WriteToNiagaraDataChannel(
        &world,
        &asset,
        search_parameters_,
        n,
        visible_to_game,
        visible_to_cpu,
        visible_to_gpu,
        writer_debug_source
    )};
    return writer;
}
{% endhighlight %}

The code below is a summarised version of how the subsystem writes to the data channel.
Simply open the writer and use the `WriteX` member functions to write your data to the channel


{% highlight cpp %}
static auto const position_label{FName("position")};
static auto const rotation_label{FName("rotation")};

auto const n_systems{ /* get n emitters... */ };
auto* writer{create_data_channel_writer(*world, asset, n_systems)};

for (int32 i{0}; i < n_systems; ++i) {
    writer->WritePosition(position_label, i, locations[i]);
    writer->WriteVector(rotation_label, i, rotations[i]);
}
{% endhighlight %}

# Conclusion

This post details an issue where Niagara particles were being culled in Unreal Engine 5 when using Niagara Data Channel assets.
The issue was due to the channel's search parameters being left blank when the channel writer was opened.
Setting the search parameters to spawn the Niagara system in the data channel island near the player will solve the culling issue.