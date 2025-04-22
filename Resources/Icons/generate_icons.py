import os
from PIL import Image, ImageDraw

# Create directory paths
app_icon_dir = '/Users/z/work/hanzo/prompt-magic/Resources/Assets.xcassets/AppIcon.appiconset'
menu_icon_dir = '/Users/z/work/hanzo/prompt-magic/Resources/Assets.xcassets/MenuBarIcon.imageset'
menu_inactive_dir = '/Users/z/work/hanzo/prompt-magic/Resources/Assets.xcassets/MenuBarIconInactive.imageset'

# App icon sizes
app_icon_sizes = [16, 32, 64, 128, 256, 512, 1024]

# Main app color - purple (#6C5CE7)
app_color = (108, 92, 231)
inactive_color = (170, 170, 170)  # Gray for inactive icons

def create_app_icon(size, color, output_path):
    """Create a simple app icon with the given size and color"""
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Draw a circular background
    padding = int(size * 0.05)
    circle_diameter = size - (2 * padding)
    draw.ellipse(
        [(padding, padding), (padding + circle_diameter, padding + circle_diameter)],
        fill=color
    )
    
    # Add a simple "chat bubble" shape
    bubble_padding = int(size * 0.2)
    bubble_size = size - (2 * bubble_padding)
    draw.ellipse(
        [(bubble_padding, bubble_padding), 
         (bubble_padding + bubble_size, bubble_padding + bubble_size)],
        fill=(255, 255, 255, 220)  # Slightly transparent white
    )
    
    # Add a vertical line in the center (the "wand")
    line_width = max(1, int(size * 0.05))
    center_x = size // 2
    top_y = int(size * 0.35)
    bottom_y = int(size * 0.65)
    draw.line([(center_x, top_y), (center_x, bottom_y)], fill=color, width=line_width)
    
    # Save the image
    img.save(output_path, 'PNG')
    print("Created {} ({}x{})".format(output_path, size, size))

def create_menu_bar_icon(size, color, output_path):
    """Create a simplified menu bar icon"""
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # For menu bar, we want a simpler shape that works well as a template
    padding = int(size * 0.15)
    
    # Draw a simple chat bubble
    bubble_width = size - (2 * padding)
    bubble_height = int(bubble_width * 0.8)
    
    # Bubble outline points (simple rounded rectangle with pointer)
    bubble_top = padding
    bubble_left = padding
    bubble_right = padding + bubble_width
    bubble_bottom = padding + bubble_height
    
    # Check if rectangle with radius is available (older PIL versions might not have it)
    try:
        # Draw the basic bubble shape with rounded corners
        draw.rectangle(
            [(bubble_left, bubble_top), (bubble_right, bubble_bottom)],
            fill=color, 
            outline=None, 
            width=0,
            radius=int(size * 0.15)  # Rounded corners
        )
    except TypeError:
        # Fallback for older PIL versions
        draw.rectangle(
            [(bubble_left, bubble_top), (bubble_right, bubble_bottom)],
            fill=color
        )
    
    # Add a simple "wand" in the center
    line_width = max(1, int(size * 0.06))
    center_x = size // 2
    top_y = int(size * 0.35)
    bottom_y = int(size * 0.7)
    draw.line([(center_x, top_y), (center_x, bottom_y)], fill=(255, 255, 255), width=line_width)
    
    # Save the image
    img.save(output_path, 'PNG')
    print("Created {} ({}x{})".format(output_path, size, size))

# Generate app icons
for size in app_icon_sizes:
    output_path = os.path.join(app_icon_dir, "appicon-{}.png".format(size))
    create_app_icon(size, app_color, output_path)

# Generate menu bar icons
create_menu_bar_icon(20, app_color, os.path.join(menu_icon_dir, "menubar-icon.png"))
create_menu_bar_icon(40, app_color, os.path.join(menu_icon_dir, "menubar-icon@2x.png"))
create_menu_bar_icon(20, inactive_color, os.path.join(menu_inactive_dir, "menubar-icon-inactive.png"))
create_menu_bar_icon(40, inactive_color, os.path.join(menu_inactive_dir, "menubar-icon-inactive@2x.png"))

print("All icons generated successfully!")
