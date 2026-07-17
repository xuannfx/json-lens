application = defines["application"]
background_image = defines["background"]
volume_icon = defines["icon"]

format = "UDZO"
filesystem = "HFS+"
files = [application]
symlinks = {"Applications": "/Applications"}
icon = volume_icon
background = background_image

window_rect = ((200, 150), (700, 440))
icon_size = 112
text_size = 12
show_status_bar = False
show_toolbar = False
show_pathbar = False
show_sidebar = False
arrange_by = None
grid_offset = (0, 0)
grid_spacing = 100

icon_locations = {
    "Json Lens.app": (170, 240),
    "Applications": (530, 240),
}

hide = [".background.png", ".DS_Store", ".VolumeIcon.icns"]
