---
layout: hub-post
title: "UObjects"
last_updated: 2026-07-11 23:59:00 +0100
---

## Add a button to the editor details panel

Using `CallInEditor` with `UNFUNCTION` allows you to put a button in the editor details panel.

```c++
UFUNCTION(CallInEditor, Category = "Ship")
void apply_asset_configuration();
```

<figure class="post-figure">
  <img src="/images/unreal_notes/uobjects/details_button.webp"
       alt="A UFunction button in an actor's details panel"/>
  <figcaption>
    A UFunction button in an actor's details panel
  </figcaption>
</figure>

## Interfaces

I couldn't make interfaces show up in the editor i.e.

```c++
UPROPERTY(EditAnywhere, Category = "Ship")
TScriptInterface<ITestEntity> target_ship{nullptr};
```

I tried to use a constrained `AActor*` using `ObjectMustImplement` however the filtering didn't seem to work.

```c++
UPROPERTY(EditAnywhere,
          meta = (ObjectMustImplement = "/Script/Sandbox.TestEntity"),
          Category = "Ship")
TObjectPtr<AActor> target_ship{nullptr};
```

It seems using `AActor*` properties and `CastChecked` is the simplest solution.

```c++
auto const* const target_entity_interface{CastChecked<ITestEntity>(target)};
auto const target_handle{target_entity_interface->get_entity_handle()};
```

## CastChecked<T>

`CastChecked<T>` is a useful function.

It is equivalent to

```c++
auto foo{Cast<T>(bar)};
check(foo);
```
