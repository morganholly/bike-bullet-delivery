extends Area3D


@export var free_ammo: Dictionary[GunStats.BulletType, int]
@export var full_mags: Dictionary[GunStats.BulletType, int]
@export var take_while_holding: bool = true

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group(&"Player"):
		if not take_while_holding:
			if self.get_parent().is_in_group(&"IsHeld"):
				return
		for bt in GunStats.BulletType.values():
			body.hold_container.ammo_pool.free_ammo[bt] = free_ammo.get_or_add(bt, 0) + body.hold_container.ammo_pool.free_ammo.get_or_add(bt, 0)
			self.free_ammo[bt] = 0
			body.hold_container.ammo_pool.full_mags[bt] = full_mags.get_or_add(bt, 0) + body.hold_container.ammo_pool.full_mags.get_or_add(bt, 0)
			self.full_mags[bt] = 0
			if body.hold_container.ammo_pool.free_ammo[bt] + body.hold_container.ammo_pool.full_mags[bt] > 0:
				print("up to ", body.hold_container.ammo_pool.full_mags[bt], " mags and ", body.hold_container.ammo_pool.free_ammo[bt], " bullets for", str(bt))
		if not self.get_parent().is_in_group(&"IsHeld"):
			self.get_parent().queue_free()
