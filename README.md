# install
`git clone https://github.com/davekch/LEDvis.jl.git`

```julia
using Pkg
Pkg.resolve()
Pkg.instantiate()
import Conda
Conda.pip_interop(true)
Conda.pip("install", "rtmidi")
```
