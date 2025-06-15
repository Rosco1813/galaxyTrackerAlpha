extends CanvasLayer

var green:Color = Color("71b446")
var orange:Color = Color("e19728")
var salmon:Color = Color("e882df")
var red:Color = Color("e70002d8")
var blue:Color = Color("0235ff")
@onready var pistol_label:Label =$primary_ammo/VBoxContainer/Label
@onready var pistol_icon:TextureRect = $primary_ammo/VBoxContainer/TextureRect

@onready var shotgun_lable:Label = $shotgun_ammo/VBoxContainer/Label
@onready var shotgun_icon:TextureRect = $shotgun_ammo/VBoxContainer/TextureRect

@onready var grenade_label:Label = $grenade_ammo/VBoxContainer/Label
@onready var grenade_icon: TextureRect = $grenade_ammo/VBoxContainer/TextureRect
@onready var player_one_health:TextureProgressBar = $health_container/TextureProgressBar
@onready var player_one_stamina:TextureProgressBar = $stamina_container/TextureProgressBar
@onready var selected_weapon_label:Label = $selected_weapon/VBoxContainer/Label
func _ready() -> void:
	update_stats()
	Globals.connect("stats_updated", update_stats)
	print('attempt global connection to stats_updated')
#	Globals.connect("stats_updated ", update_stats )
#	update_player_one_stamina()
#	update_selected_weapon()

func update_selected_weapon():
	selected_weapon_label.text = Globals.selectedWeapon
	if Globals.selectedWeapon == 'shotgun':
		update_shotgun_ui()
func update_pistol_ammo_text():
	pistol_label.text = str(Globals.pistol_ammo)
	if Globals.pistol_ammo == 0:
		pistol_label.modulate = red
		pistol_icon.modulate = red
	else:
		pistol_label.modulate = salmon
		pistol_icon.modulate = orange

func update_shotgun_ui():
	shotgun_lable.text = str(Globals.shot_gun_ammo)
	if Globals.shot_gun_ammo == 0:
		shotgun_lable.modulate = red
		shotgun_icon.modulate = red
	else:
		shotgun_lable.modulate = blue
		shotgun_icon.modulate = blue

func update_grenade_ammo_text():
	grenade_label.text = str(Globals.grenade_ammo)
	if Globals.grenade_ammo == 0:
		grenade_label.modulate = red
		grenade_icon.modulate = red
	else:
		grenade_label.modulate = salmon
		grenade_icon.modulate = green

func update_player_one_health():
	player_one_health.value = Globals.player_one_health
func update_player_one_stamina():
	player_one_stamina.value = Globals.player_one_stamina


func update_stats():
#	print('============= update stats ================')
	update_pistol_ammo_text()
	update_grenade_ammo_text()
	update_player_one_health()
	update_player_one_stamina()
	update_selected_weapon()
	update_shotgun_ui()
