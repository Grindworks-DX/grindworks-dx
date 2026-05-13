extends ToonAttack
class_name GagToonup

## Holds all toon-up movies
## The damage value is irrelevant to this class
## Use the Toonup Effect value for consistency (more flexibility as a float)

enum MovieType {
	FEATHER,
	MEGAPHONE,
	LIPSTICK,
	CANE,
	PIXIE,
	JUGGLING
}
@export var movie_type := MovieType.FEATHER

var toon: Toon
var props : Array[Node3D] = []

@export var toonup_effect := 0.0

var small_laughs : Array[String] = [
	"Ha Ha Ha"
]
var big_laughs : Array[String] = [
	"BWAH HAH HAH HAH!",
	"HA HA HA!",
	"HO HO HO!"
]

func action():
	toon = user.toon
	initialize_props()
	
	# Find the camera focus position
	#manager.s_focus_char.emit(manager.battle_node)
	#manager.battle_node.battle_cam.global_position.y-=5.0
	#manager.battle_node.battle_cam.position.x += [-2.0,2.0][randi()%2]
	#manager.battle_node.battle_cam.look_at(user.head_node.global_position)
	manager.s_focus_char.emit(user)
	
	
	# Run the custom toonup movies
	await run_custom_movie()

	# Cleanup Props
	for prop in props:
		prop.queue_free()

# Is run at the beginning of the script.
func initialize_props():
	match movie_type:
		MovieType.FEATHER:
			var feather := create_prop(load('res://models/props/gags/feather/feather.tscn'))
			toon.right_hand_bone.add_child(feather)
		MovieType.MEGAPHONE:
			var megaphone := create_prop(load('res://models/props/gags/megaphone/megaphone.glb'))
			toon.right_hand_bone.add_child(megaphone)
		MovieType.LIPSTICK:
			var lipstick := create_prop(load('res://models/props/gags/lipstick/lipstick.glb'))
			toon.right_hand_bone.add_child(lipstick)
			lipstick.position = Vector3(-.237,.122,.009)
			lipstick.rotation = Vector3(-8.4,-90.4,-27.8)
		MovieType.CANE:
			var cane := create_prop(load('res://models/props/gags/cane/cane.glb'))
			var hat := create_prop(load('res://models/props/gags/cane/hat.glb'))
			toon.right_hand_bone.add_child(cane)
			toon.hat_bone.add_child(hat)
			hat.rotation_degrees.z = -75.0
			hat.position.y = -0.24
		MovieType.JUGGLING:
			var cubes := create_prop(load('res://models/props/gags/cubes/cubes.tscn'))
			toon.hip_bone.add_child(cubes)
			cubes.rotate_y(deg_to_rad(180.0))
			#cubes.position.y += 0.6


# Use this method to instantiate props
# So they can be referenced anywhere (just track indexes)
# And they can be automatically freed at end of anim
func create_prop(prop : PackedScene) -> Node3D:
	var newprop = prop.instantiate()
	props.append(newprop)
	return newprop


func run_custom_movie():
	var target = targets[0]
	match movie_type:
		MovieType.FEATHER:
			var feather := props[0]
			user.set_animation('tickle')
			feather.get_node('AnimationPlayer').play('toonup')
			await manager.sleep(0.2)
			AudioManager.play_sound(load("res://audio/sfx/battle/gags/toonup/AA_heal_tickle.mp3"))
			await manager.sleep(2.2)
			manager.affect_target(user,int(round(toonup_effect)),false)
			target.set_animation('cringe')
			user.toon.speak(small_laughs[randi()%small_laughs.size()])
			await manager.barrier(user.animator.animation_finished, 3.0)
		MovieType.MEGAPHONE:
			user.set_animation('shout')
			toon.speak("Why couldn't the twelve year old get into the pirate movie?")
			AudioManager.play_sound(load("res://audio/sfx/battle/gags/toonup/AA_heal_telljoke.mp3"))
			await manager.sleep(2.4)
			toon.speak('It was rated "ARRR"!')
			await manager.sleep(1.0)
			manager.affect_target(user,int(round(toonup_effect)),false)
			user.toon.speak("That wasn't very funny")
			await manager.sleep(2.5)
		MovieType.LIPSTICK:
			# Setup
			user.set_animation('smooch')
			await manager.sleep(2.0)
			
			# Create lips
			AudioManager.play_sound(load('res://audio/sfx/battle/gags/toonup/AA_heal_smooch.mp3'))
			var lips : Sprite3D = load('res://models/props/gags/lipstick/lips.tscn').instantiate()
			toon.add_child(lips)
			lips.position = Vector3(-1.048,3.227,2.279)
			lips.scale = Vector3(0.01,0.01,0.01)
			
			# Lip grow/shoot anim
			var grow_tween : Tween = lips.create_tween()
			grow_tween.tween_property(lips,'scale',Vector3(2,2,2),0.5)
			grow_tween.tween_interval(2.2)
			grow_tween.tween_property(lips,'global_position',user.global_position,0.25)
			
			# Lip cleanup + heal
			await grow_tween.finished
			grow_tween.kill()
			lips.queue_free()
			manager.affect_target(user,toonup_effect,false)
			user.set_animation('conked')
			user.toon.speak(big_laughs[randi()%big_laughs.size()])
			await manager.barrier(user.animator.animation_finished, 3.0)
		MovieType.CANE:
			user.set_animation('happy_dance')
			AudioManager.play_sound(load('res://audio/sfx/battle/gags/toonup/AA_heal_happydance.mp3'))
			await manager.sleep(2.0)
			manager.affect_target(user,toonup_effect,false)
			user.toon.speak(big_laughs[randi()%big_laughs.size()])
			await manager.barrier(user.animator.animation_finished, 3.0)
		MovieType.PIXIE:
			toon.rotation_degrees.y+=90.0
			user.set_animation('sprinkle')
			await manager.sleep(1.8)
			manager.affect_target(user,toonup_effect,false)
			user.toon.speak(big_laughs[randi()%big_laughs.size()])
			play_pixie_sfx()
			var dust := create_prop(load('res://objects/battle/effects/pixie_dust/pixie_dust.tscn'))
			user.toon.add_child(dust)
			dust.position.y = 5.0
			await manager.barrier(user.animator.animation_finished, 3.0)
			dust.emitting = false
			toon.rotation_degrees.y-=90.0
		MovieType.JUGGLING:
			var cubes := props[0]
			cubes.get_node('AnimationPlayer').play('juggle')
			await manager.sleep(0.1)
			user.set_animation('juggle')
			AudioManager.play_sound(load('res://audio/sfx/battle/gags/toonup/AA_heal_juggle.mp3'))
			await manager.sleep(4.0)
			manager.affect_target(user,toonup_effect,false)
			user.toon.speak(big_laughs[randi()%big_laughs.size()])
			await manager.barrier(user.animator.animation_finished, 5.0)

func play_pixie_sfx():
	var sounds : Array[AudioStream] = [
		load("res://audio/sfx/battle/gags/toonup/AA_single_pixiedust_1.mp3"),
		load("res://audio/sfx/battle/gags/toonup/AA_single_pixiedust_2.mp3"),
		load("res://audio/sfx/battle/gags/toonup/AA_single_pixiedust_3.mp3")
	]
	var sfx := 0
	while sfx < 3:
		AudioManager.play_sound(sounds[sfx])
		sfx+=1
		await manager.sleep(1.2)
