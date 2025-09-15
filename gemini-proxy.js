const express = require('express');
const axios = require('axios');
const cors = require('cors');
const fileUpload = require('express-fileupload');
require('dotenv').config();
const pdfParse = require('pdf-parse');
const mammoth = require('mammoth');
const XLSX = require('xlsx');
const fs = require('fs');
const path = require('path');
const app = express();
app.use(cors());
app.use(express.json());
app.use(fileUpload());

const GEMINI_API_KEY = process.env.GEMINI_API_KEY;
if (!GEMINI_API_KEY) {
  // This will stop the server on startup if the key is not found.
  // You need to create a `.env` file in the `file_genius` directory
  // with the line: GEMINI_API_KEY='YourActualApiKeyHere'
  throw new Error('GEMINI_API_KEY is not set in the environment variables.');
}
const pptx2json = require('pptx2json');
const officeparser = require('officeparser');

app.post('/gemini', async (req, res) => {
  try {
    const model = req.body?.model || 'gemini-1.5-pro-latest';
    const response = await axios.post(
      `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${GEMINI_API_KEY}`,
      req.body
    );
    res.json(response.data);
  } catch (err) {
    const status = err.response?.status || 500;
    const message = err.response?.data?.error?.message || err.message;
    console.error(`[Proxy] Gemini error ${status}: ${message}`);
    res.status(status).json({ error: message, data: err.response?.data });
  }
});

// PDF text extraction endpoint
app.post('/extract-pdf-text', async (req, res) => {
  const { url } = req.body;
  if (!url) {
    return res.status(400).send('URL is required');
  }

  try {
    const response = await axios.get(url, { responseType: 'arraybuffer' });
    const buffer = Buffer.from(response.data, 'binary');
    
    try {
      const text = await officeparser.parseOfficeAsync(buffer);
      res.send(text);
    } catch (parseError) {
      console.error('Error parsing file:', parseError);
      res.status(400).send(`Failed to parse file. It might be corrupted or in an unsupported format. Parser error: ${parseError.message}`);
    }

  } catch (error) {
    console.error('Error fetching or processing file:', error);
    res.status(500).send('Error fetching file from URL.');
  }
});

// Helper to download a file to a temp location
async function downloadToTemp(url, ext) {
  // Validate the URL before proceeding
  if (!url?.startsWith('http')) {
    console.error(`[Proxy] Invalid URL for download: ${url}`);
    // Return a path to a dummy file or throw an error
    // For now, we'll throw to indicate failure clearly
    throw new Error(`Invalid URL provided for download: ${url}`);
  }
  const tempPath = path.join(__dirname, `temp_file_${Date.now()}.${ext}`);
  const response = await axios.get(url, { responseType: 'arraybuffer' });
  fs.writeFileSync(tempPath, response.data);
  return tempPath;
}

// PPTX extraction endpoint
app.post('/extract-pptx-text', async (req, res) => {
  try {
    if (!req.body.url) return res.status(400).json({ error: 'No PPTX URL provided.' });
    const tempPath = await downloadToTemp(req.body.url, 'pptx');
    console.log(`[PPTX] Downloaded to: ${tempPath}`);
    officeparser.parseOffice(tempPath, (err, data) => {
      fs.unlinkSync(tempPath);
      let text;
      if (err && typeof err === 'string' && !data) {
        text = err;
        console.log('[PPTX] Extraction success, text length:', text.length);
        return res.json({ text });
      }
      if (err) {
        console.error('[PPTX] Extraction error:', err);
        return res.status(500).json({ error: err.message || String(err) });
      }
      text = data;
      console.log('[PPTX] Extraction success, text length:', text.length);
      res.json({ text });
    });
  } catch (err) {
    console.error('[PPTX] Endpoint error:', err);
    res.status(500).json({ error: err.message });
  }
});

// DOCX extraction endpoint
app.post('/extract-docx-text', async (req, res) => {
  try {
    if (!req.body.url) return res.status(400).json({ error: 'No DOCX URL provided.' });
    const tempPath = await downloadToTemp(req.body.url, 'docx');
    console.log(`[DOCX] Downloaded to: ${tempPath}`);
    officeparser.parseOffice(tempPath, (err, data) => {
      fs.unlinkSync(tempPath);
      let text;
      if (err && typeof err === 'string' && !data) {
        text = err;
        console.log('[DOCX] Extraction success, text length:', text.length);
        return res.json({ text });
      }
      if (err) {
        console.error('[DOCX] Extraction error:', err);
        return res.status(500).json({ error: err.message || String(err) });
      }
      text = data;
      console.log('[DOCX] Extraction success, text length:', text.length);
      res.json({ text });
    });
  } catch (err) {
    console.error('[DOCX] Endpoint error:', err);
    res.status(500).json({ error: err.message });
  }
});

// XLSX extraction endpoint
app.post('/extract-xlsx-text', async (req, res) => {
  try {
    if (!req.body.url) return res.status(400).json({ error: 'No XLSX URL provided.' });
    const tempPath = await downloadToTemp(req.body.url, 'xlsx');
    console.log(`[XLSX] Downloaded to: ${tempPath}`);
    officeparser.parseOffice(tempPath, (err, data) => {
      fs.unlinkSync(tempPath);
      let text;
      if (err && typeof err === 'string' && !data) {
        text = err;
        console.log('[XLSX] Extraction success, text length:', text.length);
        return res.json({ text });
      }
      if (err) {
        console.error('[XLSX] Extraction error:', err);
        return res.status(500).json({ error: err.message || String(err) });
      }
      text = data;
      console.log('[XLSX] Extraction success, text length:', text.length);
      res.json({ text });
    });
  } catch (err) {
    console.error('[XLSX] Endpoint error:', err);
    res.status(500).json({ error: err.message });
  }
});

app.listen(3000, () => console.log('Proxy running on http://localhost:3000'));