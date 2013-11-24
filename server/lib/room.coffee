async = require 'async'
_ = require 'underscore'

Player = require './player'

class Room
  constructor: (@name) ->

    @player1 = null
    @player2 = null

    @spectators = {}
    @activePlayer = null

    @allCards = {}

    @active = null
    @target = null

  addPlayer: (player) =>

    if @name is 'Lobby' or (@player1? and @player2?)
      @spectators[player.id] = player
    else if not @player1? then @player1 = player
    else @player2 = player

  removePlayer: (player) =>
    if @player1 is player
      @player1 = null
    else if @player2 is player
      @player2 = null
    else
      delete @spectators[player.id]

  startNewGame: () =>
    return unless (@player1 and @player2)

    # Determine who ISNT active player (this number is flipped in changeTurns)
    if (Math.floor(Math.random()*2))
      @activePlayer = @player1.id
    else @activePlayer = @player2.id

    io.sockets.in(@name).emit "GameStart",
      activePlayer: @activePlayer
      player1:
        id: @player1.id
        deck: _.map @player1.deck, (card) => {id: card.id, x: card.x, y: card.y}
      player2:
        id: @player2.id
        deck: _.map @player2.deck, (card) => {id: card.id, x: card.x, y: card.y}

    for i in [1..5] by 1
      @player1.draw (message) => io.sockets.in(@name).emit("CardDraw", message)
      @player2.draw (message) => io.sockets.in(@name).emit("CardDraw", message)

    @changeTurns()

  getCard: (id) =>
    @allCards[id]

  changeTurns: () =>
    @active = null
    @target = null

    player = @player1
    if @activePlayer is @player1.id
      @activePlayer = @player2.id
      player = @player2
    else
      @activePlayer = @player1.id
      player = @player1

    player.hasUsedResource = false

    io.sockets.in(@name).emit "TurnStart",
      activePlayer: @activePlayer

module.exports = Room