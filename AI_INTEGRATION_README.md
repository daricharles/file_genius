# FileGenius AI Integration

## 🚀 Overview

FileGenius now includes powerful AI capabilities for intelligent file analysis and interaction. The AI integration allows users to:

- **Analyze files** with intelligent insights and summaries
- **Ask questions** about file content and get instant answers
- **Generate summaries** of long documents
- **Get recommendations** based on file content

## ✨ Features

### 🤖 AI-Powered File Analysis
- **Document Analysis**: Get intelligent insights about PDF, DOCX, PPTX, and XLSX files
- **Content Summarization**: Generate concise summaries of long documents
- **Q&A Assistant**: Ask questions about your files and get instant answers
- **Smart Recommendations**: Get suggestions for further analysis

### 📁 Supported File Types
- **PDF** - Full text analysis and document insights
- **DOCX** - Word document content analysis
- **PPTX** - Presentation content and structure analysis
- **XLSX** - Spreadsheet data analysis and insights
- **TXT/MD** - Text file analysis and summarization
- **JSON/XML** - Data structure analysis
- **CSV** - Data analysis and pattern recognition

### 🎯 AI Chat Interface
- **Real-time Chat**: Interactive conversation with AI about your files
- **Quick Actions**: One-click analysis and summary generation
- **Markdown Support**: Rich formatting for AI responses
- **Context Awareness**: AI understands file context and metadata

## 🛠️ Setup Instructions

### 1. Get OpenAI API Key
1. Visit [OpenAI Platform](https://platform.openai.com/api-keys)
2. Create an account or sign in
3. Generate a new API key
4. Copy the API key (starts with `sk-`)

### 2. Configure API Key
You have two options to set your API key:

#### Option A: Environment File (Recommended)
1. Open the `.env` file in your project root
2. Replace `your_openai_api_key_here` with your actual API key:
   ```
   OPENAI_API_KEY=sk-your_actual_api_key_here
   ```

#### Option B: In-App Settings
1. Run the app
2. Click the "AI Settings" button in the sidebar
3. Enter your API key in the settings page
4. Click "Save API Key"

### 3. Test the Integration
1. Upload a supported file (PDF, DOCX, PPTX, etc.)
2. Click on the file to open it
3. The AI chat interface will appear on the right side
4. Try asking questions or use the quick action buttons

## 🎮 How to Use

### Basic Usage
1. **Upload a File**: Drag and drop or click to upload a supported file
2. **Open File**: Click on the file in the file list
3. **Start Chat**: The AI chat interface will appear automatically
4. **Ask Questions**: Type questions about your file content
5. **Use Quick Actions**: Click "Analyze" or "Summary" for instant insights

### Advanced Features
- **File Analysis**: Get comprehensive insights about document structure, key points, and important data
- **Content Summarization**: Generate concise summaries of long documents
- **Data Analysis**: For spreadsheets, get insights about data patterns and key metrics
- **Document Q&A**: Ask specific questions about any part of your document

### Example Questions
- "What is this document about?"
- "Summarize the main points"
- "What are the key findings?"
- "Extract important data or statistics"
- "What is the document structure?"
- "Identify patterns in the data"

## 🔧 Technical Details

### Architecture
- **AI Service**: Handles OpenAI API communication
- **File Content Extractor**: Extracts text from different file types
- **Chat Widget**: Interactive UI for AI conversations
- **Settings Management**: Secure API key storage

### Security
- API keys are stored securely using SharedPreferences
- Environment variables for development
- No API keys are logged or exposed in the UI

### Dependencies
- `dio`: HTTP client for API calls
- `flutter_markdown`: Markdown rendering for AI responses
- `shared_preferences`: Secure storage for API keys
- `flutter_dotenv`: Environment variable management

## 🚨 Troubleshooting

### Common Issues

#### "API key not configured"
- Make sure you've set your OpenAI API key in the settings
- Check that the `.env` file exists and contains the correct key
- Try setting the key through the in-app settings

#### "Failed to analyze file"
- Check your internet connection
- Verify your OpenAI API key is valid
- Ensure the file type is supported
- Check if you have sufficient OpenAI credits

#### "File type not supported"
- Only certain file types support AI analysis
- Supported types: PDF, DOCX, PPTX, XLSX, TXT, MD, JSON, XML, CSV
- For other file types, the AI chat will show a "not supported" message

### Getting Help
1. Check the console for error messages
2. Verify your API key is working on the OpenAI platform
3. Ensure you have sufficient API credits
4. Try with a different file to isolate the issue

## 🔮 Future Enhancements

### Planned Features
- **Speech-to-Text**: Voice input for questions
- **Multi-language Support**: AI analysis in multiple languages
- **Advanced Analytics**: Charts and visualizations for data files
- **Collaborative Features**: Share AI insights with team members
- **Custom Prompts**: Save and reuse custom analysis prompts

### Integration Possibilities
- **Google Drive Integration**: Direct analysis of cloud files
- **Email Integration**: Analyze email attachments
- **OCR Enhancement**: Better text extraction from images
- **Real-time Collaboration**: Live AI chat with multiple users

## 📊 Cost Considerations

### OpenAI API Costs
- **GPT-4o-mini**: ~$0.15 per 1M input tokens, ~$0.60 per 1M output tokens
- **Typical Usage**: ~$0.01-0.05 per file analysis
- **Monthly Estimate**: $5-20 for regular usage

### Optimization Tips
- Use concise questions to reduce token usage
- Generate summaries instead of full analysis for large files
- Set up usage alerts on your OpenAI account

## 🤝 Contributing

To contribute to the AI integration:

1. Fork the repository
2. Create a feature branch
3. Implement your changes
4. Add tests for new functionality
5. Submit a pull request

### Development Setup
1. Clone the repository
2. Install dependencies: `flutter pub get`
3. Set up your `.env` file with API key
4. Run the app: `flutter run`

## 📄 License

This AI integration is part of FileGenius and follows the same license terms.

---

**Note**: This AI integration requires an active OpenAI API key and internet connection to function. API usage is subject to OpenAI's terms of service and pricing. 