---
layout: post
title:  "[SystemVerilog] Verifying interface types within a module"
date:   2025-03-31 19:10:38 +0100
categories: system_verilog
---
Modules and interfaces can both be parameterised. 
A module and interface may share some parameters and we want to ensure the interface that the module is connecting to has the same parameters.
Unfortunately you cannot simply do `interface.parameter` despite the value surely being instantiated when the module is instantiated.

The solution is to use the `$bits` function. We can access the widths of data-types in the interface and verify them in generate constructs.

{% highlight verilog %}
    interface MyIf
    #(
        parameter int WIDTH = 8,
        localparam type T = logic [WIDTH-1:0]
    )();
        T out;

        modport mp(output out);
    endinterface

    module MyMod
    #(
        parameter int WIDTH = 8,
        localparam type T = logic [WIDTH-1:0]
    )(
        MyIf.mp my_if
    );

        localparam int IF_WIDTH = $bits(my_if.T);
        generate
            if (IF_WIDTH != WIDTH) begin
                $error("Interface has width of %d but module param is %d.", 
                       IF_WIDTH, WIDTH)
            end
        endgenerate
    endmodule
{% endhighlight %}

Sadly this solution is only appropriate for types.
If we tried to use this trick to pass around constants then we run into issues with the language.
Packed arrays are only guaranteed to work with a 16 bit index and 24 bits for unpacked arrays.