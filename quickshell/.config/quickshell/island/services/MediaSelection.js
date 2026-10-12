.pragma library

function selectPlayer(players, current, playingState) {
    if (players.includes(current) && current.playbackState === playingState) return current;
    return players.find(player => player.playbackState === playingState)
        ?? (players.includes(current) ? current : players[0])
        ?? null;
}
