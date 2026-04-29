#!/usr/bin/env node

/**
 * QR Code Generator for Survey App
 * 
 * Usage:
 *   node generate-qr.js "https://your-project-id.web.app"
 *   or
 *   npm run generate:qr -- "https://your-project-id.web.app"
 */

const QRCode = require('qrcode');
const fs = require('fs');
const path = require('path');

const url = process.argv[2];

if (!url) {
    console.error('❌ Please provide a URL as an argument');
    console.error('');
    console.error('Usage: node generate-qr.js "https://your-project-id.web.app"');
    console.error('');
    console.error('Examples:');
    console.error('  node generate-qr.js "https://my-survey-app.web.app"');
    console.error('  npm run generate:qr -- "https://my-survey-app.web.app"');
    process.exit(1);
}

// Validate URL
try {
    new URL(url);
} catch (_) {
    console.error('❌ Invalid URL provided');
    console.error('Make sure your URL starts with http:// or https://');
    process.exit(1);
}

const timestamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, -5);
const filename = `qr-code-${timestamp}.png`;
const filepath = path.join(process.cwd(), filename);

console.log('🔄 Generating QR Code...');
console.log(`📍 URL: ${url}`);
console.log(`💾 Saving to: ${filename}`);
console.log('');

QRCode.toFile(filepath, url, {
    errorCorrectionLevel: 'H',
    type: 'image/png',
    width: 300,
    margin: 2,
    color: {
        dark: '#000000',
        light: '#ffffff'
    }
}, (err) => {
    if (err) {
        console.error('❌ Error generating QR code:', err.message);
        process.exit(1);
    }
    
    const fileSize = fs.statSync(filepath).size;
    
    console.log('✅ QR Code Generated Successfully!');
    console.log('');
    console.log('📋 Details:');
    console.log(`  File: ${filename}`);
    console.log(`  Size: ${(fileSize / 1024).toFixed(2)} KB`);
    console.log(`  Path: ${filepath}`);
    console.log('');
    console.log('🎯 Next Steps:');
    console.log('  1. Print the QR code');
    console.log('  2. Share it on social media or email');
    console.log('  3. Users can scan it to access your Survey App');
    console.log('');
    console.log('💡 Pro Tips:');
    console.log('  • Minimum print size: 2cm × 2cm');
    console.log('  • Test scan before mass distribution');
    console.log('  • Use a short URL for easier scanning');
    console.log('');
});
