const express = require('express');
const app = express();
const port = 3000;

app.get('/', (req, res) => res.send('Hello Production!'));

app.listen(port, () => console.log(`App on port ${port}`));