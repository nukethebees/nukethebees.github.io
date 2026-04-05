---
layout: post
title:  "Replacing generic systems with Metalanguages"
date:   2025-06-11 18:00:00 +0100
categories: programming opinion
---

At a certain point, a programming language should consider replacing its generic type system with a metalanguage.

Programming languages are fundamentally used to define data types and transformations on them.
Generic systems let us write high-level definitions to generate functionally similar code for various types, reducing code duplication.

{% highlight cpp %}
template <typename T>
void call_foo(T obj) {
    obj.foo();
}
{% endhighlight %}

In this C++ example, the compiler will create a version of the `call_foo` function for any type `T` which has a `foo` method.

{% highlight cpp %}
template <typename T>
struct Complex {
    T real;
    T imag;

    auto abs() const {
        return sqrt(real*real + imag*imag);
    }
}
{% endhighlight %}

Similarly, this struct template models a complex number for any type that supports `sqrt` and multiplication.

Over time, generic systems have added compile-time constructs such as:
* Filters to reject certain types from being instantiated
* Conditional branching
* Functions and variables for both values and types
* Adding/removing members from classes

Why not extrapolate the trends and design a metalanguage that's specifically designed to create and manipulate code?
It would make it easier to do things like:

* Create type layouts like structs-of-arrays by iterating over AST tokens and types
* Customise function parameters and generate overloads
* Create utilities like enum-to-string functions
* Verify classes meet certain conditions
* Provide better error messages by analysing the types involved in the error
* Serialise types
* Automatically create unit tests

Developing a metalanguage would not be trivial by any means but with cases like C++ getting static reflection 28 years after its release in 1998, it's possible that a metalanguage could have been created in less time with better results.