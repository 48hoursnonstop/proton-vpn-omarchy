pragma Singleton
import QtQuick
import qs.Commons
import qs.Commons as Commons

// Local roles derived from Omarchy, never a separate plugin theme.
QtObject {
  property bool reducedMotion: false
  readonly property int transitionMs: reducedMotion ? 0 : 120
  readonly property int panelWidth: Style.space(420)
  readonly property int panelHeight: Style.space(640)
  readonly property int controlHeight: Math.max(40, Style.space(40))

  function linear(value) {
    return value <= 0.04045 ? value / 12.92 : Math.pow((value + 0.055) / 1.055, 2.4)
  }

  function luminance(color) {
    return 0.2126 * linear(color.r) + 0.7152 * linear(color.g) + 0.0722 * linear(color.b)
  }

  function contrast(a, b) {
    var first = luminance(a), second = luminance(b)
    return (Math.max(first, second) + 0.05) / (Math.min(first, second) + 0.05)
  }

  function blend(foreground, background, amount) {
    return Qt.rgba(foreground.r * amount + background.r * (1 - amount),
                   foreground.g * amount + background.g * (1 - amount),
                   foreground.b * amount + background.b * (1 - amount), 1)
  }

  function secondaryText(foreground) {
    var background = blend(Commons.Color.popups.background, Commons.Color.background, Commons.Color.popups.background.a)
    var surfaces = [background]
    var fills = [Style.normalFillFor(foreground, Commons.Color.accent),
      Style.hoverFillFor(foreground, Commons.Color.accent), Style.focusFillFor(foreground, Commons.Color.accent),
      Style.selectedFillFor(foreground, Commons.Color.accent)]
    for (var i = 0; i < fills.length; ++i) surfaces.push(blend(fills[i], background, fills[i].a))
    function readable(color) {
      for (var i = 0; i < surfaces.length; ++i) if (contrast(color, surfaces[i]) < 4.5) return false
      return true
    }
    if (readable(Commons.Color.muted)) return Commons.Color.muted
    for (var amount = 0.65; amount < 1; amount += 0.05) {
      var candidate = blend(foreground, background, amount)
      if (readable(candidate)) return candidate
    }
    return foreground
  }
}
