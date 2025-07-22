const express = require('express');
const axios = require('axios');
const cors = require('cors');
const fileUpload = require('express-fileupload');
const pdfParse = require('pdf-parse');
const mammoth = require('mammoth');
const XLSX = require('xlsx');
const fs = require('fs');
const path = require('path');
const app = express();
app.use(cors());
app.use(express.json());
app.use(fileUpload());

const GEMINI_API_KEY = 'AIzaSyBAHxBGsAXmkffc1MPpirFF2dh-sVVnc4U';
const pptx2json = require('pptx2json');
const officeparser = require('officeparser');

app.post('/gemini', async (req, res) => {
  try {
    const response = await axios.post(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=${GEMINI_API_KEY}`,
      req.body
    );
    res.json(response.data);
  } catch (err) {
    res.status(err.response?.status || 500).json({ error: err.message, data: err.response?.data });
  }
});

// PDF text extraction endpoint
app.post('/extract-pdf-text', async (req, res) => {
  try {
    if (req.files && req.files.pdf) {
      // PDF uploaded as file
      const pdfBuffer = req.files.pdf.data;
      const data = await pdfParse(pdfBuffer);
      res.json({ text: data.text });
    } else if (req.body.url) {
      // PDF provided as URL
      const response = await axios.get(req.body.url, { responseType: 'arraybuffer' });
      const data = await pdfParse(response.data);
      res.json({ text: data.text });
    } else {
      res.status(400).json({ error: 'No PDF file or URL provided.' });
    }
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Helper to download a file to a temp location
async function downloadToTemp(url, ext) {
  const response = await axios.get(url, { responseType: 'arraybuffer' });
  const tempPath = path.join(__dirname, `tmp_${Date.now()}.${ext}`);
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