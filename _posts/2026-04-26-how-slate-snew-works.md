---
layout: post
title:  "UE5: Understanding Slate widget construction and writing factory functions"
date:   2026-04-26 15:38:00 +0100
categories: software cpp unreal
---

Writing Slate widgets in Unreal Engine often involves repetition, which naturally leads to factory functions.
Slate's types and syntax can easily trip people up, so this post will explain how Slate widgets are constructed and how to write some simple factory functions.
The limitations of this approach will also be highlighted.

First, it helps to understand how Slate widgets are constructed.
The usual way is the `SNew` macro[^1] (shown below):

```c++
#define SNew( WidgetType, ... ) \
	MakeTDecl<WidgetType>( 
        #WidgetType, 
        __FILE__, 
        __LINE__, 
        RequiredArgs::MakeRequiredArgs(__VA_ARGS__) 
    ) 
    <<= TYPENAME_OUTSIDE_TEMPLATE WidgetType::FArguments()
```

`SNew` constructs a builder object and configures the widget by passing its arguments via an overloaded `<<=` operator.

`MakeTDecl` constructs a `TSlateDecl<WidgetType>`[^2], an intermediate form of the widget, but does not call `WidgetType::Construct` on it.
`Construct` is called via the overloaded `<<=` operator, which takes a `WidgetType::FArguments` instance.

Every Slate widget contains its own `FArguments` struct defined within the `SLATE_BEGIN_ARGS/SLATE_END_ARGS` section.
This is what enables the Slate method chaining syntax, for example:

```c++
return SNew(STextBlock)
    .Text(FText::FromString(TEXT("Foo")))
    .Justification(ETextJustify::Center);
```

This system also means that you cannot (cleanly) partially build a widget in a factory function and then continue to configure it outside the function[^3].
When the `<<=` call finishes, the widget is fully constructed into a `TSharedRef<WidgetType>`.
As such, your factory function must do all the customisation that you require e.g.:

```c++
auto make_text_block{[](TCHAR const* text) -> TSharedRef<STextBlock> {
    return SNew(STextBlock)
        .Text(FText::FromString(text))
        .Justification(ETextJustify::Center);
}};
```

The limitation does not apply to slot objects like `SVerticalBox::Slot()` because they are argument builders rather than widgets.
You can create a slot object in a function, customise it, and then return it using `MoveTemp` (as `FSlot::FSlotArguments` is movable but not copyable).
The following code shows a slot factory function:

```c++
auto make_horizontal_slot{[]() -> SHorizontalBox::FSlot::FSlotArguments {
    return MoveTemp(SHorizontalBox::Slot() 
        .FillWidth(1.f)
        .VAlign(VAlign_Fill)
        .HAlign(EHorizontalAlignment::HAlign_Center));
}};
```

[^1]: `SNew` is defined in `<UE Root>\Engine\Source\Runtime\SlateCore\Public\Widgets\DeclarativeSyntaxSupport.h`
[^2]: `TSlateDecl` and `MakeTDecl` are both declared in the same file as `SNew`
[^3]: If variation is needed, use function parameters rather than trying to force post-construction chaining