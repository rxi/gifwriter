# gifwriter
A Nim library for writing animated GIFs, based on
[jo_gif](http://www.jonolick.com/home/gif-writer).

## Basic Usage
```nim
import gifwriter

var
  gif = newGif("out.gif", 128, 128, fps=24)
  pixels = newSeq[Color](128 * 128)

for frame in 0..<64:
  for i in 0..<pixels.len:
    pixels[i].r = uint8(frame * 4 + i * 2)
    pixels[i].g = uint8(frame * 4 + i div 64)
    pixels[i].b = uint8(frame * 4 + i * 4)
  gif.write(pixels)

gif.close()
```

## License
This library is free software; you can redistribute it and/or modify it under
the terms of the MIT license. See [LICENSE](LICENSE) for details.
