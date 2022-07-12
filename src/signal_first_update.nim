import esg


type
    Source = ref object of SimpleSubgame
        urn: Urn[int]
        play: int
    Agent = ref object of SimpleSubgame
        urns: array[2, Urn[int]]
        input: int
        received: int
        play: int


proc newSource(): Source =
    Source(
        urn: newUrn([0,1])
    )


proc newAgent(input: int): Agent =
    Agent(
        urns: [newUrn([0,1]), newUrn([0,1])],
        input: input
    )


method reward(s: Source, r: int) =
    if r == 1:
        s.urn.add(s.play)


method reward(s: Agent, r: int) =
    if r == 1:
        s.urns[s.received].add(s.play)


method play(s: Source, input: openArray[int]): int =
    s.play = s.urn.draw()
    s.play


method play(s: Agent, input: openArray[int]): int =
    s.received = input[s.input]
    s.play = s.urns[s.received].draw()
    s.play


proc run(s: OrderedNetwork, source: Source, player1, player2: Agent, n: int): array[5, float] =
    for i in 1 .. n:
        discard s.play()
    [((float)source.urn[0]) / (float)source.urn.total,
     ((float)player1.urns[0][0]) / (float)player1.urns[0].total, ((float)player2.urns[0][0]) / (float)player2.urns[0].total,
     ((float)player1.urns[1][0]) / (float)player1.urns[1].total, ((float)player2.urns[1][0]) / (float)player2.urns[1].total]


proc commitmentGame(n: int): array[5, float] =
    var nodes = newSeq[SimpleSubgame]()
    var source = newSource()
    var player1 = newAgent(0)
    var player2 = newAgent(0)
    nodes.add(source)
    nodes.add(player1)
    nodes.add(player2)

    var game = newOrderedNetwork(
        nodes,
        proc(o: openArray[int]): seq[int] =
            if o[1] != o[2]:
                @[1, 1, 1]
            else:
                @[0, 0, 0]
    )
    game.run(source, player1, player2, n)


when isMainModule:
    import random
    import times
    import json
    import strformat

    let a = epochTime()
    randomize(1)
    writeFile(fmt"signal_first_update.json", $(%runMulticoreSimulations(makeFactory(array[5, float], commitmentGame(10_000)), 1_000)))
    let b = epochTime()
    echo "Wallclock time elapsed: ", b - a