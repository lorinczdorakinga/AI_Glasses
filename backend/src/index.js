const express = require('express');
const cors    = require('cors');
require('dotenv').config();
require('./config/db'); // ← ADD THIS LINE

const app = express();
app.use(cors());
app.use(express.json());

app.use('/api/auth', require('./routes/auth'));
app.use('/api/goals', require('./routes/goals'));

// Health check
app.get('/health', (_, res) => res.json({ status: 'ok' }));

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`🚀 Server running on http://localhost:${PORT}`)); 