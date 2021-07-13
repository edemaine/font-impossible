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

letterURL = (letter) ->
  #"font.svg##{letter.id}"
  "##{letter.id}"

drawLetter = (char, container, state) ->
  group = container.group()
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
  element: group
  #x: 0
  #y: 0
  width: width
  height: height

## Origami Simulator
simulator = null
ready = false
onReady = null
checkReady = ->
  if ready
    onReady?()
    onReady = null
window.addEventListener 'message', (e) ->
  if e.data and e.data.from == 'OrigamiSimulator' and e.data.status == 'ready'
    ready = true
    checkReady()
simulate = (svg) ->
  if simulator? and not simulator.closed
    simulator.focus()
  else
    ready = false
    #simulator = window.open 'OrigamiSimulator/?model=', 'simulator'
    simulator = window.open 'https://origamisimulator.org/?model=', 'simulator'
  onReady = -> simulator.postMessage
    op: 'importSVG'
    svg: svg
    vertTol: 0.1
    filename: 'strip-simulate.svg'
  , '*'
  checkReady()

svgPrefixId = (svg, prefix = 'N') ->
  svg.replace /\b(id\s*=\s*")([^"]*")/gi, "$1#{prefix}$2"
  .replace /\b(xlink:href\s*=\s*"#)([^"]*")/gi, "$1#{prefix}$2"

cleanupSVG = (svg) -> svg
simulateSVG = (svg) ->
  explicit = SVG().addTo '#output'
  try
    explicit.svg svgPrefixId svg.svg(), ''
    ## Expand <use> into duplicate copies with translation
    explicit.find 'use'
    .each ->
      replacement = document.getElementById @attr('xlink:href').replace /^#/, ''
      replacement = null if replacement?.id.startsWith 'f' # remove folded
      unless replacement?  # reference to non-existing object
        return @remove()
      replacement = SVG replacement
      viewbox = replacement.attr('viewBox') ? ''
      viewbox = viewbox.split /\s+/
      viewbox = (parseFloat n for n in viewbox)
      replacement = svgPrefixId replacement.svg()
      replacement = replacement.replace /<symbol\b/, '<g'
      replacement = explicit.group().svg replacement
      ## First transform according to `transform`, then translate by `x`, `y`
      replacement.translate \
        (@attr('x') or 0) - (viewbox[0] or 0),
        (@attr('y') or 0) - (viewbox[1] or 0)
      #replacement.translate (@attr('x') or 0), (@attr('y') or 0)
      replacement.attr 'viewBox', null
      replacement.attr 'id', null
      #console.log 'replaced', @attr('xlink:href'), 'with', replacement.svg()
      @replace replacement
    ## Delete now-useless <symbol>s
    explicit.find 'symbol'
    .each ->
      @clear()
    explicit.svg()
    ## Remove surrounding <svg>...</svg> from explicit SVG container
    .replace /^<svg[^<>]*>/, ''
    .replace /<\/svg>$/, ''
  finally
    explicit.remove()

window?.onload = ->
  app = new FontWebappSVG
    root: '#output'
    rootSVG: '#svg'
    margin: 70
    charKern: 25
    lineKern: 50
    spaceWidth: 85
    renderChar: (char, state, group) ->
      unless state.lowercase
        char = char.toUpperCase()
      return unless char of window.font.folded or char of window.font.unfolded
      drawLetter char, group, state

  document.getElementById('links').innerHTML = (
    for char, letter of font.unfolded
      """<a href="#{letter.filename}">#{char}</a>"""
  ).join ', '

  document.getElementById('downloadSVG')?.addEventListener 'click', ->
    app.downloadSVG 'impossible.svg', cleanupSVG app.svg.svg()
  document.getElementById('downloadSim')?.addEventListener 'click', ->
    app.downloadSVG 'impossible-simulate.svg', simulateSVG app.svg
  document.getElementById('simulate')?.addEventListener 'click', ->
    simulate simulateSVG app.svg
