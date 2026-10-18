-- Warm Gruvbox dark: no blue/pink accents. Legacy keys keep reference modules compatible.
local accent = {
  cyan = 0xfffabd2f, purple = 0xffd79921, sage = 0xffd79921,
  rose = 0xfffb4934, gold = 0xfffabd2f, peach = 0xfffe8019,
  teal = 0xffa89984, steel = 0xffa89984, primary = 0xfffabd2f,
}
return {
  black = 0xff1d2021, white = 0xffebdbb2, red = 0xfffb4934,
  green = 0xffd79921, blue = 0xfffabd2f, yellow = 0xfffabd2f,
  orange = 0xfffe8019, magenta = 0xffd79921, grey = 0xff928374,
  shadow = 0xff1d2021, transparent = 0x00000000,
  sora = accent,
  semantic = { error = 0xfffb4934, warn = 0xfffe8019, ok = 0xffd79921, info = 0xfffabd2f },
  highlight = 0xfffabd2f,
  bar = { bg = 0xf2282828, border = 0xff504945 },
  popup = { bg = 0xf2282828, border = 0xff665c54 },
  bg1 = 0xff3c3836, bg2 = 0xff504945,
  with_alpha = function(color, alpha)
    if alpha < 0 or alpha > 1 then return color end
    return (color & 0x00ffffff) | (math.floor(alpha * 255) << 24)
  end,
}
