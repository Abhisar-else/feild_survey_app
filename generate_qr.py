#!/usr/bin/env python3
"""
QR Code Generator for Survey App
Install: pip install qrcode[pil]
Usage: python generate_qr.py "https://your-project-id.web.app"
"""

import sys
import qrcode
from datetime import datetime
from pathlib import Path
from urllib.parse import urlparse

def is_valid_url(url):
    """Validate if the provided string is a valid URL"""
    try:
        result = urlparse(url)
        return all([result.scheme, result.netloc])
    except:
        return False

def main():
    if len(sys.argv) < 2:
        print("❌ Please provide a URL as an argument")
        print("")
        print("Usage: python generate_qr.py \"https://your-project-id.web.app\"")
        print("")
        print("Examples:")
        print("  python generate_qr.py \"https://my-survey-app.web.app\"")
        print("  python generate_qr.py \"https://bit.ly/survey-app\"")
        sys.exit(1)
    
    url = sys.argv[1].strip()
    
    # Validate URL
    if not is_valid_url(url):
        print("❌ Invalid URL provided")
        print("Make sure your URL starts with http:// or https://")
        sys.exit(1)
    
    # Generate filename with timestamp
    timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    filename = f"qr-code-{timestamp}.png"
    filepath = Path.cwd() / filename
    
    print("🔄 Generating QR Code...")
    print(f"📍 URL: {url}")
    print(f"💾 Saving to: {filename}")
    print("")
    
    try:
        # Create QR code
        qr = qrcode.QRCode(
            version=1,
            error_correction=qrcode.constants.ERROR_CORRECT_H,
            box_size=10,
            border=2,
        )
        
        qr.add_data(url)
        qr.make(fit=True)
        
        # Create image
        img = qr.make_image(fill_color="black", back_color="white")
        
        # Save image
        img.save(str(filepath))
        
        # Get file size
        file_size_kb = filepath.stat().st_size / 1024
        
        print("✅ QR Code Generated Successfully!")
        print("")
        print("📋 Details:")
        print(f"  File: {filename}")
        print(f"  Size: {file_size_kb:.2f} KB")
        print(f"  Path: {filepath}")
        print("")
        print("🎯 Next Steps:")
        print("  1. Print the QR code")
        print("  2. Share it on social media or email")
        print("  3. Users can scan it to access your Survey App")
        print("")
        print("💡 Pro Tips:")
        print("  • Minimum print size: 2cm × 2cm")
        print("  • Test scan before mass distribution")
        print("  • Use a short URL for easier scanning")
        print("")
        
    except Exception as e:
        print(f"❌ Error generating QR code: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    main()
