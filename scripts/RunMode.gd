extends RefCounted
## Which kind of run the Game scene should start. Set by the tower doorway before loading Game.

static var training := false
## True for runs started from the tower's preparation screen: spells come from the prepared
## spellbook instead of level-up cards. Scenes loaded directly (tests, bots) keep the old flow.
static var prepared := false
