(function() {
  var GRID_LEN, dbg, isOver, move;

  GRID_LEN = 100;

  move = 0;

  dbg = function(data) {
    if (false) {
      console.log(data);
      return $('#terminal').prepend(data + '\n');
    }
  };

  isOver = function(g) {
    var a, b, c, i, j, over, v, vectors, _i, _len;
    vectors = [[[0, 0], [0, 1], [0, 2]], [[1, 0], [1, 1], [1, 2]], [[2, 0], [2, 1], [2, 2]], [[0, 0], [1, 0], [2, 0]], [[0, 1], [1, 1], [2, 1]], [[0, 2], [1, 2], [2, 2]], [[0, 0], [1, 1], [2, 2]], [[2, 0], [1, 1], [0, 2]]];
    for (_i = 0, _len = vectors.length; _i < _len; _i++) {
      v = vectors[_i];
      a = g[v[0][0]][v[0][1]];
      b = g[v[1][0]][v[1][1]];
      c = g[v[2][0]][v[2][1]];
      if ((a === 'x' || a === 'o') && a === b && a === c) return v;
    }
    over = true;
    for (i = 0; i <= 2; i++) {
      for (j = 0; j <= 2; j++) {
        if (!g[i][j]) over = false;
      }
    }
    return over;
  };

  if (!isOver([['x', 'x', 'x'], [0, 0, 0], [0, 0, 0]])) console.log('fail 1');

  if (!isOver([[0, 0, 0], ['x', 'x', 'x'], [0, 0, 0]])) console.log('fail 2');

  if (!isOver([[0, 0, 0], [0, 0, 0], ['x', 'x', 'x']])) console.log('fail 3');

  if (!isOver([['x', 0, 0], [0, 'x', 0], [0, 0, 'x']])) console.log('fail 4');

  if (!isOver([[0, 0, 'x'], [0, 'x', 0], ['x', 0, 0]])) console.log('fail 5');

  if (!isOver([['x', 0, 0], ['x', 0, 0], ['x', 0, 0]])) console.log('fail 6');

  if (!isOver([[0, 'x', 0], [0, 'x', 0], [0, 'x', 0]])) console.log('fail 7');

  if (!isOver([[0, 0, 'x'], [0, 0, 'x'], [0, 0, 'x']])) console.log('fail 8');

  if (!isOver([['x', 'x', 'o'], ['o', 'o', 'x'], ['x', 'o', 'x']])) {
    console.log('fail 9');
  }

  if (isOver([[0, 'x', 'o'], [0, 'o', 0], [0, 0, 0]])) console.log('fail 10');

  $(function() {
    var boardClick, canvas, clearBoard, clearHover, ctx, ctxH, doBinding, drawGame, drawGrid, drawStrike, hover, insert, lines, sock, ws;
    canvas = $('#board');
    hover = $('#hover');
    ctx = canvas[0].getContext('2d');
    ctxH = hover[0].getContext('2d');
    lines = [[GRID_LEN * 1, 20, GRID_LEN, GRID_LEN * 3 - 20], [GRID_LEN * 2, 20, GRID_LEN * 2, GRID_LEN * 3 - 20], [20, GRID_LEN * 1, GRID_LEN * 3 - 20, GRID_LEN], [20, GRID_LEN * 2, GRID_LEN * 3 - 20, GRID_LEN * 2]];
    ctx.lineWidth = 20;
    ctx.strokeStyle = "#000";
    ctx.lineCap = "round";
    ctxH.lineWidth = 20;
    ctxH.strokeStyle = "#CCC";
    ctxH.lineCap = "round";
    insert = function(ctx, x, y, marker) {
      if (marker !== 'o' && marker !== 'x') return;
      ctx.save();
      ctx.translate(x * GRID_LEN + 50, y * GRID_LEN + 50);
      ctx.beginPath();
      if (marker === 'x') {
        ctx.moveTo(-30, -30);
        ctx.lineTo(30, 30);
        ctx.moveTo(30, -30);
        ctx.lineTo(-30, 30);
      } else {
        ctx.arc(0, 0, 30, 0, Math.PI * 2, true);
      }
      ctx.stroke();
      return ctx.restore();
    };
    drawStrike = function(v) {
      var offset;
      offset = GRID_LEN / 2;
      ctx.save();
      ctx.strokeStyle = '#F00';
      ctx.beginPath();
      ctx.moveTo(v[0][0] * GRID_LEN + offset, v[0][1] * GRID_LEN + offset);
      ctx.lineTo(v[2][0] * GRID_LEN + offset, v[2][1] * GRID_LEN + offset);
      ctx.stroke();
      return ctx.restore();
    };
    boardClick = function(e) {
      var obj;
      obj = {
        x: parseInt(e.offsetX / GRID_LEN),
        y: parseInt(e.offsetY / GRID_LEN)
      };
      ws.send(JSON.stringify(obj));
      canvas.unbind();
      hover.unbind();
      return clearHover();
    };
    clearBoard = function() {
      ctx.clearRect(0, 0, canvas.width(), canvas.height());
      return drawGrid();
    };
    drawGame = function(state, vector) {
      var x, y;
      clearBoard();
      for (y = 0; y <= 2; y++) {
        for (x = 0; x <= 2; x++) {
          insert(ctx, x, y, state[x][y]);
        }
      }
      if (typeof vector === 'object') return drawStrike(vector);
    };
    drawGrid = function() {
      var l, _i, _len, _results;
      _results = [];
      for (_i = 0, _len = lines.length; _i < _len; _i++) {
        l = lines[_i];
        ctx.beginPath();
        ctx.moveTo(l[0], l[1]);
        ctx.lineTo(l[2], l[3]);
        _results.push(ctx.stroke());
      }
      return _results;
    };
    clearHover = function() {
      return ctxH.clearRect(0, 0, hover.width(), hover.height());
    };
    doBinding = function(num) {
      canvas.click(boardClick);
      canvas.mousemove(function(e) {
        ctxH.clearRect(0, 0, hover.width(), hover.height());
        return insert(ctxH, parseInt(e.offsetX / 100), parseInt(e.offsetY / 100), !num ? 'o' : 'x');
      });
      return canvas.mouseout(function(e) {
        return clearHover();
      });
    };
    sock = null;
    if (typeof WebSocket === 'undefined') {
      sock = MozWebSocket;
    } else {
      sock = WebSocket;
    }
    dbg('Connecting ...');
    ws = new sock("ws://localhost:10101");
    ws.onopen = function() {
      return dbg('Connected.');
    };
    ws.onmessage = function(e) {
      var data, el, vector;
      el = $('h1 span');
      data = JSON.parse(e.data);
      vector = isOver(data.state);
      drawGame(data.state, vector);
      if (vector) {
        el.text("");
        if (data.no < 2) {
          if (vector === true) {
            el.text("Tie. ");
          } else {
            if (!data.move) {
              el.text("You won! ");
            } else {
              el.text("You lost. ");
            }
          }
        }
        if (data.players > 2 && data.no === 0) {
          return el.append("You'll spectate next.");
        } else if (data.players === 2 && data.no === 0) {
          return el.append("You're playing. Opponent starts.");
        } else if (data.no === 1) {
          el.append("You'll start! Click to clear board.");
          return canvas.click(function() {
            clearBoard();
            return doBinding(data.no - 1);
          });
        } else if (data.no === 2) {
          return el.text("Game over. You're playing next! Opponent starts.");
        } else {
          return el.text("Game over. Now queued " + (data.no - 2) + ".");
        }
      } else {
        el.toggleClass('queued', data.players < 2 || data.no > 1);
        if (data.players < 2) {
          return el.text('Waiting for more players');
        } else {
          if (data.no > 1) {
            return el.text('Spectating, queued ' + (data.no - 1) + '.');
          } else {
            el.toggleClass('wait', !data.move);
            if (data.move) {
              el.text('Your move');
              return doBinding(data.no);
            } else {
              return el.text("Opponent's move");
            }
          }
        }
      }
    };
    ws.onerror = function(e) {
      return dbg(e);
    };
    return ws.onclose = function(e) {
      return dbg('Disconnected.');
    };
  });

}).call(this);
