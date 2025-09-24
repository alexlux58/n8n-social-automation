#!/bin/bash

# n8n Social Automation - Quick Start Script
# This script provides a simple way to start the n8n Social Automation system

set -e

echo "🚀 n8n Social Automation - Quick Start"
echo "======================================"

# Check if Python 3 is available
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is required but not found. Please install Python 3."
    exit 1
fi

# Check if we're in the right directory
if [ ! -f "scripts/manage.py" ]; then
    echo "❌ Please run this script from the n8n-social-automation directory"
    exit 1
fi

# Run the setup first
echo "🔧 Setting up dependencies..."
python3 scripts/manage.py setup

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Setup completed successfully!"
    echo ""
    echo "📝 Next steps:"
    echo "1. Edit .env file with your API keys:"
    echo "   nano .env"
    echo ""
    echo "2. Start the services:"
    echo "   python3 scripts/manage.py start"
    echo ""
    echo "3. Open n8n UI:"
    echo "   http://localhost:5678"
    echo ""
    echo "4. Import workflow.json into n8n"
    echo ""
    echo "For more help, see README.md"
else
    echo "❌ Setup failed. Please check the errors above and try again."
    exit 1
fi
