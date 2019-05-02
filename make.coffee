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

root = 'svg'
#subdirs = ['upper', 'lower', 'num']
subdirs = ['upper', 'num']
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
    svg = fs.readFileSync fullFile, encoding: 'utf8'
    .replace /^<\?xml[^]*?\?>\s*/, ''
    .replace /^<!--[^]*?-->\s*/, ''
    .replace /<sodipodi:namedview[^<>]*\/>\s*/g, ''
    .replace /<sodipodi:namedview[^]*?<\/sodipodi:namedview>\s*/g, ''
    .replace /<metadata[^]*?<\/metadata>\s*/g, ''
    .replace /xlink:href/g, 'href'
    #.replace /url\(#/g, 'url(font.svg#'
    .replace /inkscape:(collect|label|groupmode|connector-curvature|transform-center-[xy])="[^"]*"\s*/g, ''
    .replace /sodipodi:nodetypes="[^"]*"\s*/g, ''
    .replace /<defs[^<>]*\/>\s*/g, ''
    .replace /<defs[^<>]*>([^]*?)<\/defs>\s*/g, (match, def) ->
      defs.push def
      ''
    .replace /\bid="[^"]*"\s*/g, ''
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

## Prepend <def>s (with gradients) embedded within SVGs.
defs.unshift '<defs>'
defs.push '</defs>'
out[1...1] = defs

out.push '</svg>\n'
fs.writeFileSync 'font.svg', out.join('\n')
fs.writeFileSync 'font.js', "window.font = #{stringify font};"

console.log "Wrote font.svg and font.js with #{(x for x of font.folded).length} folded and #{(x for x of font.unfolded).length} unfolded symbols"
