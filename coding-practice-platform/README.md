# Coding Practice Platform

Code execution and scoring platform for TCS Smart Hiring exam prep.

## Prerequisites

- Docker
- Node.js 18+
- Python 3

## Setup (First Time)

```bash
cd coding-practice-platform

# Install dependencies
cd scoring-api && npm install && cd ..
cd piston-setup/cli && npm install && cd ../..

# Start Piston and install languages
cd piston-setup
docker compose up -d
node cli/index.js ppman install python java gcc node
cd ..
```

## Running

```bash
# From coding-practice-platform directory
make start    # Start all services
make stop     # Stop all services
make status   # Check service status
make restart  # Restart all services
```

## Access

| Environment | URL |
|-------------|-----|
| Local | http://localhost:3000 |
| VS Code Proxy | http://\<host\>:8081/proxy/3000/ |

## Test It

**Reverse String (Python):**
```python
s = input()
print(s[::-1])
```

**Two Sum (Python):**
```python
import ast
arr = ast.literal_eval(input())
target = int(input())
for i in range(len(arr)):
    for j in range(i+1, len(arr)):
        if arr[i] + arr[j] == target:
            print(i, j)
            exit()
```

## Commands

| Command | Description |
|---------|-------------|
| `make start` | Start all services |
| `make stop` | Stop all services |
| `make restart` | Restart all |
| `make status` | Check status |
| `make logs` | View recent logs |
| `make logs-api` | Follow API logs |
| `make logs-piston` | Follow Piston logs |
| `make clean` | Stop and cleanup |

## Services

| Service | Port | Description |
|---------|------|-------------|
| Frontend | 3000 | Web UI |
| Scoring API | 3001 | Test runner & scoring |
| Piston | 2000 | Code execution |

## Supported Languages

- Python 3
- JavaScript (Node.js)
- C (GCC)
- C++ (GCC)
- Java

## Adding Questions

Edit `scoring-api/data/questions.json`:

```json
{
  "id": "unique-id",
  "title": "Question Title",
  "description": "Problem description",
  "sampleTests": [
    {"input": "hello", "expected": "olleh"}
  ],
  "hiddenTests": [
    {"input": "world", "expected": "dlrow"}
  ]
}
```

## Troubleshooting

```bash
# Check logs
make logs

# Restart everything
make restart

# Check if Piston has languages
curl http://localhost:2000/api/v2/runtimes
```




 okay, check the setup in this folder - coding-practice-platform/frontend and overall check the coding practice platform
  directory to understand what we are trying to do, so the project is running now and I can see it working, but the UI is pretty
  ugly, since we are trying to set this up for exams for students, more context about this will be there in the readme - coding-
  practice-platform/README.md, so lets revamp the UI and make it better, we are looking somewhat in the direction of leetcode ui


ssh -L 1455:localhost:1455 phoenix-admin@100.64.11.64