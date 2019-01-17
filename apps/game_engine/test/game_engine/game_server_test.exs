defmodule GameEngine.GameServerTest do
  use ExUnit.Case
  doctest GameEngine.GameServer

  alias GameEngine.{Board, Game, GameServer}

  @game_name "my-game"

  describe "join_player/2" do
    test "joins the first player as :x" do
      {:ok, _game_pid} = GameServer.start_link(@game_name)

      player = "Felipe"

      expected =
        {:ok, :x,
         %GameEngine.Game{
           board: %GameEngine.Board{
             positions: [nil, nil, nil, nil, nil, nil, nil, nil, nil]
           },
           finished: false,
           first: :x,
           next: :x,
           o: nil,
           winner: nil,
           x: "Felipe"
         }}

      assert GameServer.join_player(@game_name, player) == expected
    end

    test "joins the second player as :o" do
      {:ok, _game_pid} = GameServer.start_link(@game_name)

      player_x = "Felipe"
      player_o = "Renan"

      GameServer.join_player(@game_name, player_x)

      expected =
        {:ok, :o,
         %GameEngine.Game{
           board: %GameEngine.Board{
             positions: [nil, nil, nil, nil, nil, nil, nil, nil, nil]
           },
           finished: false,
           first: :x,
           next: :x,
           o: "Renan",
           winner: nil,
           x: "Felipe"
         }}

      assert GameServer.join_player(@game_name, player_o) == expected
    end

    test "returns an error when already there are two players" do
      {:ok, _game_pid} = GameServer.start_link(@game_name)

      player_x = "Felipe"
      player_o = "Renan"

      GameServer.join_player(@game_name, player_x)
      GameServer.join_player(@game_name, player_o)

      expected = {:error, "This game already has two players"}

      assert GameServer.join_player(@game_name, "Gomes") == expected
    end
  end

  describe "put_player_symbol/3" do
    test "returns the finished game when it's finished" do
      {:ok, _game_pid} = GameServer.start_link(@game_name, %Game{finished: true})
      {:ok, player_x, _game} = GameServer.join_player(@game_name, "Felipe")
      {:ok, _player_o, _game} = GameServer.join_player(@game_name, "Renan")

      position = 0
      expected = {:error, "this game is already finished"}

      assert GameServer.put_player_symbol(@game_name, player_x, position) == expected
    end

    test "put the player symbol when it is his/her turn" do
      {:ok, _game_pid} = GameServer.start_link(@game_name)
      {:ok, player_x, _game} = GameServer.join_player(@game_name, "Felipe")
      {:ok, _player_o, _game} = GameServer.join_player(@game_name, "Renan")

      position = 0

      expected =
        {:ok,
         %GameEngine.Game{
           board: %GameEngine.Board{
             positions: [:x, nil, nil, nil, nil, nil, nil, nil, nil]
           },
           finished: false,
           first: :x,
           next: :o,
           o: "Renan",
           winner: nil,
           x: "Felipe"
         }}

      assert GameServer.put_player_symbol(@game_name, player_x, position) == expected
    end

    test "returns an error when it's not the player turn" do
      {:ok, _game_pid} = GameServer.start_link(@game_name)
      {:ok, _player_x, _game} = GameServer.join_player(@game_name, "Felipe")
      {:ok, player_o, _game} = GameServer.join_player(@game_name, "Renan")

      position = 0

      expected = {:error, "It's not :o turn. Now it's :x turn"}

      assert GameServer.put_player_symbol(@game_name, player_o, position) == expected
    end

    test "finish the game and define the winner when there is an winner" do
      board = %Board{positions: [:x, :x, nil, nil, nil, nil, nil, nil, nil]}
      {:ok, _game_pid} = GameServer.start_link(@game_name, %Game{board: board})
      {:ok, player_x, _game} = GameServer.join_player(@game_name, "Felipe")
      {:ok, _player_o, _game} = GameServer.join_player(@game_name, "Renan")

      position = 2

      expected =
        {:winner,
         %GameEngine.Game{
           board: %GameEngine.Board{
             positions: [:x, :x, :x, nil, nil, nil, nil, nil, nil]
           },
           finished: true,
           first: :x,
           next: :x,
           o: "Renan",
           winner: :x,
           x: "Felipe"
         }}

      assert GameServer.put_player_symbol(@game_name, player_x, position) == expected
    end

    test "finish the game when the board is fulfilled" do
      board = %Board{positions: [:x, :o, :x, :x, :o, :x, :o, :x, nil]}
      {:ok, _game_pid} = GameServer.start_link(@game_name, %Game{board: board, next: :o})
      {:ok, _player_x, _game} = GameServer.join_player(@game_name, "Felipe")
      {:ok, player_o, _game} = GameServer.join_player(@game_name, "Renan")

      position = 8

      expected =
        {:draw,
         %GameEngine.Game{
           board: %GameEngine.Board{
             positions: [:x, :o, :x, :x, :o, :x, :o, :x, :o]
           },
           finished: true,
           first: :x,
           next: :o,
           o: "Renan",
           winner: :draw,
           x: "Felipe"
         }}

      assert GameServer.put_player_symbol(@game_name, player_o, position) == expected
    end
  end

  describe "new_round/1" do
    test "reset the board and change which player is the first" do
      board = %Board{positions: [:x, :o, :x, :x, :o, :x, :o, :x, nil]}

      {:ok, _game_pid} =
        GameServer.start_link(@game_name, %Game{board: board, finished: true, first: :x})

      {:ok, _player_x, _game} = GameServer.join_player(@game_name, "Felipe")
      {:ok, _player_o, _game} = GameServer.join_player(@game_name, "Renan")

      expected =
        {:ok,
         %GameEngine.Game{
           board: %GameEngine.Board{
             positions: [nil, nil, nil, nil, nil, nil, nil, nil, nil]
           },
           finished: false,
           first: :o,
           next: :o,
           o: "Renan",
           winner: nil,
           x: "Felipe"
         }}

      assert GameServer.new_round(@game_name) == expected
    end
  end

  describe "leave/2" do
    test "remove the player from the game server" do
      {:ok, _game_pid} = GameServer.start_link(@game_name)

      {:ok, player_x, _game} = GameServer.join_player(@game_name, "Felipe")
      {:ok, _player_o, _game} = GameServer.join_player(@game_name, "Renan")

      expected =
        {:ok,
         %GameEngine.Game{
           board: %GameEngine.Board{
             positions: [nil, nil, nil, nil, nil, nil, nil, nil, nil]
           },
           finished: false,
           first: :x,
           next: :x,
           o: "Renan",
           winner: nil,
           x: nil
         }}

      assert GameServer.leave(@game_name, player_x) == expected
    end
  end
end
