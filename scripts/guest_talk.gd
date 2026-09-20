extends RefCounted
class_name GuestTalk

## Spoken lines for park guests. Pick is stable per guest so the inspect
## card does not flicker while they stay on the same beat.


static func line(voice: String, beat: String, hook: String, seed: int) -> String:
	var pool: PackedStringArray = _pool(voice, beat)
	if pool.is_empty():
		pool = _pool("_", beat)
	if pool.is_empty():
		return "Hmm."
	var i: int = absi(seed + beat.hash() + voice.hash()) % pool.size()
	var text: String = pool[i]
	if text.contains("%s"):
		var word: String = hook if not hook.is_empty() else "one"
		return text % word
	return text


static func blurt(kind: String, seed: int) -> String:
	var pool: PackedStringArray = _event(kind)
	if pool.is_empty():
		return ""
	return pool[absi(seed + kind.hash()) % pool.size()]


static func _pool(voice: String, beat: String) -> PackedStringArray:
	match beat:
		"leaving":
			match voice:
				"family":
					return PackedStringArray([
						"That's us for today. The kids are ready.",
						"The kids have seen enough.",
						"We'll head back with the kids.",
					])
				"children":
					return PackedStringArray([
						"I want to go home.",
						"Can we leave? Please?",
						"I don't like it here anymore.",
					])
				"parents":
					return PackedStringArray([
						"That's us for today.",
						"Time we headed back.",
						"We'll catch this ride.",
					])
				"tourists":
					return PackedStringArray([
						"Cab's here. I'm done.",
						"Not the postcard I wanted. Going.",
					])
				"goths":
					return PackedStringArray([
						"Whatever. I'm out.",
						"Fine. This scene's dead anyway.",
					])
				"creators":
					return PackedStringArray([
						"That's a wrap chat. Heading out.",
						"Going live from the car. Bye.",
					])
				_:
					return PackedStringArray([
						"Calling a car.",
						"I'm heading out.",
						"That's my ride.",
					])
		"empty":
			match voice:
				"family":
					return PackedStringArray([
						"The kids keep asking where the animals are.",
						"We paid to look at empty grass. The kids noticed.",
						"Kids, there's nothing in the pens yet.",
					])
				"children":
					return PackedStringArray([
						"Where are the animals?",
						"There's nothing to look at.",
						"I wanted to see a creature.",
					])
				"tourists":
					return PackedStringArray([
						"I came all this way for empty paddocks?",
						"Not even a statue to photograph.",
						"This brochure lied.",
					])
				"goths":
					return PackedStringArray([
						"Empty cages. Almost atmospheric.",
						"A grim little nothing. I respect it.",
						"No beasts. Just the void. Fine.",
					])
				"creators":
					return PackedStringArray([
						"Nothing to film yet.",
						"Can't post an empty field.",
					])
				"thrill":
					return PackedStringArray([
						"Wake me when something's in a pen.",
						"No teeth, no point.",
					])
				"scientists":
					return PackedStringArray([
						"No specimens. Disappointing.",
						"The dataset is empty.",
					])
				"parents":
					return PackedStringArray([
						"Not much here for the kids yet.",
						"I promised them animals.",
					])
				_:
					return PackedStringArray(["There's nothing in the pens."])
		"arrive":
			match voice:
				"family":
					return PackedStringArray([
						"The kids want to see everything.",
						"Alright kids, stay close.",
						"Kids, first stop is whatever's nearest.",
					])
				"children":
					return PackedStringArray([
						"I wanna see a cute one!",
						"Are there fluffy ones?",
						"Can we go look? Can we?",
					])
				"tourists":
					return PackedStringArray([
						"Hoping for something majestic.",
						"Need one good photo. Just one.",
						"Where's the postcard animal?",
					])
				"goths":
					return PackedStringArray([
						"Show me the grim stuff.",
						"If it isn't grim, I'm not staying.",
						"Point me at the grim exhibits.",
					])
				"creators":
					return PackedStringArray([
						"Look at these animals chat.",
						"We're live. Hunting for a clip.",
						"Chat, this better be worth posting.",
					])
				"thrill":
					return PackedStringArray([
						"Looking for a scare.",
						"Something with teeth, please.",
					])
				"scientists":
					return PackedStringArray([
						"Let's see how unusual this mix is.",
						"Notes first. Wonder later.",
					])
				"parents":
					return PackedStringArray([
						"We'll follow the kids around.",
						"If the kids are happy, I'm happy.",
					])
				_:
					return PackedStringArray(["Let's see what they've got."])
		"like":
			match voice:
				"family":
					return PackedStringArray([
						"The kids can't stop talking about the %s one.",
						"Look at the kids. They're hooked on the %s one.",
						"That %s one just made the trip worth it for the kids.",
					])
				"children":
					return PackedStringArray([
						"The %s one is the BEST.",
						"I love the %s one so much.",
						"Can we live here with the %s one?",
					])
				"tourists":
					return PackedStringArray([
						"That's going on the postcard.",
						"Hold still. This is the shot.",
						"Finally. Something photogenic.",
					])
				"goths":
					return PackedStringArray([
						"Yes. Keep it grim.",
						"This is the grim energy I came for.",
						"Don't you dare make it cute.",
					])
				"creators":
					return PackedStringArray([
						"Look at these animals chat.",
						"Chat, this is the one.",
						"That's the clip. Smash like.",
						"This is going to do numbers.",
					])
				"thrill":
					return PackedStringArray([
						"That one actually looks dangerous.",
						"Yes. That. More of that.",
					])
				"scientists":
					return PackedStringArray([
						"A proper mix. Finally.",
						"The arrangement is… interesting.",
					])
				"parents":
					return PackedStringArray([
						"The kids are having a good time.",
						"Alright. This one's a hit with the kids.",
					])
				_:
					return PackedStringArray(["They're enjoying the %s."])
		"film":
			match voice:
				"creators":
					return PackedStringArray([
						"Look at these animals chat.",
						"Okay chat, exhibit incoming.",
						"We're live chat. Don't scroll.",
						"Chat, look at this.",
					])
				_:
					return PackedStringArray(["Look at that."])
		"hate":
			match voice:
				"family":
					return PackedStringArray([
						"The kids didn't like that. Too %s.",
						"We're steering the kids away from the %s one.",
						"That %s exhibit is a no from the kids.",
					])
				"children":
					return PackedStringArray([
						"It's too %s. I don't like it.",
						"I don't want to look at the %s one.",
						"Make it go away. It's %s.",
					])
				"tourists":
					return PackedStringArray([
						"Nothing majestic about that.",
						"I'm not putting that on the feed.",
						"That's not the photo I wanted.",
					])
				"goths":
					return PackedStringArray([
						"Ugh. Too %s. Not grim enough.",
						"Cute? In this economy?",
					])
				"creators":
					return PackedStringArray([
						"Not filming that.",
						"My audience would scroll past.",
					])
				"thrill":
					return PackedStringArray([
						"Too soft. Where's the bite?",
						"I didn't come for a nap.",
					])
				"scientists":
					return PackedStringArray([
						"Too ordinary.",
						"I've seen this mix in textbooks.",
					])
				"parents":
					return PackedStringArray([
						"Not sure this is a good one.",
						"Maybe we skip this pen.",
					])
				_:
					return PackedStringArray(["Not a fan of the %s."])
		"scared":
			match voice:
				"family":
					return PackedStringArray([
						"The kids are frightened. Too scary.",
						"Kids, don't look. We're moving on.",
						"That one's too much for the kids.",
					])
				"children":
					return PackedStringArray([
						"It's too scary. I want to go home.",
						"I don't like its teeth.",
						"Mum. Dad. It's looking at me.",
					])
				"parents":
					return PackedStringArray([
						"The kids are shaking. We're done here.",
						"That's too scary for them.",
					])
				_:
					return PackedStringArray(["That exhibit is too scary."])
		"bored":
			match voice:
				"family":
					return PackedStringArray([
						"The kids are bored. Time to go.",
						"We've walked the same loop twice. Kids are done.",
					])
				"children":
					return PackedStringArray([
						"I'm bored.",
						"Is this all of them?",
					])
				_:
					return PackedStringArray([
						"Nothing new. Not worth another ticket.",
						"Seen it. Next park.",
					])
		"done":
			match voice:
				"family":
					return PackedStringArray([
						"We've seen the lot. Worth the trip for the kids.",
						"Kids are happy. That's a win.",
					])
				"tourists":
					return PackedStringArray([
						"Got the photos. Happy with that.",
						"Postcard acquired.",
					])
				"goths":
					return PackedStringArray([
						"Grim enough. I'll allow it.",
						"A grim little zoo. Not bad.",
					])
				_:
					return PackedStringArray([
						"We've seen it. Pretty good zoo.",
						"That's a wrap. Decent park.",
					])
		"done_bad":
			match voice:
				"family":
					return PackedStringArray([
						"We've seen the lot. The kids weren't impressed.",
						"Kids wanted more. We got less.",
					])
				_:
					return PackedStringArray([
						"We've seen it. Not our kind of zoo.",
						"Wouldn't come back.",
					])
		"wait":
			match voice:
				"family":
					return PackedStringArray([
						"Still wandering. The kids want more.",
						"Kids, one more pen. Then snacks.",
					])
				"children":
					return PackedStringArray([
						"Still looking for a cute one.",
						"Is there a fluffy one this way?",
					])
				"tourists":
					return PackedStringArray([
						"Still waiting for something majestic.",
						"The big photo's around here somewhere.",
					])
				"goths":
					return PackedStringArray([
						"Still hunting for something grim.",
						"Keep walking. The grim bit's further in.",
					])
				"scientists":
					return PackedStringArray([
						"Still looking for something unusual.",
						"The interesting mix has to be here.",
					])
				_:
					return PackedStringArray(["Still looking."])
		_:
			return PackedStringArray()
	return PackedStringArray()


static func _event(kind: String) -> PackedStringArray:
	match kind:
		"parent_goth":
			return PackedStringArray([
				"Kids, car. Now.",
				"Don't look at them. We're leaving.",
				"Absolutely not. Back to the car.",
				"I did not bring the kids for this.",
			])
		"parent_mate":
			return PackedStringArray([
				"DISGUSTING",
			])
		"kid_goth":
			return PackedStringArray([
				"They're scary!",
				"I don't like those people.",
				"Mum, I want the car.",
				"They're looking at me!",
			])
		"tourist_goth":
			return PackedStringArray([
				"This crowd is a bit much.",
				"Not the vibe I booked.",
				"Maybe another hour. Maybe not.",
			])
		"souvenir":
			return PackedStringArray([
				"Souvenir. Had to.",
				"This one's coming home with me.",
				"Gift shop win.",
			])
		"snack":
			return PackedStringArray([
				"Snack run.",
				"I needed that.",
				"One more pretzel.",
			])
		"roar_thrill":
			return PackedStringArray([
				"That roar!",
				"Do it again!",
				"YES.",
			])
		"roar_kid":
			return PackedStringArray([
				"Too loud!",
				"It shouted at me!",
				"I didn't like that roar.",
			])
		"roar_parent":
			return PackedStringArray([
				"Kids, cover your ears.",
				"That was a bit much.",
			])
		"creator_clip":
			return PackedStringArray([
				"Posted. More guests are coming.",
				"That's up. Watch the gate.",
				"Clip's live. You're welcome.",
				"Chat went feral. Extra guests incoming.",
			])
		"too_scary":
			return PackedStringArray([
				"Too scary!",
				"I don't want to look.",
				"It's going to eat me.",
			])
		"cute_love":
			return PackedStringArray([
				"It's so cute!",
				"Can we take it home?",
				"I love it I love it I love it.",
			])
		_:
			return PackedStringArray()
