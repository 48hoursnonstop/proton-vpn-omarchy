.pragma library

function normalize(value) {
  var text = String(value || "").trim().toLowerCase()
  if (typeof text.normalize === "function") text = text.normalize("NFD")
  return text
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/[ł]/g, "l")
    .replace(/[ø]/g, "o")
    .replace(/[ð]/g, "d")
    .replace(/[þ]/g, "th")
    .replace(/[æ]/g, "ae")
    .replace(/[œ]/g, "oe")
}

function compactServerName(value) {
  return normalize(value).replace(/[#\-\s]/g, "")
}

function wordPrefixIndex(text, query) {
  var index = text.indexOf(query)
  while (index >= 0) {
    if (index === 0 || /[\s#\-]/.test(text.charAt(index - 1))) return index
    index = text.indexOf(query, index + 1)
  }
  return -1
}

function matchRank(query, values) {
  var needle = normalize(query)
  if (!needle) return -1
  var best = -1
  for (var index = 0; index < values.length; ++index) {
    var candidate = normalize(values[index])
    if (!candidate) continue
    var rank = candidate === needle ? 0
      : candidate.indexOf(needle) === 0 ? 1
      : wordPrefixIndex(candidate, needle) >= 0 ? 2
      : candidate.indexOf(needle) >= 0 ? 3 : -1
    if (rank >= 0 && (best < 0 || rank < best)) best = rank
  }
  return best
}

function canonicalServerLookup(value) {
  var text = String(value || "").trim().toUpperCase()
  if (!text || text.length > 128 || !/^[A-Z0-9#-]+$/.test(text)) return ""
  var digitIndex = text.search(/[0-9]/)
  if (digitIndex < 0) return ""
  var prefix = text.substring(0, digitIndex)
  if ((prefix.match(/[A-Z]/g) || []).length < 2 || !/^[A-Z#-]+$/.test(prefix)) return ""
  if (prefix.indexOf("#") >= 0) return text
  if (prefix.charAt(prefix.length - 1) === "-")
    return text.substring(0, digitIndex - 1) + "#" + text.substring(digitIndex)
  return text.substring(0, digitIndex) + "#" + text.substring(digitIndex)
}
