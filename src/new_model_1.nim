# {
#   left balls: 151,
#   right balls: 60
# }

# generate random number R in [1, 211]
# iterate through types of balls

# start with "left" type
# subtract number of left balls from R
# if R < 0: draw "left" ball

# otherwise move on to "right" type
# subtract number of right balls from R
# if R < 0: draw "right" ball












import esg


type
    Sender = ref object of SimpleSubgame
        commitUrn: Urn[int]  # Yes / No balls
        signalUrn: Urn[int]  # L / R balls
        leftUrn: Urn[int]    # go left / go right
        rightUrn: Urn[int]   # go left / go right
        actionUrn: Urn[int]  # go left / go right (if no commitment)
        commitChoice: int    # ball drawn from commitUrn
        signalChoice: int    # ball drawn from signalUrn
        actionChoice: int    # ball drawn from left/right/actionUrn

    Receiver = ref object of SimpleSubgame
        actionUrn: Urn[int]       # draw from this if no signal received
        actionChoice: int
        sender: Sender


proc newSender(): Sender =
    Sender(
        commitUrn: newUrn([0, 1]),  # 0 don't commit, 1 commit
        signalUrn: newUrn([0, 1]),  # 0 left, 1 right
        leftUrn: newUrn([0, 1]),
        rightUrn: newUrn([0, 1]),
        actionUrn: newUrn([0, 1])
    )


proc newReceiver(sender: Sender): Receiver =
    Receiver(
        actionUrn: newUrn([0, 1]),
        sender: sender
    )


method reward(agent: Sender, r: int) =
    # given a sender and a payoff (0/1), how to update the urns
    if r == 1:
        agent.commitUrn.add(agent.commitChoice)
        if agent.commitChoice == 1:  # committed
            agent.signalUrn.add(agent.signalChoice)
            if agent.signalChoice == 0:  # signalled left
                agent.leftUrn.add(agent.actionChoice)
            else:                    # signalled right
                agent.rightUrn.add(agent.actionChoice)
        else:                    # didn't commit
            agent.actionUrn.add(agent.actionChoice)


method reward(agent: Receiver, r: int) =
    if r == 1 and agent.sender.commitChoice == 0:
        agent.actionUrn.add(agent.actionChoice)


method play(agent: Sender, input: openArray[int]): int =
    agent.commitChoice = agent.commitUrn.draw()
    if agent.commitChoice == 0:  # didn't commit
        agent.actionChoice = agent.actionUrn.draw()
    else:
        agent.signalChoice = agent.signalUrn.draw()
        if agent.signalChoice == 0:  # signals "left"
            agent.actionChoice = agent.leftUrn.draw()
        else:
            agent.actionChoice = agent.rightUrn.draw()
    return agent.actionChoice


method play(agent: Receiver, input: openArray[int]): int =
    if agent.sender.commitChoice == 0:
        agent.actionChoice = agent.actionUrn.draw()
    else:
        agent.actionChoice = agent.sender.signalChoice
    return agent.actionChoice


proc runGame(game: OrderedNetwork, numberOfPlays: int): float =
    result = 0
    for i in 1 .. numberOfPlays:
        result += (float)game.play()[0]
    result = result / (float)numberOfPlays


proc calculateSuccessProb(sender: Sender, receiver: Receiver): array[2, float] =
    # returns P(success | commit), P(success | ~commit)
    var bothLeft = (((float)sender.actionUrn[0]) / (float)sender.actionUrn.total) *
                   (((float)receiver.actionUrn[0]) / (float)receiver.actionUrn.total)
    var bothRight = (((float)sender.actionUrn[1]) / (float)sender.actionUrn.total) *
                   (((float)receiver.actionUrn[1]) / (float)receiver.actionUrn.total)
    var successGivenNotCommit = bothLeft + bothRight

    var followThroughGivenLeft = ((float)sender.leftUrn[0]) / (float)sender.leftUrn.total
    var followThroughGivenRight = ((float)sender.rightUrn[1]) / (float)sender.rightUrn.total
    var commitLeft = ((float)sender.signalUrn[0]) / (float)sender.signalUrn.total
    var successGivenCommit = (followThroughGivenLeft * commitLeft) + (followThroughGivenRight * (1 - commitLeft))

    return [successGivenCommit, successGivenNotCommit]


proc commitmentGame(numberOfPlays: int): array[4, float] =
    var sender = newSender()
    var receiver = newReceiver(sender)
    var game = newOrderedNetwork(
        @[
            sender,
            receiver
        ],
        proc (actions: openArray[int]): seq[int] =
            # given a list of agent actions, test if they've coordinated and assign payoff
            if actions[0] == actions[1]:
                return @[1, 1]
            else:
                return @[0, 0]
    )

    var empiricalSuccessRate = runGame(game, numberOfPlays)
    var commitProb = ((float)sender.commitUrn[1]) / (float)sender.commitUrn.total
    var successProbs = calculateSuccessProb(sender, receiver)
    return [empiricalSuccessRate, commitProb, successProbs[0], successProbs[1]]


when isMainModule:
    import random
    import times
    import json
    import strformat

    let a = epochTime()
    randomize(1)
    writeFile(fmt"new_model_1.json", $(%runMulticoreSimulations(makeFactory(array[4, float], commitmentGame(10_000)), 1_000)))
    let b = epochTime()
    echo "Wallclock time elapsed: ", b - a





# game = [
#     sender,
#     receiver
# ]

# game.play() -> sender.play(), receiver.play()







# sender = newSender()