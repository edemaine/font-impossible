margin = 10
charKern = 25
charSpace = 65
lineKern = 30
fontSep = 20

svg = null

drawLetter = (char, svg, state) ->
  neither = not state.folded and not state.unfolded
  group = svg.group()
  width = height = 0
  letters =
    for subfont in ['folded', 'unfolded'] \
    when (state[subfont] or neither) and char of window.font[subfont]
      window.font[subfont][char]
  for letter, i in letters
    use = group.use().attr 'href', "font.svg##{letter.id}"
    .y height += fontSep
    if letters.length == 2 and letter.width < letters[1-i].width
      use.x (letters[1-i].width - letter.width)/2
    width = Math.max width, letter.width
    height += letter.height
  group: group
  x: 0
  y: 0
  width: width
  height: height

stop = ->

updateText = (changed) ->
  state = @getState()
  if changed.text or changed.unfolded or changed.folded
    svg.clear()
    y = 0
    xmax = 0
    for line in state.text.split '\n'
      x = 0
      dy = 0
      row = []
      for char, c in line
        char = char.toUpperCase()
        if char of window.font.folded or char of window.font.unfolded
          x += charKern unless c == 0
          letter = drawLetter char, svg, state
          letter.group.move x - letter.x, y - letter.y
          row.push letter
          x += letter.width
          xmax = Math.max xmax, x
          dy = Math.max dy, letter.height
        else if char == ' '
          x += charSpace
      ## Bottom alignment
      for letter in row
        letter.group.dy dy - letter.height
      y += dy + lineKern
    svg.viewbox
      x: -margin
      y: -margin
      width: xmax + 2*margin
      height: y + 2*margin

## Based on meouw's answer on http://stackoverflow.com/questions/442404/retrieve-the-position-x-y-of-an-html-element
getOffset = (el) ->
  x = y = 0
  while el and not isNaN(el.offsetLeft) and not isNaN(el.offsetTop)
    x += el.offsetLeft - el.scrollLeft
    y += el.offsetTop - el.scrollTop
    el = el.offsetParent
  x: x
  y: y

resize = ->
  offset = getOffset document.getElementById('output')
  height = Math.max 100, window.innerHeight - offset.y
  document.getElementById('output').style.height = "#{height}px"

checkAlone = ['unfolded', 'folded']

furls = null
window?.onload = ->
  svg = SVG 'output'
  furls = new Furls()
  .addInputs()
  .on 'stateChange', updateText
  .syncState()

  for checkbox in checkAlone
    do (checkbox) ->
      document.getElementById(checkbox+'-alone').addEventListener 'click', ->
        for other in checkAlone when other != checkbox
          furls.set other, false
        furls.set checkbox, true
        #updateTextSoon()

  window.addEventListener 'resize', resize
  resize()
