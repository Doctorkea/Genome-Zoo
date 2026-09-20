extends RefCounted
class_name GuestMoodArt

## Overhead marks for park guests. Graphics are Twemoji (CC-BY 4.0),
## Copyright 2020 Twitter, Inc and other contributors:
## https://github.com/jdecked/twemoji

const TEX_BANG: Texture2D = preload("res://art/ui/mood/bang.png")
const TEX_TEAR: Texture2D = preload("res://art/ui/mood/tear.png")
const TEX_HEART: Texture2D = preload("res://art/ui/mood/heart.png")
const TEX_SWEAT: Texture2D = preload("res://art/ui/mood/sweat.png")
const TEX_SPARK: Texture2D = preload("res://art/ui/mood/spark.png")


static func bang() -> Texture2D:
	return TEX_BANG


static func tear() -> Texture2D:
	return TEX_TEAR


static func heart() -> Texture2D:
	return TEX_HEART


static func sweat() -> Texture2D:
	return TEX_SWEAT


static func spark() -> Texture2D:
	return TEX_SPARK
