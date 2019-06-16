#!/usr/bin/coffee
fs = require 'fs'
path = require 'path'
stringify = require 'json-stringify-pretty-compact'
#stringify = JSON.stringify

font = {folded: {}, unfolded: {}}

out = ['''
  <?xml version="1.0" encoding="UTF-8" standalone="no"?>
  <svg xmlns:svg="http://www.w3.org/2000/svg" xmlns="http://www.w3.org/2000/svg" version="1.1">

''']
defs = []
gradientDark = {}
nextId = 0

root = 'svg'
subdirs = ['upper', 'lower', 'num']
for subdir in subdirs
  dir = path.join root, subdir
  files = fs.readdirSync dir
  for file in files when not file.startsWith '.'
    match = /^(ink_)?(.).svg$/.exec file
    unless match?
      console.error "'#{file}' failed to parse"
      continue
    folded = if match[1]? then 'folded' else 'unfolded'
    letter = match[2]
    fullFile = path.join dir, file
    #console.log folded, letter, fullFile

    width = height = null
    id = "#{folded[0]}#{subdir[0]}#{letter}"
    idMap = {}
    svg = fs.readFileSync fullFile, encoding: 'utf8'
    .replace /^<\?xml[^]*?\?>\s*/, ''
    .replace /^<!--[^]*?-->\s*/, ''
    .replace /<sodipodi:namedview[^<>]*\/>\s*/g, ''
    .replace /<sodipodi:namedview[^]*?<\/sodipodi:namedview>\s*/g, ''
    .replace /<metadata[^]*?<\/metadata>\s*/g, ''
    .replace /xlink:href/g, 'href'
    .replace /\bid="([^"]*)"\s*/g, (match, id) ->
      if id.startsWith 'linearGradient'
        match
      else
        ''
    .replace /inkscape:(collect|label|groupmode|connector-curvature|transform-center-[xy])="[^"]*"\s*/g, ''
    .replace /sodipodi:nodetypes="[^"]*"\s*/g, ''
    .replace /\s*>/g, '>'
    .replace /<defs[^<>]*\/>\s*/g, ''
    .replace /<defs[^<>]*>([^]*?)<\/defs>\s*/g, (match, def) ->
      def = def.replace /\bid="([^"]*)"/g, (match2, oldId) ->
        idMap[oldId] = "d#{nextId}"
        "id=\"d#{nextId++}\""
      .replace (new RegExp "href=\"#(#{(key for key of idMap).join '|'})\"", 'g'),
        (match, oldId) -> "href=\"##{idMap[oldId]}\""
      defs.push def
      ## Compute darkest color of each gradient
      gradientRe = /<linearGradient[^<>]*id="([^"]*)"[^<>/]*>([^]*?)<\/linearGradient>/g
      while gradient = gradientRe.exec def
        gradientId = gradient[1]
        stopRe = /stop-color\s*:\s*(#[a-fA-F0-9]+)/g
        while stop = stopRe.exec gradient
          unless gradientDark[gradientId]? and gradientDark[gradientId] < stop[1]
            gradientDark[gradientId] = stop[1]
      gradientRe = /<linearGradient[^<>]*id="([^"]*)"[^<>/]*\/>/g
      while gradient = gradientRe.exec def
        gradientId = gradient[1]
        href = /href\s*=\s*"#([^"]*)"/.exec gradient[0]
        gradientDark[gradientId] = gradientDark[href[1]]
      ''
    .replace (new RegExp "url\\(#(#{(key for key of idMap).join '|'})\\)", 'g'),
      (match, oldId) -> "url(##{idMap[oldId]})" +
        ## Use darkest color of gradient as fallback color (for Chrome with bug
        ## https://bugs.chromium.org/p/chromium/issues/detail?id=572685)
        if gradientDark[idMap[oldId]]? then " #{gradientDark[idMap[oldId]]}" else ""
    .replace /<svg[^<>]*>/, (match) ->
      width = /width="([^"]*?)mm"/.exec match
      height = /height="([^"]*?)mm"/.exec match
      viewbox = /viewBox="([^"]*)"/.exec match
      unless width? and height? and viewbox?
        console.error "Missing stuff in #{match}"
      coords = /^([.\d]+)\s+([.\d]+)\s+([.\d]+)\s+([.\d]+)$/.exec viewbox[1]
      unless coords?
        console.error "Unparsable viewbox #{coords} in #{fullFile}"
      unless coords[1] == coords[2] == "0"
        console.error "Weird viewbox #{coords} in #{fullFile}"
      unless width? and height? and viewbox?
        console.error "Missing stuff in #{match}"
      unless width[1] == coords[3] and height[1] == coords[4]
        console.error "Invalid width/height #{width[1]}/#{height[1]} vs. viewbox #{coords[3]}/#{coords[4]} in #{match}"
      width = width[1]
      height = height[1]
      """<symbol id="#{id}" width="#{width}" height="#{height}">"""
    .replace /<\/svg>/, '</symbol>'
    out.push svg

    font[folded][letter] =
      width: parseFloat width
      height: parseFloat height
      id: id
      filename: fullFile

## Prepend <def>s (with gradients) embedded within SVGs.
defs.unshift '<defs>'
defs.push '</defs>'
out[1...1] = defs

out.push '</svg>\n'
fs.writeFileSync 'font.svg', out.join('\n')
fs.writeFileSync 'font.js', "window.font = #{stringify font};"

console.log "Wrote font.svg and font.js with #{(x for x of font.folded).length} folded and #{(x for x of font.unfolded).length} unfolded symbols"
