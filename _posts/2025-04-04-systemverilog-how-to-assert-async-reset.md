---
layout: post
title:  "[SystemVerilog] How to create an assertion property for an asynchronous reset when using clocking blocks?"
date:   2025-04-04 18:51:00 +0100
categories: system_verilog
---

SystemVerilog's assertion system lets you describe your circuit's expected behaviour with time-based expressions.
These can run concurrently and verify the circuit operation at each clock cycle.

I had some trouble creating an assertion for an asynchonous reset with a clocking block.
The solution is to use multi-clock sequences or properties[^1].

I'll walk through an example with an active-low reset.

{% highlight verilog %}
// Assume this is driven elsewhere
logic reset_n;

clocking @ cb (posedge clk);
    default input #1step output #0;
    input my_data;
endclocking

property check_async_reset;
    @ (negedge reset_n) 1'b1
    ##1 @(posedge reset_n) 1'b1
    ##1 @(posedge clk) 1'b1
    ##1 (my_value_to_check == '0)
endproperty
{% endhighlight %}

Let's go through the property line by line.

{% highlight verilog %}
@ (negedge reset_n) 1'b1
{% endhighlight %}

We begin the assertion with the flag being pulled low.
We don't care about anything else so our assertion expression is `1'b1` so it will always pass.

{% highlight verilog %}
##1 @(posedge reset_n) 1'b1
{% endhighlight %}

The `##1` expression here says to continue on with the sequence until we detect a positive edge of `reset_n`.
The reset is de-asserted but we can't sample the value yet as the clocking block `cb` hasn't triggered an event yet.
At this point in the sequence, the property's "clock" is now `posedge reset_n`.

{% highlight verilog %}
##1 @(cb) 1'b1
{% endhighlight %}

We do the same trick again to move to the clocking block's clock domain.
We _still_ can't safely check `my_data` because the assertion sees the value from last clock edge.
As this is our first `cb` sampling event, `my_data` will likely be `X`.

{% highlight verilog %}
##1 (my_value_to_check == '0)
{% endhighlight %}

With one more `cb` cycle the property will be able to see `my_data` from the previous `cb` event.
We can now verify that the reset worked correctly. 

The same functionality can be implemented with the implication operator. I'd argue it's more readable but a slower to type.

{% highlight verilog %}
property check_async_reset;
    @ (negedge reset_n) 1'b1
    |=> @(posedge reset_n) 1'b1
    |=> @(posedge clk) 1'b1
    |=> (my_value_to_check == '0)
endproperty
{% endhighlight %}

[^1]: Section 16.13 in the IEEEE 1800-2023 LRM