from flask import Flask, request, send_file
from playwright.sync_api import sync_playwright
import io

app = Flask(__name__)

@app.route('/capture')
def capture():
    url = request.args.get('url')
    if not url:
        return {'error': 'url requerida'}, 400
    with sync_playwright() as p:
        browser = p.chromium.launch()
        page = browser.new_page()
        try:
            page.goto(url, timeout=15000)
            screenshot_bytes = page.screenshot(full_page=True)
        except Exception as e:
            browser.close()
            return {'error': str(e)}, 500
        browser.close()
    return send_file(io.BytesIO(screenshot_bytes), mimetype='image/png')

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)