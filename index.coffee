margin = 70
charKern = 25
charSpace = 85
lineKern = 50
fontSep = 25

fullCharHeight = 172.35469
## Q extends below baseline
window.font.folded.Q.depth = window.font.folded.Q.height - fullCharHeight
window.font.folded.g.depth = 42.333
window.font.folded.j.depth = 42.333  # compromise
window.font.folded.q.depth = 42.333
#window.font.folded.y.depth = 63.5   # actual depth
window.font.folded.y.depth = 42.333  # compromise to avoid overlap
window.font.folded.A.lead = 69.504
window.font.folded.H.lead = 27.171
window.font.folded.N.lead = 27.171
window.font.folded.U.lead = 26.897
window.font.folded.W.lead = 27.171
window.font.folded.Y.lead = 27.568
window.font.folded['4'].lead = 63.500
window.font.folded['6'].lead = 21.167
window.font.folded.d.lead = 27.146
window.font.folded.g.lead = 37.764
window.font.folded.h.lead = 21.167
window.font.folded.k.lead = 21.167
window.font.folded.m.lead = 21.167
window.font.folded.n.lead = 10.583
window.font.folded.p.lead = 63.5
window.font.folded.q.lead = 21.167
window.font.folded.u.lead = 31.75
window.font.folded.w.lead = 63.5
window.font.folded.y.lead = 63.5
window.font.folded.z.lead = 21.167

svg = null

letterURL = (letter) ->
  #"font.svg##{letter.id}"
  "##{letter.id}"

drawLetter = (char, svg, state) ->
  group = svg.group()
  width = height = 0
  letters =
    for subfont in ['unfolded', 'folded'] \
    when state.font in [subfont, 'both'] and char of window.font[subfont]
      window.font[subfont][char]
  for letter, i in letters
    height += fontSep if i > 0
    use = group.use().attr 'href', letterURL letter
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

updateText = (changed) ->
  state = @getState()
  svg.clear()
  y = 0
  xmax = 0
  for line in state.text.split '\n'
    x = 0
    dy = 0
    row = []
    for char, c in line
      unless state.lowercase
        char = char.toUpperCase()
      if char of window.font.folded or char of window.font.unfolded
        x += charKern unless c == 0
        letter = drawLetter char, svg, state
        letter.group.translate x - letter.x, y - letter.y
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
  svg = SVG().addTo '#output'
  furls = new Furls()
  .addInputs()
  .on 'stateChange', updateText
  .syncState()

  document.getElementById('links').innerHTML = (
    for char, letter of font.unfolded
      """<a href="#{letter.filename}">#{char}</a>"""
  ).join ', '

  window.addEventListener 'resize', resize
  resize()

  ## Inline symbols and gradients from font.svg into output <svg>
  fetch 'font.svg'
  .then (response) -> response.text()
  .then (fontSVG) ->
    svg.node.innerHTML = fontSVG + svg.node.innerHTML
