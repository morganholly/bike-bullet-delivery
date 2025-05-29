extends Area3D


@export var free_ammo: Dictionary[GunStats.BulletType, int]
@export var full_mags: Dictionary[GunStats.BulletType, int]
@export var take_while_holding: bool = true
@export var disable_equip: bool = false



func _on_body_entered(body: Node3D) -> void:
	print("got an ammo. ")
	if not disable_equip:
		if body.is_in_group(&"Player"):
			if not take_while_holding:
				if self.get_parent().is_in_group(&"IsHeld"):
					return
			var done=false
			for bt in GunStats.BulletType.values():
				body.hold_container.ammo_pool.free_ammo[bt] = free_ammo.get_or_add(bt, 0) + body.hold_container.ammo_pool.free_ammo.get_or_add(bt, 0)
				#self.free_ammo[bt] = 0
				body.hold_container.ammo_pool.full_mags[bt] = full_mags.get_or_add(bt, 0) + body.hold_container.ammo_pool.full_mags.get_or_add(bt, 0)
				#self.full_mags[bt] = 0
				if body.hold_container.ammo_pool.free_ammo[bt] + body.hold_container.ammo_pool.full_mags[bt] > 0:
					print("up to ", body.hold_container.ammo_pool.full_mags[bt], " mags and ", body.hold_container.ammo_pool.free_ammo[bt], " bullets for", str(bt))
					#play pickup sound #TIDYUP
					body.hold_container.ammo_pool.play_ammopickup() #TIDYUP
					var res=calculate_reserve_ammo(body.hold_container.ammo_pool, bt, 11)
					UIManager.update_bullet_display(-2, res) #needs to update here #TIDYUP
					#var ammo_pool_ref = ammo_pool  # Store reference to ammo pool
					#var reserve_ammo = calculate_reserve_ammo(ammo_pool)
					#UIManager.update_bullet_display(bullets_in_mag, reserve_ammo)
					
			
			if not self.get_parent().is_in_group(&"IsHeld"):
				self.get_parent().queue_free()
				
func calculate_reserve_ammo(ammo_pool: Node, bullet_type, mag_capacity) -> int:
	#var bullet_type = gun_stats.bullet_id
	var free_bullets = ammo_pool.free_ammo.get_or_add(bullet_type, 0)
	var full_mags = ammo_pool.full_mags.get_or_add(bullet_type, 0)
	
	# Calculate total reserve bullets (free bullets + full magazines * capacity)
	#return free_bullets + (full_mags * gun_stats.mag_capacity)
	return free_bullets + (full_mags * mag_capacity)
