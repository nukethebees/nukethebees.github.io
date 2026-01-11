---
layout: post
title:  "UE5: Using the ThisClass typedef for more concise code"
date:   2026-01-11 12:50:00 +0100
categories: software c++ unreal
---

In the Unreal Engine, the `Super` typedef for a `UCLASS`'s base class is well known.
Less well known is the `ThisClass` typedef that aliases the derived class itself.
Each `UCLASS` generates its own `ThisClass`, so it will always refer to the class being defined.
It's useful for saving time when binding delegates or copying code between multiple `UCLASS`s e.g.

{% highlight cpp %}
MyCollisionBox->OnComponentBeginOverlap.AddDynamic(
    this, 
    &AMyExtremelyVerboseActorTypeName::OnOverlapBegin);
MyCollisionBox->OnComponentBeginOverlap.AddDynamic(
    this, 
    &ThisClass::OnOverlapBegin);
{% endhighlight %}

I will illustrate the typedef's source with the following `UCLASS` definition.

{% highlight cpp %}
#pragma once

#include "CoreMinimal.h"

#include "ExampleClass.generated.h"

UCLASS()
class UExampleClass : public UObject {
    GENERATED_BODY()
  public:
    UExampleClass();
};
{% endhighlight %}

In the expanded `GENERATED_BODY` macro, we find the typedef.

{% highlight cpp %}
typedef UObject Super;
typedef UExampleClass ThisClass;
{% endhighlight %}

For completeness, we can verify that `ThisClass` and `UExampleClass` are the same with `static_assert` and `std::is_same_v` from `<type_traits>`.

{% highlight cpp %}
#include "ExampleClass.h"

#include <type_traits>

UExampleClass::UExampleClass() {
    static_assert(std::is_same_v<UExampleClass, ThisClass>);
}
{% endhighlight %}

`ThisClass` is a small but useful typedef that can save you time and make your code more concise.