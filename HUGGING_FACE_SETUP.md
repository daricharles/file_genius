# Hugging Face API Setup Guide

## 🚀 **Free AI Alternative to OpenAI**

This app now uses Hugging Face's free inference API instead of OpenAI to avoid rate limiting issues.

## 📋 **Step-by-Step Setup:**

### 1. **Create Hugging Face Account**
- Go to [huggingface.co](https://huggingface.co)
- Click "Sign Up" and create a free account
- Verify your email

### 2. **Get Your API Token**
- Log in to your Hugging Face account
- Go to [Settings > Access Tokens](https://huggingface.co/settings/tokens)
- Click "New token"
- Give it a name (e.g., "FileGenius AI")
- Select "Read" permissions
- Click "Generate token"
- **Copy the token** (starts with `hf_`)

### 3. **Update the Code**
- Open `lib/services/ai_service.dart`
- Find this line:
  ```dart
  return 'hf_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'; // Replace with your Hugging Face token
  ```
- Replace `hf_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx` with your actual token

### 4. **Test the App**
- Run the app: `flutter run`
- Upload a file and test the AI features

## 🎯 **Benefits of Hugging Face:**

✅ **Completely Free** - No payment required  
✅ **Higher Rate Limits** - More requests allowed  
✅ **No Credit Card** - No billing setup needed  
✅ **Multiple Models** - Access to thousands of AI models  

## 🔧 **Current Model:**
- **Model**: `microsoft/DialoGPT-medium`
- **Type**: Text generation model
- **Free Tier**: Yes, with generous limits

## 📊 **Rate Limits:**
- **Free Tier**: ~30,000 requests per month
- **Per Request**: ~3-5 seconds response time
- **No Per-Minute Limits**: Unlike OpenAI's strict limits

## 🆘 **Troubleshooting:**

### If you get "API key not configured":
- Make sure you've replaced the placeholder token
- Check that your token starts with `hf_`
- Verify your Hugging Face account is active

### If you get rate limit errors:
- Wait a few seconds and try again
- Hugging Face has much more generous limits than OpenAI

### If responses seem different:
- This is normal - different AI models have different personalities
- The model is still very capable for file analysis and Q&A

## 🔄 **Want to Switch Back to OpenAI?**
If you prefer OpenAI and have a paid account:
1. Add payment method to OpenAI account
2. Get API credits
3. Replace the Hugging Face token with your OpenAI key
4. Update the API endpoints back to OpenAI format

---

**Happy AI-powered file analysis! 🎉** 