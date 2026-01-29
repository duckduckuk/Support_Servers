#!/usr/bin/env python3
import os
import sys

def create_file(path, content):
    """Helper to create a file with specific content."""
    # Ensure directory exists
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content.strip())
    print(f"Created: {path}")

def main():
    base_dir = os.getcwd()
    
    # ---------------------------------------------------------
    # 1. TEMPLATES: The Reusable Components & Layouts
    # ---------------------------------------------------------
    
    # Main Layout (Base Template)
    # Includes Tailwind CDN for immediate usage and links custom theme.css
    base_html = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{% block title %}My Python Site{% endblock %}</title>
    
    <!-- Tailwind CSS (CDN for Development) -->
    <script src="https://cdn.tailwindcss.com"></script>
    
    <!-- Custom Theme CSS -->
    <link rel="stylesheet" href="/static/css/theme.css">
</head>
<body class="bg-gray-50 text-gray-800 flex flex-col min-h-screen">

    <!-- Header & Nav Component -->
    {% include 'components/header.html' %}

    <!-- Main Content Area -->
    <main class="flex-grow container mx-auto px-4 py-8">
        {% block content %}{% endblock %}
    </main>

    <!-- Footer Component -->
    {% include 'components/footer.html' %}

</body>
</html>
"""

    # Homepage Template
    home_html = """
{% extends 'base.html' %}

{% block title %}Home | My Python Site{% endblock %}

{% block content %}
    <!-- Hero Component -->
    {% include 'components/hero.html' %}

    <section class="mt-12 grid grid-cols-1 md:grid-cols-3 gap-6">
        <div class="bg-white p-6 rounded-lg shadow-md">
            <h3 class="text-xl font-bold mb-2 text-primary">Fast</h3>
            <p>Built with Python and compiled to static HTML for speed.</p>
        </div>
        <div class="bg-white p-6 rounded-lg shadow-md">
            <h3 class="text-xl font-bold mb-2 text-primary">Responsive</h3>
            <p>Mobile-first design using Tailwind CSS utility classes.</p>
        </div>
        <div class="bg-white p-6 rounded-lg shadow-md">
            <h3 class="text-xl font-bold mb-2 text-primary">Modular</h3>
            <p>Reusable components make maintenance a breeze.</p>
        </div>
    </section>
{% endblock %}
"""

    # Example Sub-page (About)
    about_html = """
{% extends 'base.html' %}

{% block title %}About Us{% endblock %}

{% block content %}
    <div class="max-w-2xl mx-auto">
        <h1 class="text-4xl font-bold mb-6 text-gray-900">About Our Project</h1>
        <div class="prose lg:prose-xl">
            <p class="mb-4">
                This page is generated from <code>templates/pages/about.html</code>.
            </p>
            <p class="mb-4">
                When you run <code>build.py</code>, this file is compiled into a directory structure 
                at <code>./about/index.html</code>, making the URL simply <code>/about/</code>.
            </p>
            <a href="/" class="text-primary hover:underline">&larr; Back Home</a>
        </div>
    </div>
{% endblock %}
"""

    # ---------------------------------------------------------
    # 2. COMPONENTS: Reusable Parts
    # ---------------------------------------------------------

    header_html = """
<header class="bg-white shadow-sm sticky top-0 z-50">
    <div class="container mx-auto px-4">
        {% include 'components/nav.html' %}
    </div>
</header>
"""

    nav_html = """
<nav class="flex items-center justify-between h-16">
    <!-- Logo -->
    <a href="/" class="text-2xl font-bold text-primary tracking-tighter">
        Py<span class="text-gray-900">Site</span>
    </a>

    <!-- Navigation Links -->
    <div class="hidden md:flex space-x-8">
        <a href="/" class="text-gray-600 hover:text-primary transition-colors">Home</a>
        <a href="/about/" class="text-gray-600 hover:text-primary transition-colors">About</a>
        <a href="#" class="text-gray-600 hover:text-primary transition-colors">Services</a>
        <a href="#" class="text-gray-600 hover:text-primary transition-colors">Contact</a>
    </div>

    <!-- Mobile Menu Button (Visual Only for Demo) -->
    <button class="md:hidden text-gray-600 focus:outline-none">
        <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16"></path></svg>
    </button>
</nav>
"""

    hero_html = """
<div class="relative bg-gray-900 rounded-3xl overflow-hidden shadow-2xl">
    <div class="absolute inset-0">
        <img class="w-full h-full object-cover opacity-30" src="https://images.unsplash.com/photo-1550745165-9bc0b252726f?ixlib=rb-4.0.3&auto=format&fit=crop&w=2070&q=80" alt="Tech Background">
    </div>
    <div class="relative px-6 py-16 sm:px-12 sm:py-24 text-center">
        <h1 class="text-4xl sm:text-6xl font-extrabold text-white tracking-tight mb-6">
            Build Faster with Python
        </h1>
        <p class="text-lg sm:text-xl text-gray-300 max-w-2xl mx-auto mb-8">
            This is a reusable Hero component. It's defined in one place but can be included anywhere.
        </p>
        <div class="flex justify-center gap-4">
            <a href="/about/" class="bg-primary hover:bg-opacity-90 text-white px-8 py-3 rounded-full font-semibold transition-all transform hover:scale-105">
                Get Started
            </a>
            <a href="#" class="bg-white bg-opacity-10 backdrop-filter backdrop-blur-sm hover:bg-opacity-20 text-white px-8 py-3 rounded-full font-semibold transition-all">
                Learn More
            </a>
        </div>
    </div>
</div>
"""

    footer_html = """
<footer class="bg-gray-900 text-white mt-auto">
    <div class="container mx-auto px-4 py-8">
        <div class="flex flex-col md:flex-row justify-between items-center">
            <div class="mb-4 md:mb-0">
                <p>&copy; 2024 My Python Site. All rights reserved.</p>
            </div>
            <div class="flex space-x-6">
                <a href="#" class="text-gray-400 hover:text-white transition-colors">Privacy</a>
                <a href="#" class="text-gray-400 hover:text-white transition-colors">Terms</a>
                <a href="#" class="text-gray-400 hover:text-white transition-colors">GitHub</a>
            </div>
        </div>
    </div>
</footer>
"""

    # ---------------------------------------------------------
    # 3. STATIC ASSETS: CSS
    # ---------------------------------------------------------

    theme_css = """
/* Custom Design Tokens & Overrides */
:root {
    --primary-color: #3B82F6; /* Tailwind Blue-500 */
    --secondary-color: #10B981;
}

/* Since we are using Tailwind, we keep this file minimal.
   Use this for specific custom classes or overrides.
*/

.text-primary {
    color: var(--primary-color);
}

.bg-primary {
    background-color: var(--primary-color);
}

/* Smooth scrolling for anchor links */
html {
    scroll-behavior: smooth;
}
"""

    # ---------------------------------------------------------
    # 4. PYTHON SCRIPTS: The Builder & Environment Setup
    # ---------------------------------------------------------

    requirements_txt = """
jinja2
"""

    # Shell script to specifically handle the "Externally Managed Environment" error
    setup_env_sh = """
#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status

VENV_NAME="venv"

echo "------------------------------------------------------------------"
echo "🔧 Setting up Virtual Environment to fix 'Externally Managed' error"
echo "------------------------------------------------------------------"

# 1. Attempt to create virtual environment
if ! python3 -m venv "$VENV_NAME"; then
    echo ""
    echo "❌ Error: Could not create virtual environment."
    echo "This often happens on Ubuntu if 'python3-venv' is missing."
    echo "Try running this command with sudo first:"
    echo ""
    echo "    sudo apt install python3-venv"
    echo ""
    exit 1
fi

# 2. Activate the venv
source "$VENV_NAME/bin/activate"

# 3. Install requirements
echo "📦 Installing dependencies (jinja2) inside the venv..."
pip install -r requirements.txt

echo ""
echo "✅ Setup complete!"
echo "------------------------------------------------------------------"
echo "To manage your site, run:"
echo ""
echo "    bash manage.sh"
echo "------------------------------------------------------------------"
"""

    # NEW: Management script for Stop/Run operations
    manage_sh = """
#!/bin/bash

PID_FILE=".server_pid"
LOG_FILE="server.log"

show_menu() {
    echo "---------------------------------------"
    echo "  Python Static Site Manager"
    echo "---------------------------------------"
    echo "1. Stop the site"
    echo "2. Build & Run the site"
    echo "3. Exit"
    echo -n "Select an option [1-3]: "
}

stop_site() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p $PID > /dev/null 2>&1; then
            echo "Stopping server with PID: $PID..."
            kill $PID
            rm "$PID_FILE"
            echo "✅ Site stopped."
        else
            echo "⚠️  PID file found ($PID) but process is not running. Cleaning up."
            rm "$PID_FILE"
        fi
    else
        echo "⚠️  No active server found (no .server_pid file)."
        echo "If you started it manually, you'll need to kill it manually."
    fi
}

build_and_run() {
    # 1. Activate venv
    if [ -d "venv" ]; then
        source venv/bin/activate
    else
        echo "❌ Virtual environment not found. Run 'bash setup_env.sh' first."
        return
    fi

    # 2. Build
    echo "🔨 Building site..."
    python build.py

    # 3. Ask for Port
    read -p "Enter port to run on [8000]: " PORT
    PORT=${PORT:-8000}

    # 4. Check for existing lock
    if [ -f "$PID_FILE" ]; then
        echo "⚠️  It seems the server is already running (PID file exists)."
        echo "Please stop it first (Option 1) or delete $PID_FILE if it's stale."
        return
    fi

    # 5. Run in background
    echo "🚀 Starting server on port $PORT..."
    nohup python3 -m http.server $PORT --directory . > "$LOG_FILE" 2>&1 &
    
    SERVER_PID=$!
    echo $SERVER_PID > "$PID_FILE"
    
    echo "✅ Site is live! (PID: $SERVER_PID)"
    echo "   URL: http://localhost:$PORT"
    echo "   Logs: $LOG_FILE"
}

show_menu
read OPTION

case $OPTION in
    1) stop_site ;;
    2) build_and_run ;;
    3) exit 0 ;;
    *) echo "Invalid option." ;;
esac
"""

    build_py = """
import os
import shutil
from jinja2 import Environment, FileSystemLoader

# Configuration
TEMPLATE_DIR = 'templates'
OUTPUT_DIR = '.'  # Root directory as per request
STATIC_DIR = 'static'
PAGES_DIR = 'pages' # Subfolder in templates for sub-pages

def build():
    # 1. Setup Jinja2 Environment
    env = Environment(loader=FileSystemLoader(TEMPLATE_DIR))
    
    print("🔨 Starting build process...")

    # 2. Build Homepage (Root index.html)
    try:
        template = env.get_template('home.html')
        output_path = os.path.join(OUTPUT_DIR, 'index.html')
        with open(output_path, 'w', encoding='utf-8') as f:
            f.write(template.render())
        print(f"✅ Generated: index.html")
    except Exception as e:
        print(f"❌ Error generating home: {e}")

    # 3. Build Sub-pages
    # Scans templates/pages/*.html and creates folder/index.html for each
    pages_path = os.path.join(TEMPLATE_DIR, PAGES_DIR)
    if os.path.exists(pages_path):
        for filename in os.listdir(pages_path):
            if filename.endswith('.html'):
                slug = filename[:-5] # remove .html
                
                # Create directory for the page (e.g., ./about/)
                page_dir = os.path.join(OUTPUT_DIR, slug)
                os.makedirs(page_dir, exist_ok=True)
                
                # Render template
                template = env.get_template(os.path.join(PAGES_DIR, filename).replace('\\\\', '/'))
                output_path = os.path.join(page_dir, 'index.html')
                
                with open(output_path, 'w', encoding='utf-8') as f:
                    f.write(template.render(page_slug=slug))
                print(f"✅ Generated: {slug}/index.html")

    print("\\n🎉 Build complete! Open index.html to view your site.")

if __name__ == "__main__":
    build()
"""

    # ---------------------------------------------------------
    # WRITE FILES
    # ---------------------------------------------------------
    
    files_to_create = {
        'templates/base.html': base_html,
        'templates/home.html': home_html,
        'templates/pages/about.html': about_html,
        'templates/components/header.html': header_html,
        'templates/components/nav.html': nav_html,
        'templates/components/hero.html': hero_html,
        'templates/components/footer.html': footer_html,
        'static/css/theme.css': theme_css,
        'requirements.txt': requirements_txt,
        'setup_env.sh': setup_env_sh,
        'manage.sh': manage_sh,  # Added the management script
        'build.py': build_py
    }

    print("🚀 Initializing Python Web Project Structure...\n")

    for path, content in files_to_create.items():
        create_file(os.path.join(base_dir, path), content)

    print("\n-------------------------------------------------------")
    print("✅ Project setup complete!")
    print("-------------------------------------------------------")
    print("NEXT STEPS:")
    print("1. Initialize environment (Runs 'python3 -m venv' for you):")
    print("   bash setup_env.sh")
    print("2. Manage your site (Stop / Build & Run):")
    print("   bash manage.sh")
    print("-------------------------------------------------------")

if __name__ == "__main__":
    main()
