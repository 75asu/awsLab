import express from 'express';
import cors from 'cors';
import { readFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __dirname = dirname(fileURLToPath(import.meta.url));
const app = express();
app.use(cors());
app.use(express.json());

const questions = JSON.parse(readFileSync(join(__dirname, '../data/questions.json'), 'utf-8'));
const results = {};
const PISTON_URL = process.env.PISTON_URL || 'http://localhost:2000';

// Language mapping: frontend languageId -> Piston language name
const LANGUAGE_MAP = {
  71: { language: 'python', version: '3.12.0' },      // Python 3
  62: { language: 'java', version: '15.0.2' },        // Java
  54: { language: 'c++', version: '10.2.0' },         // C++
  50: { language: 'c', version: '10.2.0' },           // C
  63: { language: 'javascript', version: '20.11.1' }, // JavaScript (Node.js)
};

async function runCode(sourceCode, languageId, input) {
  const langConfig = LANGUAGE_MAP[languageId];
  if (!langConfig) {
    return { error: `Unsupported language ID: ${languageId}` };
  }

  try {
    const res = await fetch(`${PISTON_URL}/api/v2/execute`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        language: langConfig.language,
        version: langConfig.version,
        files: [{ content: sourceCode }],
        stdin: input || ''
      })
    });

    const data = await res.json();

    // Map Piston response to Judge0-like format for compatibility
    return {
      stdout: data.run?.stdout || '',
      stderr: data.run?.stderr || '',
      compile_output: data.compile?.stderr || '',
      message: data.message || null,
      exit_code: data.run?.code
    };
  } catch (err) {
    return { error: err.message };
  }
}

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', engine: 'piston' });
});

// Get available languages
app.get('/languages', async (req, res) => {
  try {
    const response = await fetch(`${PISTON_URL}/api/v2/runtimes`);
    const runtimes = await response.json();
    res.json(runtimes);
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch languages' });
  }
});

// List questions (without hidden tests)
app.get('/coding/questions', (req, res) => {
  const safe = questions.map(q => ({
    id: q.id,
    title: q.title,
    description: q.description,
    sampleTests: q.sampleTests
  }));
  res.json(safe);
});

// Run sample tests only
app.post('/coding/run', async (req, res) => {
  const { questionId, code, languageId } = req.body;
  const question = questions.find(q => q.id === questionId);
  if (!question) return res.status(404).json({ error: 'Question not found' });

  const testResults = [];
  for (const test of question.sampleTests) {
    const result = await runCode(code, languageId, test.input);
    const stdout = (result.stdout || '').trim();
    testResults.push({
      input: test.input,
      expected: test.expected,
      actual: stdout,
      passed: stdout === test.expected,
      error: result.stderr || result.compile_output || result.message || result.error
    });
  }
  res.json({ testResults });
});

// Submit - run hidden tests and score
app.post('/coding/submit', async (req, res) => {
  const { questionId, code, languageId, userId } = req.body;
  const question = questions.find(q => q.id === questionId);
  if (!question) return res.status(404).json({ error: 'Question not found' });

  let passed = 0;
  const total = question.hiddenTests.length;
  for (const test of question.hiddenTests) {
    const result = await runCode(code, languageId, test.input);
    if ((result.stdout || '').trim() === test.expected) passed++;
  }
  const score = Math.round((passed / total) * 100);

  if (userId) {
    if (!results[userId]) results[userId] = {};
    results[userId][questionId] = { score, passed, total, timestamp: new Date() };
  }
  res.json({ score, passed, total });
});

// Get user results
app.get('/results/:userId', (req, res) => {
  res.json(results[req.params.userId] || {});
});

const PORT = process.env.PORT || 3001;
app.listen(PORT, () => console.log(`Scoring API running on http://localhost:${PORT} (using Piston)`));
