margin = 70
charKern = 25
charSpace = 85
lineKern = 50
fontSep = 25

fullCharHeight = 172.35469
## Q extends below baseline
window.font.folded.Q.depth = window.font.folded.Q.height - fullCharHeight
window.font.folded.A.lead = 69.504
window.font.folded.H.lead = 27.171
window.font.folded.N.lead = 27.171
window.font.folded.U.lead = 26.897
window.font.folded.W.lead = 27.171
window.font.folded.Y.lead = 27.568
window.font.folded['4'].lead = 63.500
window.font.folded['6'].lead = 21.167

svg = null

drawLetter = (char, svg, state) ->
  neither = not state.folded and not state.unfolded
  group = svg.group()
  width = height = 0
  letters =
    for subfont in ['unfolded', 'folded'] \
    when (state[subfont] or neither) and char of window.font[subfont]
      window.font[subfont][char]
  for letter, i in letters
    height += fontSep if i > 0
    use = group.use().attr 'href', "font.svg##{letter.id}"
    .y height - (letter.height - fullCharHeight) + (letter.depth ? 0)
    lead = letter.lead ? 0
    letterWidth = letter.width - lead
    if letters.length == 2 and letterWidth < letters[1-i].width - (letters[1-i].lead ? 0)
      use.x (letters[1-i].width - letterWidth)/2 - lead
    else
      use.x -lead
    width = Math.max width, letterWidth
    #height += letter.height - (letter.depth ? 0)
    height += fullCharHeight
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
        letter.group.last().dy dy - letter.height
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
