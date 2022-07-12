import esg


type
    Agent = ref object of SimpleSubgame
        urns: array[2, Urn[int]]
        input: int
        received: int
        play: int


proc newAgent(input: int): Agent =
    Agent(
        urns: [newUrn([0,1]), newUrn([0,1])],
        input: input
    )


method reward(s: Agent, r: int) =
    if r == 1:
        s.urns[s.received].add(s.play)


method play(s: Agent, input: openArray[int]): int =
    s.received = input[s.input]
    s.play = s.urns[s.received].draw()
    s.play


proc run(s: OrderedNetwork, player1, player2: Agent, n: int): array[4, float] =
    for i in 1 .. n:
        discard s.play()
    [((float)player1.urns[0][0]) / (float)player1.urns[0].total, ((float)player2.urns[0][0]) / (float)player2.urns[0].total,
     ((float)player1.urns[1][0]) / (float)player1.urns[1].total, ((float)player2.urns[1][0]) / (float)player2.urns[1].total]


proc commitmentGame(n: int): array[4, float] =
    var nodes = newSeq[SimpleSubgame]()
    nodes.add(newSimpleUniformSource([0,1]))
    var player1 = newAgent(0)
    var player2 = newAgent(0)
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
    game.run(player1, player2, n)


when isMainModule:
    import random
    import times
    import json
    import strformat

    let a = epochTime()
    randomize(1)
    writeFile(fmt"signal_first.json", $(%runMulticoreSimulations(makeFactory(array[4, float], commitmentGame(10_000)), 1_000)))
    let b = epochTime()
    echo "Wallclock time elapsed: ", b - a