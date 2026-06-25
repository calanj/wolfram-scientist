# lib/ — accreted Wolfram Language assets

Reusable functions the Scientist factors out of its experiments. Each `.wl` file
should define one focused, documented function with a runnable usage example, so
future runs (and humans) can reuse it instead of re-deriving it. This directory
growing — and being *used* by later runs — is the concrete, measurable form of
the Scientist's "self-improvement".

Load everything with:

```wl
Get /@ FileNames["*.wl", "lib"]
```
