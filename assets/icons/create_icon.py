#!/usr/bin/env python3
"""
Simple script to create app icons for Expensify
Creates a wallet-themed icon with money symbol
"""

try:
    from PIL import Image, ImageDraw, ImageFont
    import os
except ImportError:
    print("PIL (Pillow) not found. Please install it with: pip install Pillow")
    exit(1)

def create_app_icon():
    # Create main app icon (1024x1024)
    size = 1024
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Background circle with gradient effect
    center = size // 2
    radius = int(size * 0.47)
    
    # Create gradient background
    for i in range(radius):
        alpha = int(255 * (1 - i / radius))
        color_r = int(37 + (29 - 37) * (i / radius))  # From #2563EB to #1D4ED8
        color_g = int(99 + (78 - 99) * (i / radius))
        color_b = int(235 + (216 - 235) * (i / radius))
        
        draw.ellipse([center - radius + i, center - radius + i, 
                     center + radius - i, center + radius - i], 
                    fill=(color_r, color_g, color_b, 255))
    
    # Wallet body
    wallet_left = int(size * 0.25)
    wallet_top = int(size * 0.35)
    wallet_width = int(size * 0.5)
    wallet_height = int(size * 0.3)
    
    # Main wallet rectangle
    draw.rounded_rectangle([wallet_left, wallet_top, 
                           wallet_left + wallet_width, wallet_top + wallet_height],
                          radius=20, fill=(30, 41, 59, 240))
    
    # Wallet flap
    flap_height = int(wallet_height * 0.25)
    draw.rounded_rectangle([wallet_left, wallet_top, 
                           wallet_left + wallet_width, wallet_top + flap_height],
                          radius=20, fill=(71, 85, 105, 255))
    
    # Credit card
    card_left = wallet_left + int(wallet_width * 0.15)
    card_top = wallet_top + int(wallet_height * 0.4)
    card_width = int(wallet_width * 0.55)
    card_height = int(wallet_height * 0.45)
    
    draw.rounded_rectangle([card_left, card_top, 
                           card_left + card_width, card_top + card_height],
                          radius=12, fill=(16, 185, 129, 255))
    
    # Card stripe
    stripe_height = int(card_height * 0.25)
    draw.rounded_rectangle([card_left, card_top, 
                           card_left + card_width, card_top + stripe_height],
                          radius=12, fill=(6, 95, 70, 255))
    
    # Dollar sign
    dollar_x = wallet_left + int(wallet_width * 0.8)
    dollar_y = wallet_top + int(wallet_height * 0.6)
    dollar_radius = int(size * 0.06)
    
    # Dollar background circle
    draw.ellipse([dollar_x - dollar_radius, dollar_y - dollar_radius,
                 dollar_x + dollar_radius, dollar_y + dollar_radius],
                fill=(245, 158, 11, 255))
    
    # Try to use a system font for the dollar sign
    try:
        font_size = int(dollar_radius * 1.5)
        font = ImageFont.truetype("arial.ttf", font_size)
    except:
        try:
            font = ImageFont.truetype("/System/Library/Fonts/Arial.ttf", int(dollar_radius * 1.5))
        except:
            font = ImageFont.load_default()
    
    # Draw dollar sign
    draw.text((dollar_x, dollar_y), "$", font=font, fill=(255, 255, 255, 255), anchor="mm")
    
    # Save main icon
    img.save('assets/icons/app_icon.png', 'PNG')
    print("Created app_icon.png")
    
    # Create adaptive foreground icon (simpler version)
    fg_img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    fg_draw = ImageDraw.Draw(fg_img)
    
    # Simplified wallet for foreground
    fg_wallet_size = int(size * 0.6)
    fg_wallet_left = (size - fg_wallet_size) // 2
    fg_wallet_top = int(size * 0.3)
    fg_wallet_height = int(fg_wallet_size * 0.6)
    
    # Wallet body
    fg_draw.rounded_rectangle([fg_wallet_left, fg_wallet_top, 
                              fg_wallet_left + fg_wallet_size, fg_wallet_top + fg_wallet_height],
                             radius=30, fill=(30, 41, 59, 255))
    
    # Wallet flap
    flap_h = int(fg_wallet_height * 0.3)
    fg_draw.rounded_rectangle([fg_wallet_left, fg_wallet_top, 
                              fg_wallet_left + fg_wallet_size, fg_wallet_top + flap_h],
                             radius=30, fill=(71, 85, 105, 255))
    
    # Large dollar sign in center
    dollar_center_x = size // 2
    dollar_center_y = fg_wallet_top + int(fg_wallet_height * 0.65)
    dollar_bg_radius = int(size * 0.08)
    
    fg_draw.ellipse([dollar_center_x - dollar_bg_radius, dollar_center_y - dollar_bg_radius,
                    dollar_center_x + dollar_bg_radius, dollar_center_y + dollar_bg_radius],
                   fill=(245, 158, 11, 255))
    
    try:
        big_font_size = int(dollar_bg_radius * 1.6)
        big_font = ImageFont.truetype("arial.ttf", big_font_size)
    except:
        try:
            big_font = ImageFont.truetype("/System/Library/Fonts/Arial.ttf", int(dollar_bg_radius * 1.6))
        except:
            big_font = ImageFont.load_default()
    
    fg_draw.text((dollar_center_x, dollar_center_y), "$", font=big_font, 
                fill=(255, 255, 255, 255), anchor="mm")
    
    # Save foreground icon
    fg_img.save('assets/icons/app_icon_foreground.png', 'PNG')
    print("Created app_icon_foreground.png")
    
    print("App icons created successfully!")
    print("Run 'flutter pub get' then 'flutter pub run flutter_launcher_icons:main' to generate platform icons")

if __name__ == "__main__":
    create_app_icon()
