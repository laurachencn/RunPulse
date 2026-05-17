#!/usr/bin/env python3
"""Generate RunPulse app icons for iOS and watchOS."""

import os
import sys
from PIL import Image, ImageDraw

SIZE = 1024
BG_TOP = (255, 107, 107)    # #FF6B6B coral red
BG_BOTTOM = (78, 205, 196)   # #4ECDC4 teal
FG_COLOR = (255, 255, 255)   # white

def create_gradient_image():
    """Create 1024x1024 gradient background."""
    img = Image.new('RGB', (SIZE, SIZE))
    pixels = img.load()
    for y in range(SIZE):
        r = int(BG_TOP[0] + (BG_BOTTOM[0] - BG_TOP[0]) * y / SIZE)
        g = int(BG_TOP[1] + (BG_BOTTOM[1] - BG_TOP[1]) * y / SIZE)
        b = int(BG_TOP[2] + (BG_BOTTOM[2] - BG_TOP[2]) * y / SIZE)
        for x in range(SIZE):
            pixels[x, y] = (r, g, b)
    return img

def draw_heartbeat(draw):
    """Draw white EKG waveform centered on image."""
    # Waveform points (normalized 0-1), ~60% width, centered
    # P-QRS-T pattern: small bump, sharp spike, small bump
    points = [
        (0.20, 0.50),  # baseline start
        (0.25, 0.50),
        (0.28, 0.45),  # P wave
        (0.31, 0.50),
        (0.34, 0.50),
        (0.36, 0.52),  # Q dip
        (0.38, 0.20),  # R spike (peak)
        (0.40, 0.75),  # S dip
        (0.42, 0.50),
        (0.45, 0.50),
        (0.48, 0.42),  # T wave
        (0.52, 0.50),
        (0.55, 0.50),
        (0.60, 0.50),  # baseline end
        (0.65, 0.50),
        (0.70, 0.50),
        (0.75, 0.50),
        (0.80, 0.50),
    ]
    
    # Convert to pixel coordinates
    scaled = [(int(x * SIZE), int(y * SIZE)) for x, y in points]
    
    # Draw with thick white line
    draw.line(scaled, fill=FG_COLOR, width=12)

def generate_icon(output_path):
    """Generate a single icon."""
    img = create_gradient_image()
    draw = ImageDraw.Draw(img)
    draw_heartbeat(draw)
    img.save(output_path, 'PNG')
    print(f"Generated: {output_path}")

def main():
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    
    ios_path = os.path.join(base_dir, 'RunPulse', 'Resources', 'Assets.xcassets', 'AppIcon.appiconset', 'AppIcon-1024.png')
    watch_path = os.path.join(base_dir, 'RunPulseWatch', 'Resources', 'Assets.xcassets', 'AppIcon.appiconset', 'AppIcon-1024.png')
    
    os.makedirs(os.path.dirname(ios_path), exist_ok=True)
    os.makedirs(os.path.dirname(watch_path), exist_ok=True)
    
    generate_icon(ios_path)
    generate_icon(watch_path)
    print("Done!")

if __name__ == '__main__':
    main()
