# 📱 QR Code Generator Tools

Three different ways to generate QR codes for your Survey App!

---

## 🌐 Option 1: HTML Web Tool (Easiest)

**Perfect if you want instant results with no installation!**

### How to Use:
1. Open `qr-code-generator.html` in your browser
2. Paste your Firebase URL: `https://your-project-id.web.app`
3. Click "Generate QR Code"
4. Download, Print, or Copy URL

### Features:
✅ No installation needed  
✅ Download as PNG  
✅ Print directly  
✅ Copy URL to clipboard  
✅ Works offline  
✅ Beautiful UI  

### Quick Start:
```bash
# Just open the file in your browser
qr-code-generator.html
```

---

## 💻 Option 2: Node.js (Command Line)

**Perfect if you prefer command-line tools!**

### Installation:
```bash
npm install -g qrcode
```

Or in your project:
```bash
npm install qrcode
```

### How to Use:
```bash
node generate-qr.js "https://your-project-id.web.app"
```

### Output:
```
🔄 Generating QR Code...
📍 URL: https://your-project-id.web.app
💾 Saving to: qr-code-2026-04-29-103045.png

✅ QR Code Generated Successfully!

📋 Details:
  File: qr-code-2026-04-29-103045.png
  Size: 2.45 KB
  Path: /path/to/project/qr-code-2026-04-29-103045.png
```

### Examples:
```bash
# Generate from Firebase URL
node generate-qr.js "https://my-survey-app.web.app"

# Generate from shortened URL
node generate-qr.js "https://bit.ly/survey-app"

# Using npm script
npm run generate:qr -- "https://my-survey-app.web.app"
```

---

## 🐍 Option 3: Python (Recommended for Developers)

**Perfect if you already use Python!**

### Installation:
```bash
pip install qrcode[pil]
```

### How to Use:
```bash
python generate_qr.py "https://your-project-id.web.app"
```

### Output:
```
🔄 Generating QR Code...
📍 URL: https://your-project-id.web.app
💾 Saving to: qr-code-2026-04-29-103045.png

✅ QR Code Generated Successfully!

📋 Details:
  File: qr-code-2026-04-29-103045.png
  Size: 2.45 KB
  Path: /path/to/project/qr-code-2026-04-29-103045.png
```

### Examples:
```bash
# Generate from Firebase URL
python generate_qr.py "https://my-survey-app.web.app"

# Generate from shortened URL
python generate_qr.py "https://bit.ly/survey-app"
```

---

## 📊 Comparison Table

| Feature | HTML Tool | Node.js | Python |
|---------|-----------|---------|--------|
| Installation | ✅ None | ⚙️ npm | ⚙️ pip |
| Ease of Use | ⭐⭐⭐ Easy | ⭐⭐ Medium | ⭐⭐ Medium |
| Download | ✅ Yes | ✅ Yes | ✅ Yes |
| Print | ✅ Yes | ❌ No* | ❌ No* |
| Copy URL | ✅ Yes | ❌ No | ❌ No |
| Offline | ✅ Yes | ✅ Yes | ✅ Yes |

*Can print generated files separately

---

## 🚀 Recommended Workflow

### For Quick One-Time Generation:
```
1. Open qr-code-generator.html in browser
2. Paste your URL
3. Download QR code
4. Done! 🎉
```

### For Batch Generation:
```bash
# Generate multiple QR codes
node generate-qr.js "https://app1.web.app"
node generate-qr.js "https://app2.web.app"
node generate-qr.js "https://app3.web.app"

# Or use a script to automate
```

### For Developers:
```bash
# Add to your package.json scripts
"scripts": {
  "generate:qr": "node generate-qr.js"
}

# Then run:
npm run generate:qr -- "YOUR_URL"
```

---

## 🎨 QR Code Specifications

All generators create QR codes with these specs:

- **Size:** 300×300 pixels
- **Error Correction:** High (H - up to 30% damage recovery)
- **Format:** PNG image
- **Colors:** Black on white
- **Border:** 2 pixels margin

---

## 📏 Print Guidelines

### Recommended Print Size:
- **Small:** 2cm × 2cm (minimum for reliable scanning)
- **Medium:** 5cm × 5cm (recommended for posters)
- **Large:** 10cm × 10cm (best for posters/signage)

### Print Quality:
- Use high-quality printer (600+ DPI)
- Use white paper (good contrast)
- Test scan before mass printing
- Black ink only (no colors needed)

---

## 🔐 Security Tips

✅ **Do:**
- Generate QR codes for your own URLs only
- Keep your Firebase hosting URL secure
- Test QR codes before distribution
- Use HTTPS URLs only

❌ **Don't:**
- Share your Firebase project details
- Use QR codes for external URLs you don't control
- Generate QR codes with personally identifiable information

---

## 🐛 Troubleshooting

### "qrcode command not found"
```bash
# Install globally
npm install -g qrcode
```

### "ModuleNotFoundError: No module named 'qrcode'"
```bash
# Install Python package
pip install qrcode[pil]
```

### QR Code won't scan
- Increase print size (minimum 2cm × 2cm)
- Ensure good black/white contrast
- Check for smudges or damage
- Test with multiple phones
- Try different scanning apps

### HTML tool not working
- Use modern browser (Chrome, Firefox, Safari, Edge)
- Check internet connection (for CDN resources)
- Clear browser cache
- Try different browser

---

## 💡 Pro Tips

### Using Short URLs
Long URLs are harder to scan. Use a URL shortener:

```bash
# Shorten before generating QR code
https://your-project-id.web.app
↓
https://bit.ly/survey-app  ← Much shorter!

# Then generate QR code from short URL
```

### Create Branded QR Codes
Use online tools for branded QR codes:
- https://www.qrcode-monkey.com/
- https://qr-code-generator.com/
- Add your logo in the center
- Maintain high contrast

### Track QR Code Scans
Use URL parameters to track campaigns:

```bash
# Different QR codes for different channels
https://app.web.app?campaign=social
https://app.web.app?campaign=email
https://app.web.app?campaign=print

# View analytics in Firebase Console
```

---

## 📚 Additional Resources

- **QRCode.js**: https://davidshimjs.github.io/qrcodejs/
- **qrcode npm**: https://www.npmjs.com/package/qrcode
- **Python QRCode**: https://github.com/lincolnloop/python-qrcode
- **QR Code Standards**: https://en.wikipedia.org/wiki/QR_code

---

## 🎯 Next Steps

1. ✅ Choose your preferred tool
2. ✅ Have your Firebase URL ready
3. ✅ Generate QR code
4. ✅ Test scan on your phone
5. ✅ Download and share
6. ✅ Users scan → App opens! 🎉

---

## Questions?

For issues with:
- **HTML Tool**: Check browser console (F12)
- **Node.js**: Run with `--verbose` flag
- **Python**: Check `pip list` for qrcode installation

Enjoy! 🚀
