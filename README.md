# cp5200

## Example

<pre>
require 'cairo'
require 'cp5200'

LED_WIDTH = 64
LED_HEIGHT = 32

controller = CPower::LedController.new('5200', '192.168.1.222', 5200)
controller.connect

# Draw image

surface = Cairo::ImageSurface.new Cairo::FORMAT_ARGB32, LED_WIDTH, LED_HEIGHT
cr = Cairo::Context.new surface

cr.set_source_rgb 0, 0, 0
cr.rectangle 0, 0, LED_WIDTH, LED_HEIGHT
cr.fill

cr.set_font_size 13

cr.set_source_rgb 1, 0, 0
cr.move_to 0, LED_HEIGHT - 5

cr.show_text nearest
cr.fill

surface.flush
data = surface.data.bytes

# Prepare image for cp5200

image = CPower::SimpleImageFormat.new(
    width: LED_WIDTH,
    height: LED_HEIGHT,
    property: 7
  )

0.upto(LED_HEIGHT-1) do |y|
  0.upto(LED_WIDTH-1) do |x|
    i = (x >> 3) + y * image.bytes_per_row

    image.r[i] |= (0x80 >> (x % 8)) if data[x * 4 + y * surface.stride + 2] >= 0x80
    image.g[i] |= (0x80 >> (x % 8)) if data[x * 4 + y * surface.stride + 1] >= 0x80
    image.b[i] |= (0x80 >> (x % 8)) if data[x * 4 + y * surface.stride] >= 0x80
  end
end

# Create window and send image

controller.setup_windows([{ x: 0, y: 0, width: LED_WIDTH, height: LED_HEIGHT }])
controller.set_window_image(
  {
    window_number: 0,
    mode: 14,
    speed: 0,
    stay_time: 0xffff,
    image_format: 0x4,
    x: 0, y: 0,
    image_data: image.to_binary_s
  }
)

controller.disconnect
</pre>
