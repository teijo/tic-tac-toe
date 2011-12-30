# vim: expandtab sw=2 ts=2 sts=2
GRID_LEN = 100
move = 0

dbg = (data) ->
  if (false)
    console.log(data)
    $('#terminal').prepend(data+'\n')

# return winner marker, true on tie and false if not over
isOver = (g) ->
             #rows
  vectors = [[[0,0],[0,1],[0,2]],
             [[1,0],[1,1],[1,2]],
             [[2,0],[2,1],[2,2]],
             #cols
             [[0,0],[1,0],[2,0]],
             [[0,1],[1,1],[2,1]],
             [[0,2],[1,2],[2,2]],
             #diagonals
             [[0,0],[1,1],[2,2]],
             [[2,0],[1,1],[0,2]]]

  for v in vectors
    a = g[v[0][0]][v[0][1]]
    b = g[v[1][0]][v[1][1]]
    c = g[v[2][0]][v[2][1]]
    if (a == 'x' or a == 'o') and a == b and a == c
      return v

  # full check, tie
  over = true
  for i in [0..2]
    for j in [0..2]
      if (!g[i][j])
        over = false

  over

if !isOver(
  [['x','x','x'],
   [ 0 , 0 , 0 ],
   [ 0 , 0 , 0 ]]
  )
  console.log('fail 1')

if !isOver(
  [[ 0 , 0 , 0 ],
   ['x','x','x'],
   [ 0 , 0 , 0 ]]
  )
  console.log('fail 2')

if !isOver(
  [[ 0 , 0 , 0 ],
   [ 0 , 0 , 0 ],
   ['x','x','x']]
  )
  console.log('fail 3')

if !isOver(
  [['x', 0 , 0 ],
   [ 0 ,'x', 0 ],
   [ 0 , 0 ,'x']]
  )
  console.log('fail 4')

if !isOver(
  [[ 0 , 0 ,'x'],
   [ 0 ,'x', 0 ],
   ['x', 0 , 0 ]]
  )
  console.log('fail 5')

if !isOver(
  [['x', 0 , 0 ],
   ['x', 0 , 0 ],
   ['x', 0 , 0 ]]
  )
  console.log('fail 6')

if !isOver(
  [[ 0 ,'x', 0 ],
   [ 0 ,'x', 0 ],
   [ 0 ,'x', 0 ]]
  )
  console.log('fail 7')

if !isOver(
  [[ 0 , 0 ,'x'],
   [ 0 , 0 ,'x'],
   [ 0 , 0 ,'x']]
  )
  console.log('fail 8')

if !isOver(
  [['x','x','o'],
   ['o','o','x'],
   ['x','o','x']]
  )
  console.log('fail 9')

if isOver(
  [[ 0 ,'x','o'],
   [ 0 ,'o', 0 ],
   [ 0 , 0 , 0 ]]
  )
  console.log('fail 10')

$(() ->
  canvas = $('#board')
  hover = $('#hover')
  ctx = canvas[0].getContext('2d')
  ctxH = hover[0].getContext('2d')

  lines = [[GRID_LEN*1, 20,         GRID_LEN,      GRID_LEN*3-20],
           [GRID_LEN*2, 20,         GRID_LEN*2,    GRID_LEN*3-20],
           [20,         GRID_LEN*1, GRID_LEN*3-20, GRID_LEN],
           [20,         GRID_LEN*2, GRID_LEN*3-20, GRID_LEN*2]]

  ctx.lineWidth = 20
  ctx.strokeStyle = "#000"
  ctx.lineCap = "round"

  ctxH.lineWidth = 20
  ctxH.strokeStyle = "#CCC"
  ctxH.lineCap = "round"

  insert = (ctx, x, y, marker) ->
    if marker != 'o' and marker != 'x'
      return

    ctx.save()
    ctx.translate(x*GRID_LEN+50, y*GRID_LEN+50)
    ctx.beginPath()

    if marker == 'x'
      ctx.moveTo(-30, -30)
      ctx.lineTo( 30,  30)
      ctx.moveTo( 30, -30)
      ctx.lineTo(-30,  30)
    else
      ctx.arc(0, 0, 30, 0, Math.PI*2, true)

    ctx.stroke()
    ctx.restore()

  drawStrike = (v) ->
    offset = (GRID_LEN/2)
    ctx.save()
    ctx.strokeStyle = '#F00'
    ctx.beginPath()
    ctx.moveTo(v[0][0]*GRID_LEN+offset, v[0][1]*GRID_LEN+offset)
    ctx.lineTo(v[2][0]*GRID_LEN+offset, v[2][1]*GRID_LEN+offset)
    ctx.stroke()
    ctx.restore()

  boardClick = (e) ->
    obj =
      x: parseInt(e.offsetX / GRID_LEN)
      y: parseInt(e.offsetY / GRID_LEN)
    ws.send(JSON.stringify(obj))
    canvas.unbind()
    hover.unbind()
    clearHover()

  clearBoard = () ->
    ctx.clearRect(0, 0, canvas.width(), canvas.height())
    drawGrid()

  drawGame = (state, vector) ->
    clearBoard()
    for y in [0..2]
      for x in [0..2]
        insert(ctx, x, y, state[x][y])
    if typeof(vector) == 'object'
      drawStrike(vector)

  drawGrid = () ->
    $.each(lines, (i, l) ->
      ctx.beginPath()
      ctx.moveTo(l[0], l[1])
      ctx.lineTo(l[2], l[3])
      ctx.stroke()
    )

  clearHover = () ->
    ctxH.clearRect(0, 0, hover.width(), hover.height())

  doBinding = (num) ->
    canvas.click(boardClick)

    canvas.mousemove((e) ->
      ctxH.clearRect(0, 0, hover.width(), hover.height())
      # this drawing could be done only when moving to new cell
      insert(ctxH,
             parseInt(e.offsetX/100),
             parseInt(e.offsetY/100),
             if not num then 'o' else 'x')
    )

    canvas.mouseout((e) ->
      clearHover()
    )

  sock = null
  if typeof(WebSocket) == 'undefined'
    sock = MozWebSocket
  else
    sock = WebSocket

  dbg('Connecting ...')
  ws = new sock("ws://localhost:10101")

  ws.onopen = () ->
    dbg('Connected.')

  ws.onmessage = (e) ->
      el = $('h1 span')
      data = JSON.parse(e.data)
      vector = isOver(data.state)
      drawGame(data.state, vector)
      if vector
        el.text("")
        if data.no < 2
          if vector == true
            el.text("Tie. ")
          else
            if !data.move
              el.text("You won! ")
            else
              el.text("You lost. ")

        if data.players > 2 and data.no == 0
          el.append("You'll spectate next.")

        else if data.players == 2 and data.no == 0
          el.append("You're playing. Opponent starts.")

        else if data.no == 1
          el.append("You'll start! Click to clear board.")
          canvas.click(() ->
              clearBoard()
              # player 2 will be player 1 so 'x' -> 'o'
              doBinding((data.no-1))
          )

        else if data.no == 2
          el.text("Game over. You're playing next! Opponent starts.")

        else
          el.text("Game over. Now queued "+(data.no-2)+".")
      else
        el.toggleClass('queued', (data.players < 2 || data.no > 1))
        if data.players < 2
          el.text('Waiting for more players')
        else
          if data.no > 1
            el.text('Spectating, queued '+(data.no-1)+'.')
          else
            el.toggleClass('wait', !data.move)
            if data.move
              el.text('Your move')
              doBinding(data.no)
            else
              el.text("Opponent's move")

  ws.onerror = (e) ->
      dbg(e)

  ws.onclose = (e) ->
    dbg('Disconnected.')
)
