#!/usr/bin/env python3
"""
Generate PropPhone app icon with cosmic gradient and phone design
"""

from PIL import Image, ImageDraw, ImageFilter, ImageFont
import math
import os

def create_gradient(size, colors):
    """Create a diagonal gradient"""
    img = Image.new('RGBA', (size, size))
    draw = ImageDraw.Draw(img)

    for y in range(size):
        for x in range(size):
            # Diagonal gradient
            ratio = (x + y) / (2 * size)

            r = int(colors[0][0] + (colors[1][0] - colors[0][0]) * ratio)
            g = int(colors[0][1] + (colors[1][1] - colors[0][1]) * ratio)
            b = int(colors[0][2] + (colors[1][2] - colors[0][2]) * ratio)

            img.putpixel((x, y), (r, g, b, 255))

    return img

def create_radial_glow(size, center, radius, color, intensity=0.5):
    """Create a radial glow effect"""
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))

    for y in range(size):
        for x in range(size):
            dist = math.sqrt((x - center[0])**2 + (y - center[1])**2)
            if dist < radius:
                alpha = int(255 * intensity * (1 - dist/radius)**2)
                img.putpixel((x, y), (color[0], color[1], color[2], alpha))

    return img

def draw_rounded_rect(draw, coords, radius, fill):
    """Draw a rounded rectangle"""
    x1, y1, x2, y2 = coords

    # Main rectangle
    draw.rectangle([x1 + radius, y1, x2 - radius, y2], fill=fill)
    draw.rectangle([x1, y1 + radius, x2, y2 - radius], fill=fill)

    # Corners
    draw.ellipse([x1, y1, x1 + 2*radius, y1 + 2*radius], fill=fill)
    draw.ellipse([x2 - 2*radius, y1, x2, y1 + 2*radius], fill=fill)
    draw.ellipse([x1, y2 - 2*radius, x1 + 2*radius, y2], fill=fill)
    draw.ellipse([x2 - 2*radius, y2 - 2*radius, x2, y2], fill=fill)

def create_phone_icon(size):
    """Create a stylized phone shape"""
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Phone dimensions
    phone_width = int(size * 0.38)
    phone_height = int(size * 0.7)
    phone_x = (size - phone_width) // 2
    phone_y = (size - phone_height) // 2
    corner_radius = int(phone_width * 0.18)

    # Phone body with gradient-like effect (darker center)
    # Outer glow/border
    draw_rounded_rect(draw,
        [phone_x - 4, phone_y - 4, phone_x + phone_width + 4, phone_y + phone_height + 4],
        corner_radius + 4, (255, 255, 255, 80))

    # Main phone body (dark with slight transparency for glass effect)
    draw_rounded_rect(draw,
        [phone_x, phone_y, phone_x + phone_width, phone_y + phone_height],
        corner_radius, (20, 20, 35, 230))

    # Screen area (slightly lighter)
    screen_margin = int(phone_width * 0.08)
    screen_top = int(phone_height * 0.12)
    screen_bottom = int(phone_height * 0.08)
    screen_radius = int(corner_radius * 0.6)

    draw_rounded_rect(draw,
        [phone_x + screen_margin, phone_y + screen_top,
         phone_x + phone_width - screen_margin, phone_y + phone_height - screen_bottom],
        screen_radius, (40, 45, 70, 200))

    # Dynamic Island / notch
    notch_width = int(phone_width * 0.35)
    notch_height = int(phone_height * 0.035)
    notch_x = phone_x + (phone_width - notch_width) // 2
    notch_y = phone_y + int(phone_height * 0.045)
    notch_radius = notch_height // 2

    draw_rounded_rect(draw,
        [notch_x, notch_y, notch_x + notch_width, notch_y + notch_height],
        notch_radius, (10, 10, 20, 255))

    # Time display on screen
    time_y = phone_y + int(phone_height * 0.22)

    # Simple time representation with circles/dots
    dot_radius = int(phone_width * 0.025)
    dot_y = time_y
    dot_spacing = int(phone_width * 0.08)
    center_x = phone_x + phone_width // 2

    # "9:41" stylized - just show as glowing element
    time_width = int(phone_width * 0.4)
    time_height = int(phone_height * 0.06)
    time_x = center_x - time_width // 2

    # Glowing time element
    draw_rounded_rect(draw,
        [time_x, time_y, time_x + time_width, time_y + time_height],
        time_height // 2, (255, 255, 255, 150))

    # Incoming call style elements - caller circle
    caller_y = phone_y + int(phone_height * 0.42)
    caller_radius = int(phone_width * 0.18)
    caller_x = center_x

    # Caller avatar circle with gradient
    draw.ellipse([caller_x - caller_radius, caller_y - caller_radius,
                  caller_x + caller_radius, caller_y + caller_radius],
                 fill=(100, 200, 255, 180))

    # Inner circle
    inner_radius = int(caller_radius * 0.7)
    draw.ellipse([caller_x - inner_radius, caller_y - inner_radius,
                  caller_x + inner_radius, caller_y + inner_radius],
                 fill=(60, 150, 220, 200))

    # Person silhouette (simple)
    head_radius = int(caller_radius * 0.25)
    draw.ellipse([caller_x - head_radius, caller_y - head_radius - int(caller_radius * 0.15),
                  caller_x + head_radius, caller_y + head_radius - int(caller_radius * 0.15)],
                 fill=(255, 255, 255, 200))

    # Caller name bar
    name_y = caller_y + caller_radius + int(phone_height * 0.04)
    name_width = int(phone_width * 0.5)
    name_height = int(phone_height * 0.025)

    draw_rounded_rect(draw,
        [center_x - name_width//2, name_y, center_x + name_width//2, name_y + name_height],
        name_height // 2, (255, 255, 255, 120))

    # Call buttons at bottom
    button_y = phone_y + int(phone_height * 0.82)
    button_radius = int(phone_width * 0.12)
    button_spacing = int(phone_width * 0.35)

    # Decline button (red)
    decline_x = center_x - button_spacing // 2
    draw.ellipse([decline_x - button_radius, button_y - button_radius,
                  decline_x + button_radius, button_y + button_radius],
                 fill=(255, 69, 58, 230))

    # Accept button (green)
    accept_x = center_x + button_spacing // 2
    draw.ellipse([accept_x - button_radius, button_y - button_radius,
                  accept_x + button_radius, button_y + button_radius],
                 fill=(48, 209, 88, 230))

    return img

def generate_app_icon(output_path, size=1024):
    """Generate the complete app icon"""

    # Create base with cosmic gradient (purple to cyan)
    purple = (89, 86, 214)  # Vibrant purple
    cyan = (0, 199, 190)    # Electric cyan
    dark_purple = (30, 20, 60)

    # Start with dark base
    base = Image.new('RGBA', (size, size), dark_purple)

    # Add gradient
    gradient = create_gradient(size, [purple, cyan])
    gradient = gradient.filter(ImageFilter.GaussianBlur(radius=50))
    base = Image.alpha_composite(base, gradient)

    # Add some glow spots for depth
    glow1 = create_radial_glow(size, (size * 0.3, size * 0.3), size * 0.5, (138, 43, 226), 0.4)
    base = Image.alpha_composite(base, glow1)

    glow2 = create_radial_glow(size, (size * 0.7, size * 0.7), size * 0.4, (0, 255, 255), 0.3)
    base = Image.alpha_composite(base, glow2)

    # Add subtle center glow
    center_glow = create_radial_glow(size, (size//2, size//2), size * 0.6, (255, 255, 255), 0.15)
    base = Image.alpha_composite(base, center_glow)

    # Create phone icon
    phone = create_phone_icon(size)

    # Add subtle shadow under phone
    shadow = phone.copy()
    shadow = shadow.filter(ImageFilter.GaussianBlur(radius=20))
    shadow_layer = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    shadow_offset = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    shadow_offset.paste(shadow, (8, 8))
    base = Image.alpha_composite(base, shadow_offset)

    # Composite phone onto base
    base = Image.alpha_composite(base, phone)

    # Add subtle outer glow to phone
    phone_glow = phone.filter(ImageFilter.GaussianBlur(radius=15))
    glow_layer = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    glow_layer = Image.alpha_composite(glow_layer, phone_glow)

    # Final composition
    final = Image.alpha_composite(base, glow_layer)

    # Convert to RGB for PNG without transparency issues
    final_rgb = Image.new('RGB', (size, size), (0, 0, 0))
    final_rgb.paste(final, mask=final.split()[3] if final.mode == 'RGBA' else None)

    # Save
    final.save(output_path, 'PNG')
    print(f"Icon saved to: {output_path}")

    return output_path

if __name__ == "__main__":
    # Output path
    script_dir = os.path.dirname(os.path.abspath(__file__))
    icon_path = os.path.join(script_dir, "PropPhone", "Assets.xcassets", "AppIcon.appiconset", "AppIcon.png")

    # Generate
    generate_app_icon(icon_path, 1024)
    print("App icon generated successfully!")
