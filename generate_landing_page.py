#!/usr/bin/env python3
"""
ClaudeMD Viewer Landing Page Generator
Generates the landing page and outputs to dist/index.html
"""
import os


def generate_html():
    """Generate the HTML content for the landing page"""
    html = """<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ClaudeMD Viewer — Natural Menu Bar Access</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Fraunces:wght@400;600;700&family=DM+Sans:wght@400;500;700&display=swap" rel="stylesheet">
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        :root {
            --orange: #ff6b35;
            --pink: #ff85a8;
            --red: #ff4757;
            --peach: #ffb088;
            --dark-bg: #0f0f1e;
            --dark-card: #1a1a2e;
            --dark-border: #2a2a40;
            --text-primary: #fff5f5;
            --text-secondary: #b8a8b0;
            --shadow: rgba(255, 107, 53, 0.2);
            --glow: rgba(255, 107, 53, 0.4);
        }

        body {
            font-family: 'DM Sans', sans-serif;
            background: var(--dark-bg);
            color: var(--text-primary);
            overflow: hidden;
            height: 100vh;
            position: relative;
        }

        /* Organic background blobs */
        .bg-blob {
            position: absolute;
            border-radius: 40% 60% 70% 30% / 40% 50% 60% 50%;
            opacity: 0.15;
            filter: blur(80px);
            animation: float 25s ease-in-out infinite;
        }

        .blob-1 {
            width: 700px;
            height: 700px;
            background: linear-gradient(135deg, var(--orange), var(--pink));
            top: -250px;
            left: -150px;
            animation-delay: 0s;
        }

        .blob-2 {
            width: 600px;
            height: 600px;
            background: linear-gradient(225deg, var(--coral), var(--pink));
            bottom: -200px;
            right: -100px;
            animation-delay: 8s;
        }

        .blob-3 {
            width: 500px;
            height: 500px;
            background: linear-gradient(45deg, var(--orange), var(--coral));
            top: 40%;
            right: 5%;
            animation-delay: 16s;
        }

        @keyframes float {
            0%, 100% {
                transform: translate(0, 0) rotate(0deg);
            }
            33% {
                transform: translate(40px, -40px) rotate(8deg);
            }
            66% {
                transform: translate(-30px, 30px) rotate(-8deg);
            }
        }

        /* Language toggle */
        .lang-toggle {
            position: fixed;
            top: 24px;
            right: 24px;
            z-index: 100;
            background: var(--dark-card);
            backdrop-filter: blur(10px);
            border: 2px solid var(--dark-border);
            color: var(--text-primary);
            padding: 10px 20px;
            border-radius: 50px;
            font-size: 13px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
            box-shadow: 0 4px 20px rgba(0, 0, 0, 0.3);
        }

        .lang-toggle:hover {
            transform: translateY(-2px);
            border-color: var(--orange);
            box-shadow: 0 6px 24px var(--glow);
        }

        /* Container */
        .container {
            height: 100vh;
            padding: 32px 48px;
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
            gap: 32px;
            max-width: 1400px;
            margin: 0 auto;
            position: relative;
            z-index: 1;
        }

        /* Logo */
        .logo {
            display: flex;
            align-items: center;
            gap: 12px;
            animation: fadeIn 0.6s ease both;
        }

        .logo-icon {
            width: 40px;
            height: 40px;
            filter: drop-shadow(0 4px 12px var(--glow));
            animation: floatSlow 3s ease-in-out infinite;
        }

        .logo-icon svg {
            width: 100%;
            height: 100%;
            stroke: var(--orange);
        }

        @keyframes floatSlow {
            0%, 100% { transform: translateY(0); }
            50% { transform: translateY(-8px); }
        }

        .logo-text {
            font-family: 'Fraunces', serif;
            font-size: 28px;
            font-weight: 700;
            color: var(--text-primary);
        }

        /* Hero */
        .hero {
            text-align: center;
            max-width: 900px;
            animation: fadeIn 0.8s ease 0.2s both;
        }

        .hero-title {
            font-family: 'Fraunces', serif;
            font-size: clamp(42px, 7vw, 78px);
            font-weight: 700;
            line-height: 1.15;
            margin-bottom: 16px;
            color: var(--text-primary);
        }

        .hero-title .highlight {
            background: linear-gradient(135deg, var(--pink), var(--orange));
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
            position: relative;
            display: inline-block;
            filter: drop-shadow(0 0 20px var(--glow));
        }

        .hero-subtitle {
            font-size: clamp(16px, 1.8vw, 20px);
            color: var(--text-secondary);
            font-weight: 500;
            margin-bottom: 28px;
            line-height: 1.6;
        }

        /* App Preview */
        .app-preview {
            margin: 20px 0;
            animation: fadeIn 1s ease 0.3s both;
        }

        .mockup {
            background: var(--dark-card);
            border: 2px solid var(--dark-border);
            border-radius: 16px;
            padding: 20px;
            box-shadow: 0 12px 40px rgba(0, 0, 0, 0.5),
                        0 0 60px var(--glow);
            max-width: 380px;
            animation: floatSlow 4s ease-in-out infinite;
        }

        .mockup-header {
            display: flex;
            align-items: center;
            gap: 8px;
            padding-bottom: 12px;
            border-bottom: 1px solid var(--dark-border);
            margin-bottom: 12px;
        }

        .mockup-icon {
            width: 18px;
            height: 18px;
        }

        .mockup-icon svg {
            width: 100%;
            height: 100%;
            stroke: var(--orange);
        }

        .mockup-title {
            font-size: 13px;
            font-weight: 600;
            color: var(--text-primary);
        }

        .mockup-item {
            background: rgba(0, 217, 192, 0.08);
            border: 1px solid rgba(0, 217, 192, 0.2);
            border-radius: 8px;
            padding: 10px 12px;
            margin-bottom: 8px;
            display: flex;
            align-items: center;
            gap: 10px;
            transition: all 0.3s;
        }

        .mockup-item:hover {
            background: rgba(0, 217, 192, 0.15);
            transform: translateX(4px);
        }

        .mockup-item-icon {
            width: 18px;
            height: 18px;
            flex-shrink: 0;
        }

        .mockup-item-icon svg {
            width: 100%;
            height: 100%;
            stroke: var(--pink);
        }

        .mockup-item-text {
            font-size: 13px;
            color: var(--text-secondary);
        }

        .mockup-shortcut {
            margin-left: auto;
            font-size: 12px;
            color: var(--pink);
            font-weight: 600;
        }

        /* CTA Buttons */
        .cta-group {
            display: flex;
            gap: 16px;
            justify-content: center;
            flex-wrap: wrap;
            animation: fadeIn 1s ease 0.5s both;
        }

        .btn {
            padding: 14px 36px;
            font-family: 'DM Sans', sans-serif;
            font-size: 15px;
            font-weight: 700;
            text-decoration: none;
            border-radius: 50px;
            transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
            box-shadow: 0 4px 16px rgba(0, 0, 0, 0.3);
            position: relative;
            overflow: hidden;
        }

        .btn::before {
            content: '';
            position: absolute;
            top: 50%;
            left: 50%;
            width: 0;
            height: 0;
            border-radius: 50%;
            background: rgba(255, 255, 255, 0.2);
            transform: translate(-50%, -50%);
            transition: width 0.6s, height 0.6s;
        }

        .btn:hover::before {
            width: 300px;
            height: 300px;
        }

        .btn-primary {
            background: linear-gradient(135deg, var(--pink), var(--orange));
            color: var(--dark-bg);
        }

        .btn-primary:hover {
            transform: translateY(-3px);
            box-shadow: 0 8px 28px var(--glow);
        }

        .btn-secondary {
            background: transparent;
            color: var(--text-primary);
            border: 2px solid var(--dark-border);
        }

        .btn-secondary:hover {
            transform: translateY(-3px);
            border-color: var(--orange);
            box-shadow: 0 8px 24px var(--glow);
        }

        /* Floating Features */
        .features {
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: 16px;
            width: 100%;
            max-width: 1100px;
            animation: fadeIn 1.2s ease 0.7s both;
        }

        .feature {
            background: var(--dark-card);
            backdrop-filter: blur(10px);
            padding: 24px 20px;
            border-radius: 20px;
            border: 2px solid var(--dark-border);
            transition: all 0.4s cubic-bezier(0.4, 0, 0.2, 1);
            animation: floatUp 0.8s ease both;
            box-shadow: 0 8px 24px rgba(0, 0, 0, 0.3);
        }

        .feature:nth-child(1) {
            animation-delay: 0.8s;
            transform: translateY(0) rotate(-1deg);
        }

        .feature:nth-child(2) {
            animation-delay: 0.9s;
            transform: translateY(0) rotate(1deg);
        }

        .feature:nth-child(3) {
            animation-delay: 1s;
            transform: translateY(0) rotate(-0.5deg);
        }

        .feature:nth-child(4) {
            animation-delay: 1.1s;
            transform: translateY(0) rotate(0.5deg);
        }

        @keyframes floatUp {
            from {
                opacity: 0;
                transform: translateY(40px);
            }
            to {
                opacity: 1;
            }
        }

        .feature:hover {
            transform: translateY(-8px) scale(1.03) rotate(0deg);
            box-shadow: 0 16px 48px rgba(0, 217, 192, 0.2);
            border-color: var(--orange);
        }

        .feature-icon {
            width: 40px;
            height: 40px;
            margin-bottom: 12px;
            display: inline-block;
            filter: drop-shadow(0 2px 8px var(--glow));
            animation: floatSlow 3s ease-in-out infinite;
        }

        .feature-icon svg {
            width: 100%;
            height: 100%;
            stroke: var(--orange);
        }

        .feature:nth-child(2) .feature-icon {
            animation-delay: 0.5s;
        }

        .feature:nth-child(3) .feature-icon {
            animation-delay: 1s;
        }

        .feature:nth-child(4) .feature-icon {
            animation-delay: 1.5s;
        }

        .feature-title {
            font-family: 'Fraunces', serif;
            font-size: 17px;
            font-weight: 600;
            margin-bottom: 8px;
            color: var(--text-primary);
        }

        .feature-desc {
            font-size: 14px;
            line-height: 1.6;
            color: var(--text-secondary);
        }

        /* Footer */
        .footer {
            position: absolute;
            bottom: 16px;
            left: 50%;
            transform: translateX(-50%);
            font-size: 12px;
            color: var(--text-secondary);
            opacity: 0.6;
            animation: fadeIn 1.4s ease 1.2s both;
        }

        @keyframes fadeIn {
            from {
                opacity: 0;
            }
            to {
                opacity: 1;
            }
        }

        /* Hide Japanese by default */
        .lang-ja {
            display: none;
        }

        /* Mobile responsive */
        @media (max-width: 1024px) {
            .features {
                grid-template-columns: repeat(2, 1fr);
                gap: 14px;
            }
        }

        @media (max-width: 768px) {
            .container {
                padding: 24px 20px;
                gap: 24px;
            }

            .hero-title {
                font-size: 38px;
            }

            .mockup {
                max-width: 100%;
            }

            .features {
                grid-template-columns: 1fr;
                gap: 12px;
            }

            .feature {
                padding: 18px 16px;
            }

            .blob-1, .blob-2, .blob-3 {
                opacity: 0.08;
            }
        }
    </style>
</head>
<body>
    <!-- Background blobs -->
    <div class="bg-blob blob-1"></div>
    <div class="bg-blob blob-2"></div>
    <div class="bg-blob blob-3"></div>

    <!-- Language toggle -->
    <button class="lang-toggle" onclick="toggleLang()">
        <span class="lang-btn-en">🇯🇵 日本語</span>
        <span class="lang-btn-ja" style="display: none;">🇺🇸 English</span>
    </button>

    <div class="container">
        <!-- Logo -->
        <div class="logo">
            <div class="logo-icon">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/>
                    <polyline points="14 2 14 8 20 8"/>
                    <line x1="16" y1="13" x2="8" y2="13"/>
                    <line x1="16" y1="17" x2="8" y2="17"/>
                    <polyline points="10 9 9 9 8 9"/>
                </svg>
            </div>
            <div class="logo-text">ClaudeMD Viewer</div>
        </div>

        <!-- Hero -->
        <div class="hero">
            <h1 class="hero-title">
                <span class="lang-en">Your <span class="highlight">CLAUDE.md</span><br>always within reach</span>
                <span class="lang-ja"><span class="highlight">CLAUDE.md</span>に<br>いつでもアクセス</span>
            </h1>

            <p class="hero-subtitle">
                <span class="lang-en">macOS menu bar app for instant access to all your project docs</span>
                <span class="lang-ja">macOSメニューバーから全てのプロジェクトドキュメントに即座にアクセス</span>
            </p>
        </div>

        <!-- App Preview Mockup -->
        <div class="app-preview">
            <div class="mockup">
                <div class="mockup-header">
                    <span class="mockup-icon">
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/>
                            <polyline points="14 2 14 8 20 8"/>
                        </svg>
                    </span>
                    <span class="mockup-title">ClaudeMD Viewer</span>
                </div>
                <div class="mockup-item">
                    <span class="mockup-item-icon">
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <path d="M22 19a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5l2 3h9a2 2 0 0 1 2 2z"/>
                        </svg>
                    </span>
                    <span class="mockup-item-text lang-en">my-project/CLAUDE.md</span>
                    <span class="mockup-item-text lang-ja">マイプロジェクト/CLAUDE.md</span>
                </div>
                <div class="mockup-item">
                    <span class="mockup-item-icon">
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <path d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71"/>
                            <path d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71"/>
                        </svg>
                    </span>
                    <span class="mockup-item-text lang-en">github/repo/CLAUDE.md</span>
                    <span class="mockup-item-text lang-ja">github/リポジトリ/CLAUDE.md</span>
                </div>
                <div class="mockup-item">
                    <span class="mockup-item-icon">
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <rect x="2" y="4" width="20" height="16" rx="2"/>
                            <path d="M6 8h.01M10 8h.01M14 8h.01M18 8h.01M8 12h.01M12 12h.01M16 12h.01M7 16h10"/>
                        </svg>
                    </span>
                    <span class="mockup-item-text lang-en">Quick access anywhere</span>
                    <span class="mockup-item-text lang-ja">どこからでも素早くアクセス</span>
                    <span class="mockup-shortcut">⌘⇧M</span>
                </div>
            </div>
        </div>

        <!-- CTA -->
        <div class="cta-group">
            <a href="https://github.com/taroutcy/claudemd-viewer/releases/latest/download/ClaudeMDViewer.dmg" class="btn btn-primary">
                <span class="lang-en">Download for macOS</span>
                <span class="lang-ja">macOS版をダウンロード</span>
            </a>
            <a href="https://github.com/taroutcy/claudemd-viewer" class="btn btn-secondary">
                GitHub
            </a>
        </div>

        <!-- Features -->
        <div class="features">
            <div class="feature">
                <div class="feature-icon">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M22 19a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5l2 3h9a2 2 0 0 1 2 2z"/>
                    </svg>
                </div>
                <h3 class="feature-title">
                    <span class="lang-en">Local Scan</span>
                    <span class="lang-ja">ローカルスキャン</span>
                </h3>
                <p class="feature-desc">
                    <span class="lang-en">Auto-detect CLAUDE.md files</span>
                    <span class="lang-ja">CLAUDE.mdを自動検出</span>
                </p>
            </div>

            <div class="feature">
                <div class="feature-icon">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71"/>
                        <path d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71"/>
                    </svg>
                </div>
                <h3 class="feature-title">
                    <span class="lang-en">GitHub Sync</span>
                    <span class="lang-ja">GitHub連携</span>
                </h3>
                <p class="feature-desc">
                    <span class="lang-en">Fetch from repositories</span>
                    <span class="lang-ja">リポジトリから取得</span>
                </p>
            </div>

            <div class="feature">
                <div class="feature-icon">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <rect x="2" y="4" width="20" height="16" rx="2"/>
                        <path d="M6 8h.01M10 8h.01M14 8h.01M18 8h.01M8 12h.01M12 12h.01M16 12h.01M7 16h10"/>
                    </svg>
                </div>
                <h3 class="feature-title">
                    <span class="lang-en">⌘⇧M Shortcut</span>
                    <span class="lang-ja">⌘⇧M ショートカット</span>
                </h3>
                <p class="feature-desc">
                    <span class="lang-en">Instant access</span>
                    <span class="lang-ja">即座にアクセス</span>
                </p>
            </div>

            <div class="feature">
                <div class="feature-icon">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/>
                    </svg>
                </div>
                <h3 class="feature-title">
                    <span class="lang-en">Free & Open</span>
                    <span class="lang-ja">完全無料</span>
                </h3>
                <p class="feature-desc">
                    <span class="lang-en">MIT license</span>
                    <span class="lang-ja">MITライセンス</span>
                </p>
            </div>
        </div>

        <!-- Footer -->
        <div class="footer">
            © 2026 ClaudeMD Viewer
        </div>
    </div>

    <script>
        let currentLang = 'en';

        function toggleLang() {
            const enElements = document.querySelectorAll('.lang-en');
            const jaElements = document.querySelectorAll('.lang-ja');
            const enBtn = document.querySelector('.lang-btn-en');
            const jaBtn = document.querySelector('.lang-btn-ja');

            if (currentLang === 'en') {
                // Switch to Japanese
                enElements.forEach(el => {
                    el.style.setProperty('display', 'none', 'important');
                });
                jaElements.forEach(el => {
                    el.style.setProperty('display', 'inline', 'important');
                });
                enBtn.style.display = 'none';
                jaBtn.style.display = 'inline';
                currentLang = 'ja';
            } else {
                // Switch to English
                enElements.forEach(el => {
                    el.style.setProperty('display', 'inline', 'important');
                });
                jaElements.forEach(el => {
                    el.style.setProperty('display', 'none', 'important');
                });
                enBtn.style.display = 'inline';
                jaBtn.style.display = 'none';
                currentLang = 'en';
            }
        }
    </script>
</body>
</html>"""

    return html


def main():
    """Generate the landing page HTML file in dist directory"""
    # Create dist directory if it doesn't exist
    os.makedirs('dist', exist_ok=True)

    # Generate HTML content
    html_content = generate_html()

    # Save to dist/index.html
    output_file = "dist/index.html"
    with open(output_file, "w", encoding="utf-8") as f:
        f.write(html_content)

    print(f"Generate Successful")


if __name__ == "__main__":
    main()
