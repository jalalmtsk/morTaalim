const WebSocket = require('ws');

const wss = new WebSocket.Server({ port: 8080 });

let games = {}; // { gameId: { players: [ws], state: {...} } }

wss.on('connection', (ws) => {
  console.log('Player connected');

  ws.on('message', (msg) => {
    try {
      const data = JSON.parse(msg);

      // --- Join a game ---
      if (data.type === 'join_game') {
        const { gameId, player } = data;
        if (!games[gameId]) games[gameId] = { players: [], state: {} };
        ws.gameId = gameId;
        ws.player = player;
        games[gameId].players.push(ws);

        // Notify others
        games[gameId].players.forEach(p => {
          if (p !== ws) p.send(JSON.stringify({ type: 'player_joined', player }));
        });
      }

      // --- Game actions ---
      if (data.type === 'play_card' || data.type === 'draw_card' || data.type === 'end_turn') {
        const { gameId } = ws;
        if (!games[gameId]) return;
        // Broadcast to all players in the game
        games[gameId].players.forEach(p => {
          p.send(JSON.stringify(data));
        });
      }
    } catch (e) {
      console.error('Invalid message', e);
    }
  });

  ws.on('close', () => {
    const { gameId } = ws;
    if (gameId && games[gameId]) {
      games[gameId].players = games[gameId].players.filter(p => p !== ws);
    }
    console.log('Player disconnected');
  });
});

console.log('WebSocket server running on ws://localhost:8080');
