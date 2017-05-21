import math

{.passl: "-lm".}
{.compile: "private/jo_gif.c".}


type jo_gif_t = object
  fp: ptr FILE
  palette: array[0x00000300, cuchar]
  width: cshort
  height: cshort
  repeat: cshort
  numColors: cint
  palSize: cint
  frame: cint

##  width/height | the same for every frame
##  repeat       | 0 = loop forever, 1 = loop once, etc...
##  palSize		   | must be power of 2 - 1. so, 255 not 256.
proc jo_gif_start(filename: cstring; width: cshort; height: cshort; repeat: cshort;
                  palSize: cint): jo_gif_t {.importc.}

##  gif			     | the state (returned from jo_gif_start)
##  rgba         | the pixels
##  delayCsec    | amount of time in between frames (in centiseconds)
##  localPalette | true if you want a unique palette generated for this frame (does not effect future frames)
proc jo_gif_frame(gif: ptr jo_gif_t; rgba: ptr cuchar; delayCsec: cshort;
                  localPalette: cint) {.importc.}

##  gif          | the state (returned from jo_gif_start)
proc jo_gif_end(gif: ptr jo_gif_t) {.importc.}




type
  Gif* = ref object
    active: bool
    gif: jo_gif_t
    delay: float
    delayErr: float
    expectedFrameSize: int

  Color* = object
    r*, g*, b*, x: uint8


proc close*(gif: Gif)

proc finalize*(gif: Gif) =
  if gif.active:
    gif.close()


proc newGif*(filename: string, width, height: int, fps=30.0, colors=64, loop=true): Gif =
  new result, finalize

  result.gif = jo_gif_start(
    cstring(filename), cshort(width), cshort(height),
    cshort(if loop: 0 else: 1), cint(colors))

  result.active = true
  result.delay = 1.0 / fps
  result.expectedFrameSize = width * height * 4


proc close*(gif: Gif) =
  assert gif.active
  jo_gif_end(addr gif.gif)
  gif.active = false


proc write*(gif: Gif, pixels: pointer, delay=0.0, localPalette=false) =
  assert gif.active

  var delay =
    if delay == 0.0:
      gif.delay
    else:
      delay

  # Convert delay to centiseconds and store error
  var
    n = delay + gif.delayErr
    c = floor(n * 100)
    d = c / 100
  gif.delayErr = n - d

  jo_gif_frame(
    addr gif.gif, cast[ptr cuchar](pixels),
    cshort(c), cint(localPalette))


proc checkedWrite[T](gif: Gif, pixels: T, delay: float, localPalette: bool) =
  var pixels = pixels
  assert pixels.len * pixels[0].sizeof == gif.expectedFrameSize
  gif.write(addr pixels[0], delay, localPalette)


proc write*(gif: Gif, pixels: seq[uint32], delay=0.0, localPalette=false) =
  checkedWrite[seq[uint32]](gif, pixels, delay, localPalette)


proc write*(gif: Gif, pixels: seq[uint8], delay=0.0, localPalette=false) =
  checkedWrite[seq[uint8]](gif, pixels, delay, localPalette)


proc write*(gif: Gif, pixels: seq[Color], delay=0.0, localPalette=false) =
  checkedWrite[seq[Color]](gif, pixels, delay, localPalette)



when isMainModule:
  import math

  var
    width = 128
    height = 128
    filename = "test.gif"
    gif = newGif(filename, width, height, colors=128)
    pixels = newSeq[Color](width * height)

  echo "writing '", filename, "'..."

  for frame in 0..<120:
    for x in 0..<width:
      for y in 0..<height:
        let
          t = float(frame) / 30 + 20
          ox = float(x) / float(width) * 2 - 1
          oy = float(y) / float(height) * 2 - 1

        pixels[x + y * width] = Color(
          r: uint8((cos(ox * 2 + t * 5) + 1) * 127),
          g: uint8((cos(oy * 3 + t * 1.3) + 1) * 127),
          b: uint8((cos(ox * oy * 7 + t * 0.7) + 1) * 127))

    gif.write(pixels)

  gif.close()

  echo "done"
