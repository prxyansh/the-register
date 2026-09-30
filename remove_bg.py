from PIL import Image

def extract_stencil(input_path, output_path):
    img = Image.open(input_path).convert("RGBA")
    data = img.getdata()
    
    new_data = []
    
    # We will turn the image into a pure stencil:
    # Only dark pixels (the drawing) are kept, everything else is 100% transparent.
    for item in data:
        r, g, b, a = item
        
        # Calculate brightness
        brightness = (r + g + b) / 3
        
        # If it's a dark pixel, it's part of the line art (keep it opaque)
        # Note: We can make it completely black or preserve original color
        if brightness < 130:
            # Keep the dark line art
            new_data.append((r, g, b, 255))
        else:
            # Everything else (cream, white borders, shadows) goes completely transparent
            new_data.append((255, 255, 255, 0))
            
    img.putdata(new_data)
    
    # Crop to just the drawing
    bbox = img.getbbox()
    if bbox:
        img = img.crop(bbox)
        
    # Add a comfortable amount of padding so Android doesn't clip it
    width, height = img.size
    padding = int(width * 0.3)
    new_img = Image.new("RGBA", (width + padding*2, height + padding*2), (255, 255, 255, 0))
    new_img.paste(img, (padding, padding))
    
    new_img.save(output_path, "PNG")

extract_stencil('assets/icon.jpg', 'assets/icon.png')
print("Extracted purely transparent stencil logo!")
