margin = 10
charKern = 25
charSpace = 65
lineKern = 45

svg = null

drawLetter = (char, svg, state) ->
  group = svg.use().attr 'href', "font.svg##{char.id}"
  #y = 100 - char.height
  group: group
  x: 0
  y: 0#-y
  width: char.width
  height: char.height

stop = ->
letters = null

updateText = (changed) ->
  state = @getState()
  if changed.text
    letters = []
    svg.clear()
    y = 0
    xmax = 0
    for line in state.text.split '\n'
      x = 0
      dy = 0
      for char, c in line
        char = char.toUpperCase()
        if char of font.folded
          x += charKern unless c == 0
          letter = drawLetter font.folded[char], svg, state
          letter.group.translate x - letter.x, y - letter.y
          letters.push letter
          x += letter.width
          xmax = Math.max xmax, x
          dy = Math.max dy, letter.height
        else if char == ' '
          x += charSpace
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

furls = null
window?.onload = ->
  svg = SVG 'output'
  furls = new Furls()
  .addInputs()
  .on 'stateChange', updateText
  .syncState()

  window.addEventListener 'resize', resize
  resize()
